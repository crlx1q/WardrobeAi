const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { authenticate, signToken } = require('../middleware/auth');

const router = express.Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body || {};
    if (!email || !EMAIL_RE.test(email)) return res.status(400).json({ error: 'Некорректный email' });
    if (!password || password.length < 6)
      return res.status(400).json({ error: 'Пароль должен быть не короче 6 символов' });

    const exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(409).json({ error: 'Пользователь с таким email уже существует' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ email: email.toLowerCase(), passwordHash, name: name || '' });
    const token = signToken(user);
    res.status(201).json({ token, user: user.toPublic() });
  } catch (err) {
    console.error('[auth] register', err.message);
    res.status(500).json({ error: 'Не удалось зарегистрироваться' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'Введите email и пароль' });

    const user = await User.findOne({ email: String(email).toLowerCase() });
    if (!user) return res.status(401).json({ error: 'Неверный email или пароль' });

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ error: 'Неверный email или пароль' });

    const token = signToken(user);
    res.json({ token, user: user.toPublic() });
  } catch (err) {
    console.error('[auth] login', err.message);
    res.status(500).json({ error: 'Не удалось войти' });
  }
});

router.get('/me', authenticate, async (req, res) => {
  res.json({ user: req.user.toPublic() });
});

router.patch('/me', authenticate, async (req, res) => {
  try {
    const { name, avatarUrl, location } = req.body || {};
    if (typeof name === 'string') req.user.name = name;
    if (typeof avatarUrl === 'string') req.user.avatarUrl = avatarUrl;
    if (location && typeof location === 'object') {
      req.user.location = {
        lat: location.lat ?? req.user.location.lat,
        lon: location.lon ?? req.user.location.lon,
        city: location.city ?? req.user.location.city,
      };
    }
    await req.user.save();
    res.json({ user: req.user.toPublic() });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось обновить профиль' });
  }
});

module.exports = router;
