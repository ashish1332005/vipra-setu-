const User = require('../models/User');

const ensureAdmin = async () => {
  const name = process.env.ADMIN_NAME || 'Admin';
  const email = process.env.ADMIN_EMAIL || 'admin@example.com';
  const phone = normalizePhone(process.env.ADMIN_PHONE || '');
  const password = process.env.ADMIN_PASSWORD || '';

  if (!phone || !password) {
    throw new Error('ADMIN_PHONE and ADMIN_PASSWORD are required before creating or updating the admin account.');
  }

  if (process.env.NODE_ENV === 'production' && password.length < 12) {
    throw new Error('ADMIN_PASSWORD must be at least 12 characters in production.');
  }

  const existingAdmin = await User.findOne({
    $or: [
      { email },
      { phone },
      { role: 'admin' },
    ],
  }).select('+password');

  if (existingAdmin) {
    existingAdmin.name = name;
    existingAdmin.password = password;
    existingAdmin.phone = phone;
    existingAdmin.role = 'admin';
    existingAdmin.status = 'active';
    existingAdmin.emailVerifiedAt = existingAdmin.emailVerifiedAt || new Date();
    await existingAdmin.save();

    console.log(`Admin updated: ${email}`);
    return;
  }

  await User.create({
    name,
    email,
    phone,
    password,
    role: 'admin',
    status: 'active',
    emailVerifiedAt: new Date(),
  });

  console.log(`Admin created: ${email}`);
};

const normalizePhone = (phone = '') => String(phone).replace(/\D/g, '');

module.exports = ensureAdmin;
