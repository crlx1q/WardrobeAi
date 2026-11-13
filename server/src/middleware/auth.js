const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/User');

async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'Требуется авторизация' });

    const payload = jwt.verify(token, env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (!user) return res.status(401).json({ error: 'Пользователь не найден' });

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Недействительный токен' });
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Доступ только для администратора' });
  }
  next();
}

function requirePremium(req, res, next) {
  if (!req.user || !req.user.isPremiumActive()) {
    return res.status(402).json({
      error: 'Эта функция доступна в подписке Premium',
      code: 'PREMIUM_REQUIRED',
    });
  }
  next();
}

function signToken(user) {
  return jwt.sign({ sub: user._id.toString(), role: user.role }, env.JWT_SECRET);
}

module.exports = { authenticate, requireAdmin, requirePremium, signToken };
