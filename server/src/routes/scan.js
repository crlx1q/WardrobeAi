const express = require('express');
const { authenticate } = require('../middleware/auth');
const { upload } = require('../middleware/upload');
const { recognizeGarment } = require('../services/gemini');
const { saveImage } = require('./images');

const router = express.Router();
router.use(authenticate);

// POST /api/scan  (multipart: image)
// Recognizes garment attributes and returns them for user confirmation.
// The image is stored in the DB and its relative URL returned so the client
// can reuse it when saving the item (no second upload needed).
router.post('/', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Прикрепите фото' });

    const [attributes, imageUrl] = await Promise.all([
      recognizeGarment(req.file.buffer, req.file.mimetype),
      saveImage(req.user._id, req.file),
    ]);

    res.json({ imageUrl, attributes });
  } catch (err) {
    console.error('[scan]', err.message);
    res.status(500).json({ error: 'Не удалось распознать вещь' });
  }
});

module.exports = router;
