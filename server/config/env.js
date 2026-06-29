require('dotenv').config();

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';
const mongoUri =
  process.env.MONGO_URI ||
  (isProduction ? '' : 'mongodb://127.0.0.1:27017/vipra-setu');
const jwtSecret = process.env.JWT_SECRET || (isProduction ? '' : 'dev_secret_change_me');

if (isProduction && !jwtSecret) {
  throw new Error('JWT_SECRET is required in production.');
}

if (isProduction && jwtSecret === 'dev_secret_change_me') {
  throw new Error('JWT_SECRET must not use the development fallback in production.');
}

module.exports = {
  nodeEnv,
  port: process.env.PORT || 5000,
  mongoUri,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  clientUrl: process.env.CLIENT_URL || 'https://vipra-setu-1.onrender.com',
  clientUrls: (process.env.CLIENT_URLS || 'https://vipra-setu-1.onrender.com,http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://localhost:5174,http://127.0.0.1:5173,http://127.0.0.1:5174')
    .split(',')
    .map((url) => url.trim())
    .filter(Boolean),
  emailFrom: process.env.EMAIL_FROM || 'no-reply@viprasevasetu.com',
  smtp: {
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true' || Number(process.env.SMTP_PORT) === 465,
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
};
