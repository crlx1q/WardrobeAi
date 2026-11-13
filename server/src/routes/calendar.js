const express = require('express');
const Event = require('../models/Event');
const Outfit = require('../models/Outfit');
const ClothingItem = require('../models/ClothingItem');
const { authenticate, requirePremium } = require('../middleware/auth');
const { composeOutfit } = require('../services/gemini');
const { getWeather } = require('../services/weather');
const { serialize } = require('./wardrobe');

const router = express.Router();
router.use(authenticate);

async function populateOutfit(outfit, userId) {
  if (!outfit) return null;
  const items = await ClothingItem.find({ _id: { $in: outfit.itemIds }, userId });
  return {
    id: outfit._id,
    title: outfit.title,
    rationale: outfit.rationale,
    tags: outfit.tags,
    source: outfit.source,
    date: outfit.date,
    items: items.map(serialize),
  };
}

// GET /api/calendar/events?from=&to=
router.get('/events', async (req, res) => {
  try {
    const filter = { userId: req.user._id };
    if (req.query.from || req.query.to) {
      filter.date = {};
      if (req.query.from) filter.date.$gte = new Date(req.query.from);
      if (req.query.to) filter.date.$lte = new Date(req.query.to);
    }
    const events = await Event.find(filter).sort({ date: 1 });
    const withOutfits = await Promise.all(
      events.map(async (e) => ({
        id: e._id,
        title: e.title,
        date: e.date,
        dressCode: e.dressCode,
        notes: e.notes,
        plannedOutfitId: e.plannedOutfitId,
      }))
    );
    res.json({ events: withOutfits });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось загрузить события' });
  }
});

// GET /api/calendar/outfits?from=&to=  — daily/worn outfits by date (for calendar thumbnails)
router.get('/outfits', async (req, res) => {
  try {
    const filter = { userId: req.user._id, date: { $ne: null } };
    if (req.query.from || req.query.to) {
      filter.date = {};
      if (req.query.from) filter.date.$gte = new Date(req.query.from);
      if (req.query.to) filter.date.$lte = new Date(req.query.to);
    }
    const outfits = await Outfit.find(filter).sort({ date: 1 });
    const populated = await Promise.all(outfits.map((o) => populateOutfit(o, req.user._id)));
    res.json({ outfits: populated });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось загрузить образы' });
  }
});

// POST /api/calendar/events
router.post('/events', async (req, res) => {
  try {
    const { title, date, dressCode, notes } = req.body || {};
    if (!title || !date) return res.status(400).json({ error: 'Укажите название и дату события' });
    const event = await Event.create({
      userId: req.user._id,
      title,
      date: new Date(date),
      dressCode: dressCode || '',
      notes: notes || '',
    });
    res.status(201).json({ event });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось создать событие' });
  }
});

// PATCH /api/calendar/events/:id
router.patch('/events/:id', async (req, res) => {
  try {
    const event = await Event.findOne({ _id: req.params.id, userId: req.user._id });
    if (!event) return res.status(404).json({ error: 'Событие не найдено' });
    const b = req.body || {};
    if (b.title !== undefined) event.title = b.title;
    if (b.date !== undefined) event.date = new Date(b.date);
    if (b.dressCode !== undefined) event.dressCode = b.dressCode;
    if (b.notes !== undefined) event.notes = b.notes;
    await event.save();
    res.json({ event });
  } catch (err) {
    res.status(400).json({ error: 'Не удалось обновить событие' });
  }
});

// DELETE /api/calendar/events/:id
router.delete('/events/:id', async (req, res) => {
  try {
    const deleted = await Event.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!deleted) return res.status(404).json({ error: 'Событие не найдено' });
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: 'Не удалось удалить событие' });
  }
});

// POST /api/calendar/events/:id/plan-outfit — AI outfit honoring the dress code
router.post('/events/:id/plan-outfit', requirePremium, async (req, res) => {
  try {
    const event = await Event.findOne({ _id: req.params.id, userId: req.user._id });
    if (!event) return res.status(404).json({ error: 'Событие не найдено' });

    const items = await ClothingItem.find({ userId: req.user._id });
    if (items.length === 0)
      return res.status(400).json({ error: 'Добавьте вещи в гардероб для подбора образа' });

    const weather = await getWeather(req.user.location?.lat, req.user.location?.lon);
    const catalog = items.map((i) => ({
      id: i._id,
      name: i.name,
      type: i.type,
      category: i.category,
      color: i.color,
      material: i.material,
      tags: i.tags,
      wearCount: i.wearCount,
    }));

    const composed = await composeOutfit({
      items: catalog,
      weather,
      event: { title: event.title, dressCode: event.dressCode },
    });

    const outfit = await Outfit.create({
      userId: req.user._id,
      itemIds: composed.itemIds,
      title: composed.title,
      rationale: composed.rationale,
      tags: composed.tags,
      date: event.date,
      source: 'event',
    });

    event.plannedOutfitId = outfit._id;
    await event.save();

    const populated = await populateOutfit(outfit, req.user._id);
    res.json({ outfit: populated, event });
  } catch (err) {
    console.error('[calendar] plan-outfit', err.message);
    res.status(500).json({ error: 'Не удалось подобрать образ' });
  }
});

module.exports = router;
