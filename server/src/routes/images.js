const express = require('express');
const Image = require('../models/Image');

const router = express.Router();

// Public read: images are referenced by their unguessable ObjectId.
// GET /api/images/:id
router.get('/:id', async (req, res) => {
  try {
    const img = await Image.findById(req.params.id);
    if (!img) return res.status(404).json({ error: 'Изображение не найдено' });
    res.set('Content-Type', img.contentType || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=31536000, immutable');
    res.send(img.data);
  } catch (err) {
    res.status(400).json({ error: 'Некорректный запрос' });
  }
});

module.exports = router;

// Helper reused by other routes to persist an uploaded buffer.
module.exports.saveImage = async function saveImage(userId, file) {
  if (!file || !file.buffer) return '';
  const img = await Image.create({
    userId,
    contentType: file.mimetype || 'image/jpeg',
    data: file.buffer,
  });
  return `/api/images/${img._id}`;
};
