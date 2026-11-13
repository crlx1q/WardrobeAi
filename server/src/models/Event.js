const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    date: { type: Date, required: true },
    dressCode: { type: String, default: '' },
    notes: { type: String, default: '' },
    plannedOutfitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Outfit', default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Event', eventSchema);
