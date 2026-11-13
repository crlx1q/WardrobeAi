const mongoose = require('mongoose');

const outfitSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    itemIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ClothingItem' }],
    title: { type: String, default: '' },
    rationale: { type: String, default: '' },
    tags: { type: [String], default: [] },
    date: { type: Date, default: null },
    source: { type: String, enum: ['daily', 'event', 'manual'], default: 'daily' },
    worn: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Outfit', outfitSchema);
