const jwt = require('jsonwebtoken');
const User = require('../models/User');

module.exports = async function requireAuth(req, res, next) {
  try {
    const hdr = req.headers.authorization || '';
    const token = hdr.startsWith('Bearer ') ? hdr.slice(7) : null;
    if (!token) return res.status(401).json({ error: { code: 'UNAUTH', message: 'Missing token' } });

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub || payload.id).lean();
    if (!user || user.deletedAt || user.isActive === false) {
      return res.status(401).json({ error: { code: 'UNAUTH', message: 'Invalid user' } });
    }

    req.user = {
      _id: user._id,
      id: user._id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      isVerified: !!user.isVerified,
    };

    next();
  } catch (e) {
    return res.status(401).json({ error: { code: 'UNAUTH', message: 'Invalid token' } });
  }
};
