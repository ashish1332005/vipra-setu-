const jwt = require('jsonwebtoken');
const env = require('../config/env');

const generateToken = (user) => jwt.sign(
  {
    sub: user._id.toString(),
    role: user.role,
    tokenVersion: user.tokenVersion || 0,
  },
  env.jwtSecret,
  {
    algorithm: 'HS256',
    expiresIn: env.jwtExpiresIn,
    issuer: env.jwtIssuer,
    audience: env.jwtAudience,
  }
);

module.exports = generateToken;