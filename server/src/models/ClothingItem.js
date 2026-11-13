const mongoose = require('mongoose');

// category maps garment types into the wardrobe filter tabs:
// top (Верхи), bottom (Низы), dress (Платья), outerwear, shoes, accessory
const clothingItemSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    imageUrl: { type: String, default: '' },
    name: { type: String, default: '' },
    type: { type: String, default: '' },
    category: {
      type: String,
      enum: ['top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other'],
      default: 'other',
    },
    color: { type: String, default: '' },
    material: { type: String, default: '' },
    tags: { type: [String], default: [] },
    favorite: { type: Boolean, default: false },
    wearCount: { type: Number, default: 0 },
    lastWornAt: { type: Date, default: null },
  },
  { timestamps: true }
);

clothingItemSchema.methods.toPublic = function () {
  return {
    id: this._id,
    imageUrl: this.imageUrl,
    name: this.name,
    type: this.type,
    category: this.category,
    color: this.color,
    material: this.material,
    tags: this.tags,
    favorite: this.favorite,
    wearCount: this.wearCount,
    lastWornAt: this.lastWornAt,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('ClothingItem', clothingItemSchema);
