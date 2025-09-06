require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');

const { connectDB } = require('./src/config/database');

// Routes
const authRoutes = require('./src/routes/auth');
const profileRoutes = require('./src/routes/profile');
const adminRoutes = require('./src/routes/admin');        
const emergencyUserRoutes = require('./src/routes/emergency.user'); 
const emergencyAdminRouter = require('./src/routes/emergency.admin');
const aiRoutes = require('./src/routes/ai');

// Middleware
const requireAuth = require('./src/middleware/requireAuth');
const requireRole = require('./src/middleware/requireRole');

const app = express();

/** CORS */
const originsFromEnv = (process.env.CORS_ORIGIN || '')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);

const corsOptions = {
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    if (originsFromEnv.includes('*') || originsFromEnv.includes(origin)) return cb(null, true);
    if (/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) return cb(null, true);
    if (/^http:\/\/(10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+)(:\d+)?$/i.test(origin)) return cb(null, true);
    return cb(new Error('Not allowed by CORS'));
  },
  methods: ['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type','Authorization'],
  exposedHeaders: ['Content-Disposition'],
  credentials: false,
};
app.use(cors(corsOptions));

// Static uploads
app.use('/uploads', express.static(process.env.UPLOAD_PATH || './uploads'));

app.use(helmet());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('dev'));

const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW || 60000),
  max: Number(process.env.RATE_LIMIT_MAX || 120),
});
app.use(limiter);

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/emergency', emergencyUserRoutes); // user CRUD
app.use('/api/ai', aiRoutes);
app.use('/api/admin/emergency', emergencyAdminRouter);

// Admin mount
app.use('/api/admin', requireAuth, requireRole('admin','authority'), adminRoutes);
app.use('/api/admin/emergency', require('./src/routes/emergency.admin.js'));


app.get('/api/health', (_req, res) => {
  res.json({ success: true, status: 'healthy', timestamp: new Date().toISOString(), version: 'v3.0.0' });
});

const PORT = process.env.PORT || 4000;
connectDB().then(() => {
  app.listen(PORT, () => console.log(`API listening on http://localhost:${PORT}/api`));
});
