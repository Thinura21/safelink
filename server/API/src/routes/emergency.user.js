const router = require('express').Router();
const mongoose = require('mongoose');
const requireAuth = require('../middleware/requireAuth');
const upload = require('../middleware/upload');
const Incident = require('../models/Incident');
const Counter  = require('../models/Counter');

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
function normalizeType(t) {
  const v = String(t || '').toLowerCase();
  if (v === 'police') return 'crime';
  return ['crime','medical','fire','accident','other'].includes(v) ? v : 'other';
}
function normalizeStatus(s) {
  const v = String(s || '').toLowerCase();
  if (v === 'created') return 'open';
  return v || 'open';
}
async function nextIncidentId() {
  const year = new Date().getFullYear();
  const id = `incident:${year}`;
  const doc = await Counter.findOneAndUpdate({ _id: id }, { $inc: { seq: 1 } }, { new: true, upsert: true });
  const seq = String(doc.seq).padStart(5, '0');
  return `INC-${year}-${seq}`;
}
async function findIncidentByRef(ref) {
  if (!ref) return null;
  if (/^INC-\d{4}-\d{5}$/.test(ref)) return Incident.findOne({ incidentId: ref });
  if (mongoose.Types.ObjectId.isValid(ref)) return Incident.findById(ref);
  return null;
}

function normalizePriority(p) {
  const v = String(p || '').toLowerCase();
  // keep the set aligned with your schema allowed values
  if (['low', 'normal', 'high', 'critical'].includes(v)) return v;
  return 'normal';
}

const reserved = new Set(['my']);

// CREATE: POST /api/emergency  (multipart optional: images[])
router.post('/', requireAuth, upload.array('images', 6), async (req, res, next) => {
  try {
    const u = req.user;
    const type = normalizeType(req.body.type || 'other');
    const description = String(req.body.description || '').trim();
    const priority = (req.body.priority || '').trim() || 'normal';

    const lat = toFloat(req.body.lat);
    const lng = toFloat(req.body.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ error: { code: 'BAD_COORDS', message: '`lat` and `lng` are required' } });
    }

    const incidentId = await nextIncidentId();
    const imageUrls = (req.files || []).map(f => `${req.protocol}://${req.get('host')}/uploads/${f.filename}`);

    const doc = await Incident.create({
      incidentId,
      reporterId: u._id,
      type,
      status: 'open',
      priority,
      description,
      location: { type: 'Point', coordinates: [lng, lat] },
      locationText: req.body.address || req.body.locationText || '',
      bystander: req.body.bystander === 'true' ? true : (req.body.bystander === 'false' ? false : undefined),
      casualties: asInt(req.body.casualties, undefined),
      images: imageUrls,
      imagesCount: imageUrls.length,
    });

    res.status(201).json({
      success: true,
      incident: doc,
      incidentId: doc.incidentId,   
    });
  } catch (e) { next(e); }
});

// LIST MINE: GET /api/emergency/my
router.get('/my', requireAuth, async (req, res, next) => {
  try {
    const items = await Incident.find({ reporterId: req.user._id })
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, items });
  } catch (e) { next(e); }
});

// NEW: LATEST OPEN MINE: GET /api/emergency/my/active
router.get('/my/active', requireAuth, async (req, res, next) => {
  try {
    const inc = await Incident.findOne({
      reporterId: req.user._id,
      status: { $in: ['open','assigned','enroute','ack'] },
    }).sort({ createdAt: -1 }).lean();

    if (!inc) return res.status(204).end();

    // harmonize for the client
    const assignedOfficerName = (
      inc.assignedOfficerName ||
      inc.officerName ||
      (inc.assignedOfficer && inc.assignedOfficer.fullName)
    ) || undefined;

    res.json({
      success: true,
      incident: inc,
      incidentId: inc.incidentId,
      assignedOfficerName,
      etaMinutes: inc.etaMinutes ?? undefined,
    });
  } catch (e) { next(e); }
});

// READ ONE: GET /api/emergency/:ref (id or incidentId)
router.get('/:ref', requireAuth, async (req, res, next) => {
  try {
    const ref = req.params.ref;
    if (reserved.has(ref)) return next();
    const doc = await findIncidentByRef(ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    if (doc.reporterId?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Not allowed' } });
    }
    res.json({
      success: true,
      incident: doc,
      incidentId: doc.incidentId,
      assignedOfficerName: doc.assignedOfficerName || doc.officerName || undefined,
      etaMinutes: doc.etaMinutes ?? undefined,
    });
  } catch (e) { next(e); }
});

// UPDATE (limited): PATCH /api/emergency/:ref
router.patch('/:ref', requireAuth, async (req, res, next) => {
  try {
    const ref = req.params.ref;
    if (reserved.has(ref)) return next();
    const doc = await findIncidentByRef(ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    if (doc.reporterId?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Only the reporter can update this incident' } });
    }

    const $set = {};
    if ('casualties'   in req.body) $set.casualties   = asInt(req.body.casualties, 0);
    if ('bystander'    in req.body) $set.bystander    = String(req.body.bystander) === 'true' || req.body.bystander === true;
    if ('type'         in req.body) $set.type         = normalizeType(req.body.type);
    if ('imagesCount'  in req.body) $set.imagesCount  = asInt(req.body.imagesCount, 0);
    if ('status'       in req.body) $set.status       = normalizeStatus(req.body.status);
    if ('description'  in req.body) $set.description  = String(req.body.description || '');
    if ('priority'     in req.body) $set.priority     = normalizePriority(req.body.priority);
    const updated = await Incident.findByIdAndUpdate(doc._id, { $set }, { new: true });
    res.json({ success: true, incident: updated, incidentId: updated.incidentId });
  } catch (e) { next(e); }
});

// DELETE (own): DELETE /api/emergency/:ref
router.delete('/:ref', requireAuth, async (req, res, next) => {
  try {
    const ref = req.params.ref;
    const doc = await findIncidentByRef(ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    if (doc.reporterId?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Only the reporter can delete this incident' } });
    }
    await Incident.deleteOne({ _id: doc._id });
    res.json({ success: true });
  } catch (e) { next(e); }
});

// POST /api/emergency/:ref/images (multipart images[])
// appends files to incident.images and updates imagesCount
router.post('/:ref/images', requireAuth, upload.array('images', 6), async (req, res, next) => {
  try {
    const ref = req.params.ref;
    const doc = await findIncidentByRef(ref);
    if (!doc) return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    if (doc.reporterId?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Only the reporter can upload images' } });
    }
    const urls = (req.files || []).map(f => `${req.protocol}://${req.get('host')}/uploads/${f.filename}`);
    if (urls.length === 0) return res.status(400).json({ error: { code: 'NO_FILE', message: 'No files' } });
    const images = [...(doc.images || []), ...urls];
    const updated = await Incident.findByIdAndUpdate(doc._id, { $set: { images, imagesCount: images.length } }, { new: true });
    res.status(201).json({ success: true, images: urls, incident: updated });
  } catch (e) { next(e); }
});

module.exports = router;
