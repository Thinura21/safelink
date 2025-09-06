// src/routes/profile.js
const router = require('express').Router();
const requireAuth = require('../middleware/requireAuth');
const upload = require('../middleware/upload');
const User = require('../models/User');

// helpers
const toBool = v => v === true || v === 'true' || v === 1 || v === '1';
const cleanDeep = (src) => {
  if (!src || typeof src !== 'object') return src;
  const out = Array.isArray(src) ? [] : {};
  for (const [k, v] of Object.entries(src)) {
    if (v == null) continue;
    if (typeof v === 'string') {
      const s = v.trim();
      if (!s) continue;
      Array.isArray(out) ? out.push(s) : out[k] = s;
    } else if (Array.isArray(v)) {
      const arr = v.map(x => (typeof x === 'string' ? x.trim() : x))
                  .filter(x => x != null && (typeof x !== 'string' || x));
      if (arr.length) out[k] = arr;
    } else if (typeof v === 'object') {
      const o = cleanDeep(v);
      if (Object.keys(o).length) out[k] = o;
    } else {
      Array.isArray(out) ? out.push(v) : out[k] = v;
    }
  }
  return out;
};
const parseSpecializations = (val) => {
  if (!val) return [];
  if (Array.isArray(val)) return val.map(s => String(s).trim()).filter(Boolean);
  return String(val).split(',').map(s => s.trim()).filter(Boolean);
};
const buildAbsUrl = (req, filename) => `${req.protocol}://${req.get('host')}/uploads/${filename}`;

// GET /api/profile/me
router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const u = await User.findById(req.user._id).lean();
    if (!u) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'User not found' } });
    res.json({ success: true, user: u });
  } catch (e) { next(e); }
});

/**
 * PATCH /api/profile/me
 * Accepts:
 * - Common: fullName, contact, address, nic
 * - Images by string URL: profileImage, nicImage
 * - Guardian: {name, contact|phone, address} or flat keys guardian.name/contact/address
 * - Officer-only: department, badgeNumber, specializations (string "a,b,c" or array)
 * Behavior:
 * - If role != 'officer', officer-only fields are cleared.
 * - Cleans empty strings to avoid wiping existing data unintentionally.
 */
router.patch('/me', requireAuth, async (req, res, next) => {
  try {
    const me = await User.findById(req.user._id);
    if (!me) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'User not found' } });

    const b = req.body || {};
    // Normalize guardian
    let guardian = b.guardian;
    if (!guardian && (b['guardian.name'] || b['guardian.contact'] || b['guardian.phone'] || b['guardian.address'])) {
      guardian = {
        name: b['guardian.name'],
        contact: b['guardian.contact'] || b['guardian.phone'],
        address: b['guardian.address'],
      };
    }
    guardian = guardian && typeof guardian === 'object' ? cleanDeep(guardian) : undefined;

    // Apply basics (only if provided and non-empty after cleanDeep)
    const setIf = (key, val) => {
      if (typeof val === 'string') { const s = val.trim(); if (s) me[key] = s; }
      else if (val != null) me[key] = val;
    };

    setIf('fullName', b.fullName);
    setIf('contact', b.contact ?? b.phone);
    setIf('address', b.address);
    setIf('nic', b.nic);
    setIf('profileImage', b.profileImage);
    setIf('nicImage', b.nicImage);
    if (guardian) me.guardian = guardian;

    // Officer-only vs user
    if (me.role === 'officer') {
      if ('department' in b) setIf('department', b.department);
      if ('badgeNumber' in b) setIf('badgeNumber', b.badgeNumber);
      if ('specializations' in b || 'specializationsCsv' in b) {
        const arr = parseSpecializations(b.specializations ?? b.specializationsCsv);
        me.specializations = arr;
      }
    } else {
      // ensure officer-only fields are cleared for non-officers
      me.department = undefined;
      me.badgeNumber = undefined;
      me.specializations = [];
    }

    await me.save();
    const user = await User.findById(me._id).lean();
    res.json({ success: true, user });
  } catch (e) { next(e); }
});

// PUT /api/profile/me (kept for backward-compat; narrows to a few fields)
router.put('/me', requireAuth, async (req, res, next) => {
  try {
    const allowed = ['fullName', 'contact', 'address', 'guardian'];
    const updates = {};
    for (const k of allowed) if (k in req.body) updates[k] = req.body[k];
    const cleaned = cleanDeep(updates);
    const updated = await User.findByIdAndUpdate(req.user._id, cleaned, { new: true, runValidators: true }).lean();
    res.json({ success: true, user: updated });
  } catch (e) { next(e); }
});

// POST /api/profile/me/avatar (multipart field: 'file')
router.post('/me/avatar', requireAuth, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, error: { code: 'NO_FILE', message: 'No file uploaded' } });
    const url = buildAbsUrl(req, req.file.filename);
    await User.findByIdAndUpdate(req.user._id, { profileImage: url }, { new: true });
    res.status(201).json({ success: true, url, profileImage: url });
  } catch (e) { next(e); }
});

// POST /api/profile/me/nic (multipart field: 'file')
router.post('/me/nic', requireAuth, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, error: { code: 'NO_FILE', message: 'No file uploaded' } });
    const url = buildAbsUrl(req, req.file.filename);
    await User.findByIdAndUpdate(req.user._id, { nicImage: url }, { new: true });
    res.status(201).json({ success: true, url, nicImage: url });
  } catch (e) { next(e); }
});

module.exports = router;
