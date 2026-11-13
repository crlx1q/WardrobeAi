const express = require('express');
const ClothingItem = require('../models/ClothingItem');
const { authenticate } = require('../middleware/auth');
const { upload } = require('../middleware/upload');
const { saveImage } = require('./images');

const router = express.Router();
router.use(authenticate);

// Map filter tab -> categories
const TAB_CATEGORIES = {
  all: null,
  top: ['top'],
  bottom: ['bottom'],
  dress: ['dress'],
  outerwear: ['outerwear'],
  shoes: ['shoes'],
  accessory: ['accessory'],
};

// Image URLs are returned relative (e.g. /api/images/:id). The app resolves
// them against its own API base URL, which avoids localhost/domain mismatches.
function serialize(item) {
  return item.toPublic();
}

// GET /api/wardrobe?category=all|top|bottom|dress&favorite=true
router.get('/', async (req, res) => {
  try {
    const { category = 'all', favorite } = req.query;
    const filter = { userId: req.user._id };
    const cats = TAB_CATEGORIES[category];
    if (cats) filter.category = { $in: cats };
    if (favorite === 'true') filter.favorite = true;

    const items = await ClothingItem.find(filter).sort({ createdAt: -1 });
    const counts = await ClothingItem.countDocuments({ userId: req.user._id });
    res.json({ items: items.map(serialize), total: counts });
  } catch (err) {
    res.status(500).json({ error: 'Не удалось загрузить гардероб' });
  }
});

// GET /api/wardrobe/:id
router.get('/:id', async (req, res) => {
  try {
    const item = await ClothingItem.findOne({ _id: req.params.id, userId: req.user._id });
    if (!item) return res.status(404).json({ error: 'Вещь не найдена' });
    res.json({ item: serialize(item) });
  } catch (err) {
    res.status(400).json({ error: 'Некорректный запрос' });
  }
});

// POST /api/wardrobe  (multipart: image optional + attributes)
router.post('/', upload.single('image'), async (req, res) => {
  try {
    const b = req.body || {};
    const imageUrl = req.file ? await saveImage(req.user._id, req.file) : b.imageUrl || '';
    const item = await ClothingItem.create({
      userId: req.user._id,
      imageUrl,
      name: b.name || 'Новая вещь',
      type: b.type || '',
      category: b.category || 'other',
      color: b.color || '',
      material: b.material || '',
      tags: parseTags(b.tags),
      favorite: b.favorite === 'true' || b.favorite === true,
    });
    res.status(201).json({ item: serialize(item) });
  } catch (err) {
    console.error('[wardrobe] create', err.message);
    res.status(500).json({ error: 'Не удалось сохранить вещь' });
  }
});

// PATCH /api/wardrobe/:id
router.patch('/:id', async (req, res) => {
  try {
    const item = await ClothingItem.findOne({ _id: req.params.id, userId: req.user._id });
    if (!item) return res.status(404).json({ error: 'Вещь не найдена' });
    const b = req.body || {};
    ['name', 'type', 'category', 'color', 'material', 'imageUrl'].forEach((k) => {
      if (b[k] !== undefined) item[k] = b[k];
    });
    if (b.tags !== undefined) item.tags = parseTags(b.tags);
    if (b.favorite !== undefined) item.favorite = b.favorite === true || b.favorite === 'true';
    await item.save();
    res.json({ item: serialize(item) });
  } catch (err) {
    res.status(400).json({ error: 'Не удалось обновить вещь' });
  }
});

// POST /api/wardrobe/:id/favorite  (toggle)
router.post('/:id/favorite', async (req, res) => {
  try {
    const item = await ClothingItem.findOne({ _id: req.params.id, userId: req.user._id });
    if (!item) return res.status(404).json({ error: 'Вещь не найдена' });
    item.favorite = !item.favorite;
    await item.save();
    res.json({ item: serialize(item) });
  } catch (err) {
    res.status(400).json({ error: 'Не удалось обновить' });
  }
});

// DELETE /api/wardrobe/:id
router.delete('/:id', async (req, res) => {
  try {
    const deleted = await ClothingItem.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!deleted) return res.status(404).json({ error: 'Вещь не найдена' });
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: 'Не удалось удалить' });
  }
});

function parseTags(tags) {
  if (Array.isArray(tags)) return tags.map(String);
  if (typeof tags === 'string' && tags.trim()) {
    try {
      const parsed = JSON.parse(tags);
      if (Array.isArray(parsed)) return parsed.map(String);
    } catch {
      return tags.split(',').map((t) => t.trim()).filter(Boolean);
    }
  }
  return [];
}

module.exports = { router, serialize };
