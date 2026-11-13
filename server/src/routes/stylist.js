const express = require('express');
const ClothingItem = require('../models/ClothingItem');
const Outfit = require('../models/Outfit');
const { authenticate, requirePremium } = require('../middleware/auth');
const { composeOutfit } = require('../services/gemini');
const { getWeather } = require('../services/weather');
const { serialize } = require('./wardrobe');

const router = express.Router();
router.use(authenticate);

async function buildOutfitResponse(user, { avoidItemIds = [], event = null } = {}) {
  const items = await ClothingItem.find({ userId: user._id });
  if (items.length === 0) {
    return { empty: true };
  }
  const weather = await getWeather(user.location?.lat, user.location?.lon);

  const catalog = items.map((i) => ({
    id: i._id,
    name: i.name,
    type: i.type,
    category: i.category,
    color: i.color,
    material: i.material,
    tags: i.tags,
    wearCount: i.wearCount,
    lastWornAt: i.lastWornAt,
  }));

  const composed = await composeOutfit({ items: catalog, weather, event, avoidItemIds });
  const byId = new Map(items.map((i) => [String(i._id), i]));
  const outfitItems = composed.itemIds.map((id) => byId.get(String(id))).filter(Boolean);

  return {
    empty: false,
    weather,
    outfit: {
      title: composed.title,
      rationale: composed.rationale,
      tags: composed.tags,
      items: outfitItems.map(serialize),
      itemIds: composed.itemIds,
    },
  };
}

// GET /api/stylist/today — outfit of the day
router.get('/today', async (req, res) => {
  try {
    const result = await buildOutfitResponse(req.user);
    if (result.empty) {
      return res.json({ empty: true, message: 'Добавьте вещи в гардероб, чтобы получить образ дня.' });
    }

    // persist as the daily outfit (upsert for today)
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    await Outfit.findOneAndUpdate(
      { userId: req.user._id, source: 'daily', date: { $gte: startOfDay } },
      {
        userId: req.user._id,
        source: 'daily',
        date: new Date(),
        itemIds: result.outfit.itemIds,
        title: result.outfit.title,
        rationale: result.outfit.rationale,
        tags: result.outfit.tags,
      },
      { upsert: true, new: true }
    );

    res.json(result);
  } catch (err) {
    console.error('[stylist] today', err.message);
    res.status(500).json({ error: 'Не удалось подобрать образ' });
  }
});

// POST /api/stylist/regenerate  { avoidItemIds?: [] } — "Другой вариант"
router.post('/regenerate', requirePremium, async (req, res) => {
  try {
    const avoidItemIds = Array.isArray(req.body?.avoidItemIds)
      ? req.body.avoidItemIds.map(String)
      : [];
    const result = await buildOutfitResponse(req.user, { avoidItemIds });
    if (result.empty) return res.json({ empty: true });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Не удалось подобрать образ' });
  }
});

// POST /api/stylist/wear  { itemIds: [] } — mark outfit as worn
router.post('/wear', async (req, res) => {
  try {
    const itemIds = Array.isArray(req.body?.itemIds) ? req.body.itemIds : [];
    if (itemIds.length === 0) return res.status(400).json({ error: 'Не переданы вещи' });

    await ClothingItem.updateMany(
      { _id: { $in: itemIds }, userId: req.user._id },
      { $inc: { wearCount: 1 }, $set: { lastWornAt: new Date() } }
    );

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    await Outfit.findOneAndUpdate(
      { userId: req.user._id, source: 'daily', date: { $gte: startOfDay } },
      { $set: { worn: true, itemIds } }
    );

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось отметить образ' });
  }
});

module.exports = { router, buildOutfitResponse };
