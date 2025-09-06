// src/routes/emergency.admin.js
const router   = require('express').Router();
const mongoose = require('mongoose');

const requireAuth = require('../middleware/requireAuth');
const requireRole = require('../middleware/requireRole');
const upload      = require('../middleware/upload');

const Incident = require('../models/Incident');
const Counter  = require('../models/Counter');
const User     = require('../models/User');

let Chat; try { Chat = require('../models/Chat'); } catch (_) { Chat = null; }

router.use(requireAuth, requireRole(['admin','authority']));

const asInt = (v, d=undefined) => {
  if (v === null || v === undefined || v === '') return d;
  const n = Number.parseInt(v, 10);
  return Number.isFinite(n) ? n : d;
};
const toFloat = (v, d=undefined) => {
  if (v === null || v === undefined || v === '') return d;
  const n = Number.parseFloat(v);
  return Number.isFinite(n) ? n : d;
};

const normalizeType = t => (['crime','medical','fire','accident','other'].includes(String(t||'').toLowerCase())
  ? String(t).toLowerCase() : 'other');

const normalizeStatus = s => {
  const v = String(s||'').toLowerCase();
  const ok = ['open','assigned','en_route','arrived','resolved','cancelled'];
  return ok.includes(v) ? v : undefined;
};

async function findIncidentByRef(ref) {
  if (!ref) return null;
  if (/^INC-\d{4}-\d{5}$/.test(ref)) return Incident.findOne({ incidentId: ref });
  if (mongoose.Types.ObjectId.isValid(ref)) return Incident.findById(ref);
  return null;
}

async function nextIncidentId() {
  const year = new Date().getFullYear();
  const doc = await Counter.findOneAndUpdate(
    { _id: `incident:${year}` },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );
  return `INC-${year}-${String(doc.seq).padStart(5, '0')}`;
}

/** OFFICERS  */
router.get('/officers', async (req, res, next) => {
  try {
    const q = (req.query.q || '').trim();
    const filter = { role: 'officer', isActive: true, deletedAt: null };
    if (q) {
      const rx = new RegExp(q, 'i');
      filter.$or = [{ email: rx }, { fullName: rx }, { badgeNumber: rx }, { department: rx }];
    }
    const items = await User.find(filter)
      .select('_id fullName email badgeNumber department profileImage')
      .sort({ fullName: 1 }).lean();
    res.json({ success: true, items });
  } catch (e) { next(e); }
});

/** LIST */
router.get('/incidents', async (req, res, next) => {
  try {
    const { q='', since, limit='100', status } = req.query;
    const lim = Math.max(1, Math.min(parseInt(limit,10)||50, 500));

    const filter = {};
    if (status) {
      const parts = String(status).split(',').map(s=>s.trim().toLowerCase()).filter(Boolean);
      if (parts.length) filter.status = { $in: parts };
    } else {
      filter.status = { $in: ['open','assigned','en_route'] };
    }
    if (since) {
      const dt = new Date(since);
      if (!isNaN(dt.getTime())) filter.createdAt = { $gte: dt };
    }
    if (q.trim()) {
      const rx = new RegExp(q.trim(), 'i');
      filter.$or = [
        { incidentId: rx }, { type: rx }, { priority: rx },
        { description: rx }, { locationText: rx }
      ];
    }

    const items = await Incident.find(filter)
      .select('incidentId type status priority description location locationText reporterId createdAt etaMinutes assignedOfficerId imagesCount')
      .sort({ createdAt: -1 }).limit(lim).lean();

    res.json({ success: true, items });
  } catch (e) { next(e); }
});

/** CREATE */
router.post('/incidents', async (req, res, next) => {
  try {
    const { reporterId, description='', priority='normal', locationText='' } = req.body || {};
    const type   = normalizeType(req.body.type || 'other');
    const status = normalizeStatus(req.body.status || 'open') || 'open';

    const lat = toFloat(req.body.lat);
    const lng = toFloat(req.body.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ error: { code: 'BAD_COORDS', message: 'lat/lng required' } });
    }

    const incidentId = await nextIncidentId();
    const doc = await Incident.create({
      incidentId,
      reporterId: reporterId || req.user._id,
      type, description, priority, status,
      location: { type: 'Point', coordinates: [lng, lat] },
      locationText,
      casualties: asInt(req.body.casualties, null),
      bystander: req.body.bystander === true || String(req.body.bystander) === 'true'
        ? true : (req.body.bystander === false || String(req.body.bystander) === 'false'
        ? false : null),
    });
    res.status(201).json({ success: true, incident: doc });
  } catch (e) { next(e); }
});

/** READ */
router.get('/incidents/:ref', async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    const inc = await Incident.findById(doc._id)
      .populate({ path: 'reporterId', select: '_id fullName email contact profileImage' })
      .populate({ path: 'assignedOfficerId', select: '_id fullName email badgeNumber department profileImage' })
      .lean();
    res.json({ success: true, incident: inc });
  } catch (e) { next(e); }
});

/** UPDATE (also supports lat/lng to set GeoJSON) */
router.patch('/incidents/:ref', async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });

    const $set = {};
    const allowed = [
      'type','description','priority','status','etaMinutes','assignmentNote',
      'assignedOfficerId','locationText','casualties','bystander','reporterId'
    ];
    for (const k of allowed) if (k in req.body) $set[k] = req.body[k];

    if ('type' in $set)   $set.type   = normalizeType($set.type);
    if ('status' in $set) {
      const s = normalizeStatus($set.status);
      if (!s) return res.status(400).json({ error: { code: 'BAD_STATUS', message: 'Invalid status' } });
      $set.status = s;
    }
    if ('etaMinutes' in $set) $set.etaMinutes = asInt($set.etaMinutes, null);
    if ('casualties' in $set) $set.casualties = asInt($set.casualties, null);
    if ('bystander'  in $set) $set.bystander  = ($set.bystander === true || String($set.bystander) === 'true');

    const lat = toFloat(req.body.lat), lng = toFloat(req.body.lng);
    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      $set.location = { type: 'Point', coordinates: [lng, lat] };
    } else if (req.body.location?.coordinates?.length >= 2) {
      const c = req.body.location.coordinates;
      if (Number.isFinite(c[0]) && Number.isFinite(c[1])) {
        $set.location = { type: 'Point', coordinates: [Number(c[0]), Number(c[1])] };
      }
    }

    const updated = await Incident.findByIdAndUpdate(doc._id, { $set }, { new: true });
    res.json({ success: true, incident: updated });
  } catch (e) { next(e); }
});

/** ASSIGN */
router.post('/incidents/:ref/assign', async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    const officerId = req.body.officerId;
    if (!officerId) return res.status(400).json({ error: { code: 'NO_OFFICER', message: 'officerId required' } });

    const officer = await User.findOne({ _id: officerId, role: 'officer', isActive: true });
    if (!officer) return res.status(400).json({ error: { code: 'BAD_OFFICER', message: 'Officer not found/active' } });

    const eta  = asInt(req.body.etaMinutes, null);
    const note = (req.body.note || '').toString();

    const updated = await Incident.findByIdAndUpdate(
      doc._id,
      { $set: { assignedOfficerId: officer._id, etaMinutes: eta, assignmentNote: note, status: 'assigned' } },
      { new: true }
    );
    res.json({ success: true, incident: updated });
  } catch (e) { next(e); }
});

/** ETA only */
router.post('/incidents/:ref/eta', async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    const eta = asInt(req.body.etaMinutes, null);
    const updated = await Incident.findByIdAndUpdate(doc._id, { $set: { etaMinutes: eta } }, { new: true });
    res.json({ success: true, incident: updated });
  } catch (e) { next(e); }
});

/** DELETE */
router.delete('/incidents/:ref', async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    await Incident.deleteOne({ _id: doc._id });
    res.json({ success: true });
  } catch (e) { next(e); }
});

/** ADD IMAGES */
router.post('/incidents/:ref/images', upload.array('images', 6), async (req, res, next) => {
  try {
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    const urls = (req.files || []).map(f => `${req.protocol}://${req.get('host')}/uploads/${f.filename}`);
    if (!urls.length) return res.status(400).json({ error: { code: 'NO_FILE', message: 'No files' } });
    const images  = [...(doc.images || []), ...urls];
    const updated = await Incident.findByIdAndUpdate(doc._id, { $set: { images, imagesCount: images.length } }, { new: true });
    res.status(201).json({ success: true, images: urls, incident: updated });
  } catch (e) { next(e); }
});

/** MESSAGES (optional) */
router.get('/incidents/:ref/messages', async (req, res, next) => {
  try {
    if (!Chat) return res.json({ success: true, items: [] });
    const doc = await findIncidentByRef(req.params.ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    const items = await Chat.find({ incidentId: doc._id })
      .select('_id senderId text images createdAt')
      .sort({ createdAt: -1 }).limit(200).lean();
    res.json({ success: true, items });
  } catch (e) { next(e); }
});

module.exports = router;
