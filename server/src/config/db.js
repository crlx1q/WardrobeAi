const mongoose = require('mongoose');
const env = require('./env');

async function connectDB() {
  mongoose.set('strictQuery', true);
  try {
    await mongoose.connect(env.MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log('[db] connected to MongoDB');
  } catch (err) {
    console.error('[db] connection error:', err.message);
    console.error('[db] Set a valid MONGO_URI in server/.env (MongoDB Atlas). Server will keep running but DB calls will fail.');
  }

  mongoose.connection.on('disconnected', () => console.warn('[db] disconnected'));
  mongoose.connection.on('reconnected', () => console.log('[db] reconnected'));
}

module.exports = connectDB;
