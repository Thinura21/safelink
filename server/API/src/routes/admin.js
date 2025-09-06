const router = require('express').Router();
const path = require('path');
const fs = require('fs');

const User = require('../models/User');
const Incident = require('../models/Incident');
const Counter = require('../models/Counter');
const upload = require('../middleware/upload');


const canTouchTarget = (me, target) => {
  if (!me) return false;
  if (me.role === 'admin') return true;
  return target?.role !== 'admin';
};

// Build absolute URL for stored files
const urlFor = (req, filename) =>
  filename ? `${req.protocol}://${req.get('host')}/uploads/${filename}` : undefined;

const toBool = v => v === true || v === 'true' || v === 1 || v === '1';

/* =========================
 * USERS: LIST / CREATE / UPDATE / DELETE
 * ========================= */
const parseGuardian = (raw) => {
  if (!raw) return undefined;
  if (typeof raw === 'string') {
    try { const g = JSON.parse(raw); return g && Object.keys(g).length ? g : undefined; }
    catch { return undefined; }
  }
  // already object
  return raw;
};

// GET /api/admin/users
router.get('/users', async (req, res, next) => {
  try {
    const { role, isVerified, isActive, q, page = 1, limit = 20 } = req.query;

    const filter = { deletedAt: null };
    if (req.user?.role === 'authority') filter.role = { $ne: 'admin' };
    if (role) filter.role = role;
    if (typeof isVerified !== 'undefined') filter.isVerified = toBool(isVerified);
    if (typeof isActive !== 'undefined') filter.isActive = toBool(isActive);

    if (q && q.trim()) {
      const rx = new RegExp(q.trim(), 'i');
      filter.$or = [
        { email: rx }, { fullName: rx }, { contact: rx }, { address: rx },
        { department: rx }, { badgeNumber: rx }, { nic: rx }
      ];
    }

    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const limitNum = Math.min(Math.max(parseInt(limit, 10) || 20, 1), 100);

    const [items, total] = await Promise.all([
      User.find(filter)
        .sort({ updatedAt: -1, _id: -1 })
        .skip((pageNum - 1) * limitNum)
        .limit(limitNum)
        .lean(),
      User.countDocuments(filter),
    ]);

    res.json({ success: true, items, total, page: pageNum, limit: limitNum });
  } catch (err) { next(err); }
});

// POST /api/admin/users  (multipart or JSON; files: profileImage, nicImage)
router.post('/users', upload.fields([
  { name: 'profileImage', maxCount: 1 },
  { name: 'nicImage', maxCount: 1 },
]), async (req, res, next) => {
  try {
    const me = req.user;
    const b = req.body || {};
    const f = req.files || {};

    if (me?.role === 'authority' && String(b.role || '').trim() === 'admin') {
      return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Cannot create admin accounts' } });
    }

    const g = parseGuardian(b.guardian) ?? (
      (b['guardian.name'] || b['guardian.phone'] || b['guardian.relation'])
        ? { name: b['guardian.name'], phone: b['guardian.phone'], relation: b['guardian.relation'] }
        : undefined
    );

    let role = (b.role || 'user').trim();
    let department = b.department?.trim();
    let badgeNumber = b.badgeNumber?.trim();
    let specializations = (b.specializations ? [].concat(b.specializations) : [])
      .flatMap(v => String(v).split(','))
      .map(s => s.trim()).filter(Boolean);

    // If not officer → wipe officer-only fields
    if (role !== 'officer') {
      department = undefined;
      badgeNumber = undefined;
      specializations = [];
    }

    const doc = {
      email: b.email?.trim(),
      password: b.password,
      fullName: b.fullName?.trim(),
      contact: b.contact?.trim(),
      address: b.address?.trim(),
      nic: b.nic?.trim(),
      role,
      department,
      badgeNumber,
      specializations,
      guardian: g,
      isVerified: toBool(b.isVerified),
      nicVerified: b.nicVerified || 'pending',
      verifierNote: b.verifierNote?.trim(),
      profileComplete: toBool(b.profileComplete),
      isActive: typeof b.isActive === 'undefined' ? true : toBool(b.isActive),
      fcmToken: b.fcmToken?.trim(),
    };

    if (f.profileImage?.[0]) doc.profileImage = urlFor(req, f.profileImage[0].filename);
    if (f.nicImage?.[0]) doc.nicImage = urlFor(req, f.nicImage[0].filename);

    // verifiedBy logic on create
    if (doc.isVerified || doc.nicVerified === 'verified') {
      doc.verifiedBy = me?._id ?? null;
    }

    const user = new User(doc);
    await user.save();
    res.status(201).json({ success: true, user });
  } catch (err) {
    if (err?.code === 11000) {
      return res.status(400).json({ success: false, error: { code: 'DUPLICATE_EMAIL', message: 'Email already exists' } });
    }
    next(err);
  }
});

// PATCH /api/admin/users/:id
router.patch('/users/:id', upload.fields([
  { name: 'profileImage', maxCount: 1 },
  { name: 'nicImage', maxCount: 1 },
]), async (req, res, next) => {
  try {
    const me = req.user;
    const { id } = req.params;
    const b = req.body || {};
    const f = req.files || {};

    const user = await User.findById(id);
    if (!user || user.deletedAt) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'User not found' } });
    }

    if (!canTouchTarget(me, user)) {
      return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Not allowed to modify this user' } });
    }
    if (me?.role === 'authority' && b.role === 'admin') {
      return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Cannot assign admin role' } });
    }

    const assign = (k, v) => { if (typeof v !== 'undefined') user[k] = v; };

    assign('email', b.email?.trim());
    assign('fullName', b.fullName?.trim());
    assign('contact', b.contact?.trim());
    assign('address', b.address?.trim());
    assign('nic', b.nic?.trim());

    // Role updates: wipe officer fields if role changes away from officer
    if (typeof b.role !== 'undefined') {
      user.role = b.role;
      if (b.role !== 'officer') {
        user.department = undefined;
        user.badgeNumber = undefined;
        user.specializations = [];
      }
    }

    assign('department', b.department?.trim());
    assign('badgeNumber', b.badgeNumber?.trim());

    if (typeof b.specializations !== 'undefined') {
      const arr = [].concat(b.specializations)
        .flatMap(v => String(v).split(','))
        .map(s => s.trim())
        .filter(Boolean);
      user.specializations = user.role === 'officer' ? arr : [];
    }

    const guardian = parseGuardian(b.guardian) ?? (
      (b['guardian.name'] || b['guardian.phone'] || b['guardian.relation'])
        ? { name: b['guardian.name'], phone: b['guardian.phone'], relation: b['guardian.relation'] }
        : undefined
    );
    if (typeof guardian !== 'undefined') user.guardian = guardian;

    if (typeof b.isVerified !== 'undefined') {
      user.isVerified = toBool(b.isVerified);
      user.verifiedBy = user.isVerified ? (me?._id ?? null) : null;
    }
    if (typeof b.nicVerified !== 'undefined') {
      user.nicVerified = b.nicVerified;
      if (b.nicVerified === 'verified') user.verifiedBy = me?._id ?? null;
      if (b.nicVerified === 'pending' || b.nicVerified === 'rejected') {
        if (!user.isVerified) user.verifiedBy = null;
      }
    }

    assign('verifierNote', b.verifierNote?.trim());
    if (typeof b.profileComplete !== 'undefined') assign('profileComplete', toBool(b.profileComplete));
    if (typeof b.isActive !== 'undefined') assign('isActive', toBool(b.isActive));

    if (b.password && String(b.password).trim()) user.password = String(b.password).trim();

    if (f.profileImage?.[0]) user.profileImage = urlFor(req, f.profileImage[0].filename);
    if (f.nicImage?.[0]) user.nicImage = urlFor(req, f.nicImage[0].filename);

    await user.save();
    res.json({ success: true, user });
  } catch (err) {
    if (err?.code === 11000) {
      return res.status(400).json({ success: false, error: { code: 'DUPLICATE_EMAIL', message: 'Email already exists' } });
    }
    next(err);
  }
});

// DELETE /api/admin/users/:id (soft delete)
router.delete('/users/:id', async (req, res, next) => {
  try {
    const me = req.user;
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user || user.deletedAt) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'User not found' } });
    }
    if (!canTouchTarget(me, user)) {
      return res.status(403).json({ success: false, error: { code: 'FORBIDDEN', message: 'Not allowed to delete this user' } });
    }
    user.deletedAt = new Date();
    user.isActive = false;
    await user.save();
    res.json({ success: true });
  } catch (err) { next(err); }
});

/* =========================
 * INCIDENTS (ADMIN/AUTHORITY)
 * ========================= */

// List
router.get('/incidents', async (_req, res, next) => {
  try {
    const items = await Incident.find({}).sort({ createdAt: -1 }).lean();
    res.json({ success: true, items });
  } catch (e) {
    next(e);
  }
});

// Create (admin/authority can create on behalf of a user)
router.post('/incidents', async (req, res, next) => {
  try {
    const { type = 'other', description = '', priority = 'normal', lat, lng, reporterId } = req.body;

    const latNum = Number(lat);
    const lngNum = Number(lng);

    if (!Number.isFinite(latNum) || !Number.isFinite(lngNum) || !reporterId) {
      return res.status(400).json({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: 'lat, lng (numbers) and reporterId are required' },
      });
    }

    // generate incidentId
    const year = new Date().getFullYear();
    const counterId = `incident:${year}`;
    const c = await Counter.findOneAndUpdate(
      { _id: counterId },
      { $inc: { seq: 1 } },
      { new: true, upsert: true }
    );
    const seq = String(c.seq).padStart(5, '0');
    const incidentId = `INC-${year}-${seq}`;

    const doc = await Incident.create({
      incidentId,
      reporterId,
      type,
      description,
      priority,
      status: 'open',
      location: { type: 'Point', coordinates: [lngNum, latNum] },
    });

    res.status(201).json({ success: true, incident: doc });
  } catch (e) {
    next(e);
  }
});

// Read
router.get('/incidents/:ref', async (req, res, next) => {
  try {
    const ref = req.params.ref;
    let doc = null;
    if (/^INC-\d{4}-\d{5}$/.test(ref)) doc = await Incident.findOne({ incidentId: ref });
    else doc = await Incident.findById(ref);

    if (!doc) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    }
    res.json({ success: true, incident: doc });
  } catch (e) {
    next(e);
  }
});

// Update (full or partial)
router.patch('/incidents/:ref', async (req, res, next) => {
  try {
    const ref = req.params.ref;
    let doc = null;
    if (/^INC-\d{4}-\d{5}$/.test(ref)) doc = await Incident.findOne({ incidentId: ref });
    else doc = await Incident.findById(ref);

    if (!doc) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    }

    const allowed = [
      'type',
      'description',
      'priority',
      'status',
      'etaMinutes',
      'assignmentNote',
      'assignedOfficerId',
      'location',
      'locationText',
      'casualties',
      'bystander',
    ];
    for (const k of allowed) {
      if (k in req.body) doc[k] = req.body[k];
    }

    await doc.save();
    res.json({ success: true, incident: doc });
  } catch (e) {
    next(e);
  }
});

// Delete
router.delete('/incidents/:ref', async (req, res, next) => {
  try {
    const ref = req.params.ref;
    let doc = null;
    if (/^INC-\d{4}-\d{5}$/.test(ref)) doc = await Incident.findOne({ incidentId: ref });
    else doc = await Incident.findById(ref);

    if (!doc) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Incident not found' } });
    }

    await Incident.deleteOne({ _id: doc._id });
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
