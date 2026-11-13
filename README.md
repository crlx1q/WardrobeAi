# Capsule — AI Wardrobe & Outfit Planner

Capsule is an AI-powered capsule wardrobe app. Photograph your clothes, let AI
catalogue them (type / colour / material), and get daily outfit suggestions that
factor in the weather, upcoming events, dress codes and what you have already worn.

- **Mobile app**: Flutter (Dart) — `app/`
- **Backend**: Node.js + Express + MongoDB (Mongoose) — `server/`
- **Admin panel**: `server/public/admin.html` (served at `/admin`)
- **AI**: Google **Gemini** (`gemini-1.5-flash`) for image recognition and outfit composition
- **Weather**: [Open-Meteo](https://open-meteo.com) (free, no key)
- **Design**: "Editorial Tech" system defined in [DESIGN.md](DESIGN.md)

Production domain (planned): `https://capsule.crlx1q.com` (hosted on Koyeb)

The server binds `0.0.0.0:$PORT` and prints Local + Network URLs on startup.
The public landing page is served at `/`, the admin panel at `/admin`.

---

## 1. Backend (`server/`)

### Setup

```bash
cd server
npm install
cp .env.example .env   # then edit values
npm start              # or: npm run dev  (auto-reload)
```

### Environment variables (`server/.env`)

| Variable | Description |
| --- | --- |
| `PORT` | HTTP port (default `4000`) |
| `PUBLIC_URL` | Base URL used to build absolute image links, e.g. `https://ward.crlx1q.com` |
| `MONGO_URI` | MongoDB Atlas connection string |
| `JWT_SECRET` | Secret for signing JWTs |
| `GEMINI_API_KEY` | Google Gemini API key ([get one](https://aistudio.google.com/app/apikey)) |
| `GEMINI_MODEL` | Defaults to `gemini-1.5-flash` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` | Seed admin account created on first boot |

> If `GEMINI_API_KEY` is empty the server still runs and returns sensible
> fallback data, so you can develop the UI before wiring up AI.
>
> If `MONGO_URI` is unreachable the server still boots (health check works) but
> DB-backed endpoints will error until a valid Atlas URI is provided.

### Key API routes (all under `/api`)

- `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `PATCH /auth/me`
- `GET/POST/PATCH/DELETE /wardrobe`, `POST /wardrobe/:id/favorite`
- `POST /scan` — recognise a garment from an uploaded image
- `GET /stylist/today`, `POST /stylist/regenerate`, `POST /stylist/wear`
- `GET/POST/PATCH/DELETE /calendar/events`, `GET /calendar/outfits`, `POST /calendar/events/:id/plan-outfit`
- `GET /subscription`
- `GET /admin/stats`, `GET /admin/users`, `POST /admin/users/:id/grant`, `POST /admin/users/:id/revoke`

### Admin panel

Open `http://localhost:4000/admin` and log in with the seeded admin account.
From there you can search users and **grant N days of Premium** (subscription is
admin-granted; there is no in-app payment).

---

## 2. Mobile app (`app/`)

### Setup

```bash
cd app
flutter pub get
```

### Run against a local server

The app defaults to the production domain. For local development pass the API
base URL with `--dart-define`:

```bash
# Android emulator (host machine is 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

# iOS simulator / desktop / web
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

### Screens

| Tab | Description |
| --- | --- |
| **Wardrobe** | Your catalogued items with category filters and favourites |
| **Stylist** | AI "Образ дня" — weather-aware outfit of the day |
| **Scan** | Camera + gallery capture → AI recognition → confirm & save |
| **Calendar** | Events with dress codes; AI plans an outfit per event |

Permissions required: camera, photo library, location (for weather).

---

## Project structure

```
WardrobeAi/
├── DESIGN.md              # Design system tokens & guidance
├── README.md
├── server/                # Node.js backend
│   ├── src/
│   │   ├── config/        # env + db
│   │   ├── models/        # User, ClothingItem, Outfit, Event
│   │   ├── middleware/    # auth, upload
│   │   ├── services/      # gemini, weather
│   │   ├── routes/        # auth, wardrobe, scan, stylist, calendar, subscription, admin
│   │   └── index.js
│   └── public/admin.html  # Admin panel
└── app/                   # Flutter app
    └── lib/
        ├── core/          # config, theme, models, api, providers, widgets
        └── features/      # auth, shell, wardrobe, scan, stylist, calendar, subscription, profile
```
