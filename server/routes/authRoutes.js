const express = require('express');
const {
  register, login, getMe, updateMe, changePassword,
  verifyEmail, resendVerification,
} = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { authLimiter, recoveryLimiter } = require('../middleware/security');

const router = express.Router();

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/verify-email', authLimiter, verifyEmail);
router.post('/resend-verification', recoveryLimiter, resendVerification);
router.get('/me', protect, getMe);
router.patch('/me', protect, updateMe);
router.patch('/password', protect, authorize('admin'), authLimiter, changePassword);

module.exports = router;