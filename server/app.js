const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const env = require('./config/env');
const errorHandler = require('./middleware/errorHandler');
const { apiLimiter, rejectUnsafeKeys } = require('./middleware/security');
const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const providerRoutes = require('./routes/providerRoutes');
const serviceTakerRoutes = require('./routes/serviceTakerRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adRoutes = require('./routes/adRoutes');
const categoryRoutes = require('./routes/categoryRoutes');

const app = express();
const allowedOrigins = new Set([env.clientUrl, ...env.clientUrls]);

app.disable('x-powered-by');
if (env.nodeEnv === 'production') app.set('trust proxy', 1);

app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  strictTransportSecurity: env.nodeEnv === 'production'
    ? { maxAge: 31536000, includeSubDomains: true, preload: true }
    : false,
}));
app.use(cors({
  origin(origin, callback) {
    if (!origin || env.nodeEnv !== 'production' || allowedOrigins.has(origin)) {
      callback(null, true);
      return;
    }
    callback(new Error('Origin is not allowed'));
  },
  credentials: false,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type'],
  maxAge: 600,
}));
app.use(express.json({ limit: '8mb', strict: true }));
app.use(express.urlencoded({ extended: false, limit: '1mb', parameterLimit: 100 }));
app.use(rejectUnsafeKeys);
app.use('/api', apiLimiter, (req, res, next) => {
  res.setHeader('Cache-Control', 'no-store');
  next();
});
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev', {
  skip: (req) => req.path.startsWith('/api/health'),
}));

// KYC identity documents are never public static assets.
app.use('/uploads/kyc', (req, res) => res.status(404).json({ message: 'Not found' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  dotfiles: 'deny',
  fallthrough: false,
  maxAge: env.nodeEnv === 'production' ? '1d' : 0,
  setHeaders: (res) => res.setHeader('X-Content-Type-Options', 'nosniff'),
}));

app.get('/', (req, res) => res.json({ status: 'ok', message: 'Vipra Setu API is running' }));
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/providers', providerRoutes);
app.use('/api/service-takers', serviceTakerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/categories', categoryRoutes);

app.use((req, res) => res.status(404).json({ message: 'Route not found' }));
app.use(errorHandler);

module.exports = app;