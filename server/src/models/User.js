const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema(
  {
    tier: { type: String, enum: ['free', 'premium'], default: 'free' },
    expiresAt: { type: Date, default: null },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    name: { type: String, default: '' },
    avatarUrl: { type: String, default: '' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    subscription: { type: subscriptionSchema, default: () => ({}) },
    location: {
      lat: { type: Number, default: null },
      lon: { type: Number, default: null },
      city: { type: String, default: '' },
    },
  },
  { timestamps: true }
);

userSchema.methods.isPremiumActive = function () {
  return (
    this.subscription &&
    this.subscription.tier === 'premium' &&
    this.subscription.expiresAt &&
    new Date(this.subscription.expiresAt).getTime() > Date.now()
  );
};

userSchema.methods.toPublic = function () {
  const premiumActive = this.isPremiumActive();
  return {
    id: this._id,
    email: this.email,
    name: this.name,
    avatarUrl: this.avatarUrl,
    role: this.role,
    subscription: {
      tier: premiumActive ? 'premium' : 'free',
      expiresAt: this.subscription ? this.subscription.expiresAt : null,
      active: premiumActive,
    },
    location: this.location,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('User', userSchema);
