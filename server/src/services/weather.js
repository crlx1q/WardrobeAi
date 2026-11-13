const fetch = require('node-fetch');

const WMO = {
  0: 'ясно',
  1: 'преимущественно ясно',
  2: 'переменная облачность',
  3: 'пасмурно',
  45: 'туман',
  48: 'изморозь',
  51: 'морось',
  53: 'морось',
  55: 'сильная морось',
  61: 'небольшой дождь',
  63: 'дождь',
  65: 'сильный дождь',
  71: 'небольшой снег',
  73: 'снег',
  75: 'сильный снег',
  80: 'ливень',
  81: 'ливень',
  82: 'сильный ливень',
  95: 'гроза',
  96: 'гроза с градом',
  99: 'сильная гроза',
};

// Uses the free Open-Meteo API (no key required).
async function getWeather(lat, lon) {
  if (lat == null || lon == null) {
    return { available: false, summary: 'погода недоступна', tempC: null, condition: '' };
  }
  try {
    const url =
      `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
      `&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m` +
      `&timezone=auto`;
    const res = await fetch(url, { timeout: 8000 });
    if (!res.ok) throw new Error(`open-meteo ${res.status}`);
    const data = await res.json();
    const cur = data.current || {};
    const condition = WMO[cur.weather_code] || 'неизвестно';
    const tempC = Math.round(cur.temperature_2m);
    return {
      available: true,
      tempC,
      feelsLikeC: Math.round(cur.apparent_temperature),
      windKph: Math.round((cur.wind_speed_10m || 0)),
      condition,
      summary: `${tempC}°C, ${condition}`,
    };
  } catch (err) {
    console.warn('[weather] error:', err.message);
    return { available: false, summary: 'погода недоступна', tempC: null, condition: '' };
  }
}

module.exports = { getWeather };
