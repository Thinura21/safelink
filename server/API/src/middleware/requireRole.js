module.exports = (...allowed) => {
  const allow = new Set(allowed.flat().filter(Boolean));
  return (req, res, next) => {
    const u = req.user;
    if (!u) return res.status(401).json({ error: { code: 'UNAUTH', message: 'Unauthenticated' } });

    if (u.role === 'admin') return next();
    if (!allow.size || allow.has(u.role)) return next();

    return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Forbidden' } });
  };
};
