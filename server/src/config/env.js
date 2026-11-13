require('dotenv').config();

const env = {
  PORT: parseInt(process.env.PORT || '4000', 10),
  PUBLIC_URL: (process.env.PUBLIC_URL || `http://localhost:${process.env.PORT || 4000}`).replace(/\/$/, ''),
  MONGO_URI: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/capsule',
  JWT_SECRET: process.env.JWT_SECRET || 'dev-insecure-secret-change-me',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  GEMINI_MODEL: process.env.GEMINI_MODEL || 'gemini-1.5-flash',
  ADMIN_EMAIL: process.env.ADMIN_EMAIL || 'admin@capsule.app',
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD || 'capsule-admin',
  ADMIN_NAME: process.env.ADMIN_NAME || 'Capsule Admin',
};

module.exports = env;
