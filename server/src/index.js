const path = require('path');
const fs = require('fs');
const os = require('os');
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const env = require('./config/env');
const connectDB = require('./config/db');
const seedAdmin = require('./utils/seedAdmin');

const authRoutes = require('./routes/auth');
const imageRoutes = require('./routes/images');
const { router: wardrobeRoutes } = require('./routes/wardrobe');
const scanRoutes = require('./routes/scan');
const { router: stylistRoutes } = require('./routes/stylist');
const calendarRoutes = require('./routes/calendar');
const subscriptionRoutes = require('./routes/subscription');
const adminRoutes = require('./routes/admin');

const app = express();

app.use(cors());
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true }));

// Static assets
app.use('/downloads', express.static(path.join(__dirname, '..', 'downloads')));
app.use(express.static(path.join(__dirname, '..', 'public')));

// Health (works even without a DB connection)
app.get('/api/health', (req, res) => {
  res.json({
    ok: true,
    service: 'capsule',
    gemini: Boolean(env.GEMINI_API_KEY),
    db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

// Guard: return a clear 503 (instead of a confusing 500) when the DB is down.
app.use('/api', (req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    // Detailed reason is logged server-side; users see a clean message.
    console.warn('[db] request blocked — database not connected');
    return res.status(503).json({
      error: 'Сервис временно недоступен. Попробуйте позже.',
      code: 'DB_UNAVAILABLE',
    });
  }
  next();
});

// API routes
app.use('/api/images', imageRoutes); // public read
app.use('/api/auth', authRoutes);
app.use('/api/wardrobe', wardrobeRoutes);
app.use('/api/scan', scanRoutes);
app.use('/api/stylist', stylistRoutes);
app.use('/api/calendar', calendarRoutes);
app.use('/api/subscription', subscriptionRoutes);
app.use('/api/admin', adminRoutes);

// Admin panel
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'admin.html'));
});

// App download. Drop the built APK at server/downloads/capsule.apk to enable it.
app.get('/download', (req, res) => {
  const apk = path.join(__dirname, '..', 'downloads', 'capsule.apk');
  if (fs.existsSync(apk)) {
    return res.download(apk, 'Capsule.apk');
  }
  res.status(200).type('html').send(`<!DOCTYPE html><html lang="ru"><head><meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Capsule — скоро</title>
  <style>
    body{font-family:'Inter',system-ui,sans-serif;background:#fdf8f8;color:#1c1b1b;
      display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;text-align:center;padding:24px}
    .card{background:#fff;border-radius:28px;box-shadow:0 18px 50px rgba(28,27,27,.12);padding:48px;max-width:420px}
    h1{font-family:Georgia,serif;font-size:30px;margin:0 0 12px}
    p{color:#444748;line-height:1.6}
    a{display:inline-block;margin-top:24px;background:#1c1b1b;color:#fff;text-decoration:none;
      padding:14px 26px;border-radius:999px;font-weight:600}
  </style></head><body><div class="card">
    <h1>✦ Скоро</h1>
    <p>Сборка приложения ещё готовится. Загляните чуть позже — здесь появится ссылка на скачивание Capsule.</p>
    <a href="/">На главную</a>
  </div></body></html>`);
});

// 404 (JSON for API, redirect to landing otherwise)
app.use((req, res) => {
  if (req.path.startsWith('/api')) return res.status(404).json({ error: 'Не найдено' });
  res.redirect('/');
});

// Error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('[error]', err.message);
  res.status(err.status || 500).json({ error: err.message || 'Внутренняя ошибка сервера' });
});

function localIPv4s() {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) ips.push(net.address);
    }
  }
  return ips;
}

function printBanner() {
  const c = {
    reset: '\x1b[0m',
    dim: '\x1b[2m',
    bold: '\x1b[1m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
  };
  const ok = (v) => (v ? `${c.green}✓${c.reset}` : `${c.yellow}✗${c.reset}`);
  const port = env.PORT;
  const ips = localIPv4s();
  const dbUp = mongoose.connection.readyState === 1;

  const line = `${c.gray}────────────────────────────────────────────────${c.reset}`;
  const rows = [
    '',
    `  ${c.bold}${c.cyan}✦  Capsule API${c.reset}  ${c.dim}online${c.reset}`,
    line,
    `  ${c.bold}Local${c.reset}     ${c.cyan}http://localhost:${port}${c.reset}`,
    ...ips.map((ip) => `  ${c.bold}Network${c.reset}   ${c.cyan}http://${ip}:${port}${c.reset}`),
    `  ${c.bold}Landing${c.reset}   ${c.dim}/${c.reset}`,
    `  ${c.bold}Admin${c.reset}     ${c.dim}/admin${c.reset}`,
    `  ${c.bold}Health${c.reset}    ${c.dim}/api/health${c.reset}`,
    line,
    `  ${ok(env.GEMINI_API_KEY)} Gemini AI       ${env.GEMINI_API_KEY ? `${c.dim}${env.GEMINI_MODEL}${c.reset}` : `${c.yellow}fallback data${c.reset}`}`,
    `  ${ok(dbUp)} MongoDB         ${dbUp ? `${c.green}connected${c.reset}` : `${c.yellow}not connected — set MONGO_URI${c.reset}`}`,
    '',
  ];
  console.log(rows.join('\n'));
}

async function start() {
  await connectDB();
  await seedAdmin();
  app.listen(env.PORT, '0.0.0.0', () => {
    printBanner();
  });
}

start();
