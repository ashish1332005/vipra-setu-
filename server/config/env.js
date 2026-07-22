require('dotenv').config();

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';
const mongoUri = process.env.MONGO_URI || (isProduction ? '' : 'mongodb://127.0.0.1:27017/vipra-setu');
const jwtSecret = process.env.JWT_SECRET || (isProduction ? '' : 'dev_secret_change_me_only_for_local');

if (isProduction && !mongoUri) throw new Error('MONGO_URI is required in production.');
if (isProduction && (!jwtSecret || jwtSecret.length < 32)) {
  throw new Error('JWT_SECRET must be a random value of at least 32 characters in production.');
}
if (isProduction && jwtSecret.includes('dev_secret')) {
  throw new Error('JWT_SECRET must not use a development fallback in production.');
}

const clientUrls = (process.env.CLIENT_URLS || process.env.CLIENT_URL || '')
  .split(',')
  .map((url) => url.trim().replace(/\/$/, ''))
  .filter(Boolean);

if (isProduction && clientUrls.some((url) => !url.startsWith('https://'))) {
  throw new Error('Every production CLIENT_URLS origin must use HTTPS.');
}
if (isProduction && clientUrls.length === 0) {
  throw new Error('CLIENT_URL or CLIENT_URLS is required in production.');
}

module.exports = {
  nodeEnv,
  port: Number(process.env.PORT) || 5000,
  mongoUri,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '1h',
  jwtIssuer: process.env.JWT_ISSUER || 'vipra-sewa-setu-api',
  jwtAudience: process.env.JWT_AUDIENCE || 'vipra-sewa-setu-app',
  clientUrl: process.env.CLIENT_URL || clientUrls[0] || 'http://localhost:5173',
  clientUrls,
  emailFrom: process.env.EMAIL_FROM || 'no-reply@viprasevasetu.com',
  smtp: {
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true' || Number(process.env.SMTP_PORT) === 465,
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
};