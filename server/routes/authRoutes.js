const express = require('express');
const {
  register, login, getMe, updateMe, changePassword,
  forgotPassword, resetPassword, verifyEmail, resendVerification,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const { authLimiter, recoveryLimiter } = require('../middleware/security');

const router = express.Router();

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/verify-email', authLimiter, verifyEmail);
router.post('/resend-verification', recoveryLimiter, resendVerification);
router.post('/forgot-password', recoveryLimiter, forgotPassword);
router.post('/reset-password', recoveryLimiter, resetPassword);
router.get('/me', protect, getMe);
router.patch('/me', protect, updateMe);
router.patch('/password', protect, authLimiter, changePassword);

module.exports = router;
