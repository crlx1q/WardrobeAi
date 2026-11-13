const mongoose = require('mongoose');

// Images are stored in MongoDB so they persist across deploys (e.g. Koyeb's
// ephemeral filesystem) and are always reachable from the app.
const imageSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    contentType: { type: String, default: 'image/jpeg' },
    data: { type: Buffer, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Image', imageSchema);
