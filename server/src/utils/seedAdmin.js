const bcrypt = require('bcryptjs');
const User = require('../models/User');
const env = require('../config/env');

async function seedAdmin() {
  try {
    const existing = await User.findOne({ email: env.ADMIN_EMAIL.toLowerCase() });
    if (existing) {
      if (existing.role !== 'admin') {
        existing.role = 'admin';
        await existing.save();
      }
      return;
    }
    const passwordHash = await bcrypt.hash(env.ADMIN_PASSWORD, 10);
    await User.create({
      email: env.ADMIN_EMAIL.toLowerCase(),
      passwordHash,
      name: env.ADMIN_NAME,
      role: 'admin',
    });
    console.log(`[seed] admin created: ${env.ADMIN_EMAIL}`);
  } catch (err) {
    console.warn('[seed] admin seed skipped:', err.message);
  }
}

module.exports = seedAdmin;
