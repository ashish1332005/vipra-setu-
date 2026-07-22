const jwt = require('jsonwebtoken');
const User = require('../models/User');
const env = require('../config/env');
const asyncHandler = require('../utils/asyncHandler');

const protect = asyncHandler(async (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer\s+([^\s]+)$/i);
  if (!match) {
    res.status(401);
    throw new Error('Authentication required');
  }

  let decoded;
  try {
    decoded = jwt.verify(match[1], env.jwtSecret, {
      algorithms: ['HS256'],
      issuer: env.jwtIssuer,
      audience: env.jwtAudience,
    });
  } catch (_) {
    res.status(401);
    throw new Error('Invalid or expired session');
  }

  const user = await User.findById(decoded.sub).select('+tokenVersion');
  if (!user || user.status === 'banned' || (user.tokenVersion || 0) !== (decoded.tokenVersion || 0)) {
    res.status(401);
    throw new Error('Invalid or expired session');
  }

  req.user = user;
  next();
});

const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    res.status(403);
    throw new Error('Access denied');
  }
  next();
};

const requireVerifiedEmail = (req, res, next) => {
  if (!req.user?.emailVerifiedAt) {
    res.status(403);
    throw new Error('Please verify your email before using this feature');
  }
  next();
};

module.exports = { protect, authorize, requireVerifiedEmail };