const express = require('express');
const User = require('../models/User');
const ClothingItem = require('../models/ClothingItem');
const Outfit = require('../models/Outfit');
const Event = require('../models/Event');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate, requireAdmin);

// GET /api/admin/stats
router.get('/stats', async (req, res) => {
  try {
    const now = new Date();
    const [users, premium, items, outfits, events] = await Promise.all([
      User.countDocuments({}),
      User.countDocuments({ 'subscription.tier': 'premium', 'subscription.expiresAt': { $gt: now } }),
      ClothingItem.countDocuments({}),
      Outfit.countDocuments({}),
      Event.countDocuments({}),
    ]);
    res.json({ stats: { users, premiumActive: premium, items, outfits, events } });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось получить статистику' });
  }
});

// GET /api/admin/users?search=&page=&limit=
router.get('/users', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || '25', 10)));
    const search = (req.query.search || '').trim();
    const filter = search
      ? { $or: [{ email: new RegExp(search, 'i') }, { name: new RegExp(search, 'i') }] }
      : {};

    const [users, total] = await Promise.all([
      User.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
      User.countDocuments(filter),
    ]);

    res.json({
      users: users.map((u) => u.toPublic()),
      total,
      page,
      pages: Math.ceil(total / limit),
    });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось загрузить пользователей' });
  }
});

// POST /api/admin/users/:id/grant  { days }
// Grants (or extends) premium by N days. Negative days revoke.
router.post('/users/:id/grant', async (req, res) => {
  try {
    const days = parseInt(req.body?.days, 10);
    if (Number.isNaN(days)) return res.status(400).json({ error: 'Укажите количество дней' });

    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Пользователь не найден' });

    const now = Date.now();
    const base =
      user.subscription?.expiresAt && new Date(user.subscription.expiresAt).getTime() > now
        ? new Date(user.subscription.expiresAt).getTime()
        : now;
    const newExpiry = new Date(base + days * 24 * 60 * 60 * 1000);

    if (newExpiry.getTime() <= now) {
      user.subscription = { tier: 'free', expiresAt: null };
    } else {
      user.subscription = { tier: 'premium', expiresAt: newExpiry };
    }
    await user.save();
    res.json({ user: user.toPublic() });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось изменить подписку' });
  }
});

// POST /api/admin/users/:id/revoke — remove premium
router.post('/users/:id/revoke', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'Пользователь не найден' });
    user.subscription = { tier: 'free', expiresAt: null };
    await user.save();
    res.json({ user: user.toPublic() });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось отозвать подписку' });
  }
});

// DELETE /api/admin/users/:id
router.delete('/users/:id', async (req, res) => {
  try {
    if (String(req.params.id) === String(req.user._id))
      return res.status(400).json({ error: 'Нельзя удалить самого себя' });
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'Пользователь не найден' });
    await Promise.all([
      ClothingItem.deleteMany({ userId: user._id }),
      Outfit.deleteMany({ userId: user._id }),
      Event.deleteMany({ userId: user._id }),
    ]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось удалить пользователя' });
  }
});

module.exports = router;
