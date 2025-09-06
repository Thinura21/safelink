const router = require('express').Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function signTokens(user) {
  const payload = { sub: user._id.toString(), role: user.role };
  const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRE || '7d' });
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, { expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d' });
  return { token, refreshToken };
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, contact, address, nic, guardian } = req.body;
    const user = await User.create({ email, password, fullName, contact, address, nic, guardian, profileComplete: true });
    res.status(201).json({ success: true, message: 'Registration successful. Please verify email.', userId: user._id });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ success: false, error: { code: 'DUPLICATE_EMAIL', message: 'Email already exists' }});
    res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: err.message }});
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(401).json({ success: false, error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' }});
  const ok = await user.comparePassword(password);
  if (!ok) return res.status(401).json({ success: false, error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' }});
  user.lastLogin = new Date();
  await user.save();
  const { token, refreshToken } = signTokens(user);
  res.json({ success: true, token, refreshToken, user: { _id: user._id, email: user.email, fullName: user.fullName, role: user.role, isVerified: user.isVerified, profileComplete: user.profileComplete }});
});

module.exports = router;
