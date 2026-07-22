const { rateLimit } = require('express-rate-limit');

const makeLimiter = ({ windowMs, limit, message }) => rateLimit({
  windowMs,
  limit,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  skip: (req) => req.method === 'OPTIONS',
  message: { message },
});

const apiLimiter = makeLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 500,
  message: 'Too many requests. Please try again later.',
});

const authLimiter = makeLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  message: 'Too many authentication attempts. Please wait 15 minutes.',
});

const recoveryLimiter = makeLimiter({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  message: 'Too many password recovery attempts. Please try again later.',
});

const rejectUnsafeKeys = (req, res, next) => {
  try {
    assertSafe(req.body);
    assertSafe(req.query);
    assertSafe(req.params);
    next();
  } catch (_) {
    res.status(400).json({ message: 'Invalid request payload' });
  }
};

const assertSafe = (value, depth = 0) => {
  if (depth > 20) throw new Error('Payload nesting limit exceeded');
  if (!value || typeof value !== 'object') return;
  if (Array.isArray(value)) {
    value.forEach((item) => assertSafe(item, depth + 1));
    return;
  }
  for (const [key, child] of Object.entries(value)) {
    if (
      key.startsWith('$') ||
      key.includes('.') ||
      key === '__proto__' ||
      key === 'prototype' ||
      key === 'constructor'
    ) {
      throw new Error('Unsafe object key');
    }
    assertSafe(child, depth + 1);
  }
};

module.exports = { apiLimiter, authLimiter, recoveryLimiter, rejectUnsafeKeys };