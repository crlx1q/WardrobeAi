const express = require('express');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const PLANS = [
  {
    id: 'free',
    name: 'Free',
    price: '0 ₽',
    period: '',
    features: [
      'AI-каталогизация вещей по фото',
      'Гардероб и избранное',
      'Один образ дня под погоду',
    ],
  },
  {
    id: 'premium',
    name: 'Premium',
    price: '499 ₽',
    period: '/ мес',
    highlighted: true,
    features: [
      'Всё из Free',
      'Новые варианты образа в один тап',
      'Подбор образов под события и дресс-код',
      'Учёт истории носки и аналитика',
      'Приоритетное распознавание',
    ],
  },
];

// GET /api/subscription — plans + current status
router.get('/', authenticate, (req, res) => {
  const active = req.user.isPremiumActive();
  res.json({
    plans: PLANS,
    current: {
      tier: active ? 'premium' : 'free',
      active,
      expiresAt: req.user.subscription?.expiresAt || null,
    },
    // No self-serve payment: premium is granted by an administrator.
    note: 'Premium активируется администратором. Свяжитесь с поддержкой для активации.',
  });
});

module.exports = router;
