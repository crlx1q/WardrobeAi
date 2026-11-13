const { GoogleGenerativeAI } = require('@google/generative-ai');
const env = require('../config/env');

let client = null;
function getModel() {
  if (!env.GEMINI_API_KEY) return null;
  if (!client) client = new GoogleGenerativeAI(env.GEMINI_API_KEY);
  return client.getGenerativeModel({ model: env.GEMINI_MODEL });
}

function extractJson(text) {
  if (!text) return null;
  // strip code fences and locate the first {...} or [...] block
  const cleaned = text.replace(/```json/gi, '```').replace(/```/g, '').trim();
  const match = cleaned.match(/[[{][\s\S]*[\]}]/);
  const candidate = match ? match[0] : cleaned;
  try {
    return JSON.parse(candidate);
  } catch {
    return null;
  }
}

const CATEGORY_VALUES = ['top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other'];

/**
 * Recognize a garment from an image buffer using Gemini vision.
 * Returns { name, type, category, color, material, tags[] } in Russian.
 */
async function recognizeGarment(imageBuffer, mimeType = 'image/jpeg') {
  const model = getModel();
  if (!model) {
    return {
      name: 'Новая вещь',
      type: 'Вещь',
      category: 'other',
      color: 'Нейтральный',
      material: 'Не определён',
      tags: [],
      _mock: true,
    };
  }

  const prompt = `Ты — стилист-каталогизатор гардероба. Проанализируй одежду на фото.
Ответь СТРОГО в формате JSON без пояснений и без markdown:
{
  "name": "короткое название вещи на русском (например: Шёлковая блуза)",
  "type": "тип вещи на русском (например: Блуза, Жакет, Брюки)",
  "category": "одно из: top, bottom, dress, outerwear, shoes, accessory, other",
  "color": "основной цвет на русском (например: Айвори, Бежевый, Графитовый)",
  "material": "материал на русском (например: Шёлк, Твид, Кашемир)",
  "tags": ["2-4 коротких тега-стиля на русском, например: минимализм, деловой"]
}
category правила: top=верх(рубашки/блузы/футболки), bottom=низ(брюки/юбки/шорты), dress=платья, outerwear=верхняя одежда(пальто/куртки/жакеты), shoes=обувь, accessory=аксессуары/сумки.`;

  try {
    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { data: imageBuffer.toString('base64'), mimeType } },
    ]);
    const parsed = extractJson(result.response.text());
    if (!parsed) throw new Error('parse failed');

    const category = CATEGORY_VALUES.includes(parsed.category) ? parsed.category : 'other';
    return {
      name: String(parsed.name || 'Новая вещь').slice(0, 80),
      type: String(parsed.type || 'Вещь').slice(0, 60),
      category,
      color: String(parsed.color || 'Нейтральный').slice(0, 40),
      material: String(parsed.material || 'Не определён').slice(0, 40),
      tags: Array.isArray(parsed.tags) ? parsed.tags.slice(0, 5).map((t) => String(t).slice(0, 30)) : [],
    };
  } catch (err) {
    console.warn('[gemini] recognizeGarment error:', err.message);
    return {
      name: 'Новая вещь',
      type: 'Вещь',
      category: 'other',
      color: 'Нейтральный',
      material: 'Не определён',
      tags: [],
      _error: true,
    };
  }
}

/**
 * Compose an outfit from wardrobe items given weather + optional event context.
 * items: [{ id, name, type, category, color, material, tags, wearCount, lastWornAt }]
 * Returns { itemIds[], title, rationale, tags[] }.
 */
async function composeOutfit({ items, weather, event, avoidItemIds = [] }) {
  const usable = items.filter((i) => !avoidItemIds.includes(String(i.id)));
  const pool = usable.length ? usable : items;

  const model = getModel();
  if (!model || pool.length === 0) {
    return fallbackOutfit(pool, weather, event);
  }

  const catalog = pool.map((i) => ({
    id: String(i.id),
    name: i.name,
    type: i.type,
    category: i.category,
    color: i.color,
    material: i.material,
    tags: i.tags,
    wearCount: i.wearCount || 0,
  }));

  const contextLines = [];
  if (weather && weather.available) {
    contextLines.push(`Погода сегодня: ${weather.summary} (ощущается как ${weather.feelsLikeC}°C).`);
  }
  if (event) {
    contextLines.push(`Событие: ${event.title}. Дресс-код: ${event.dressCode || 'не указан'}.`);
  }
  contextLines.push('Отдавай предпочтение вещам, которые давно не носили (меньший wearCount).');

  const prompt = `Ты — персональный AI-стилист бренда Capsule. Собери один цельный, стильный образ из гардероба пользователя.
${contextLines.join('\n')}

Гардероб (JSON):
${JSON.stringify(catalog)}

Правила:
- Используй ТОЛЬКО id вещей из гардероба.
- Собери гармоничный комплект: как правило верх+низ или платье, плюс при уместности верхняя одежда, обувь и аксессуар.
- Учитывай погоду и событие/дресс-код.
Ответь СТРОГО в формате JSON без markdown:
{
  "itemIds": ["id1", "id2"],
  "title": "короткое название образа на русском",
  "rationale": "1-2 предложения почему этот образ подходит (погода/повод), на русском",
  "tags": ["2-3 тега стиля на русском"]
}`;

  try {
    const result = await model.generateContent([{ text: prompt }]);
    const parsed = extractJson(result.response.text());
    if (!parsed || !Array.isArray(parsed.itemIds)) throw new Error('parse failed');

    const validIds = new Set(pool.map((i) => String(i.id)));
    const itemIds = parsed.itemIds.map(String).filter((id) => validIds.has(id));
    if (itemIds.length === 0) throw new Error('no valid ids');

    return {
      itemIds,
      title: String(parsed.title || 'Образ дня').slice(0, 80),
      rationale: String(parsed.rationale || '').slice(0, 400),
      tags: Array.isArray(parsed.tags) ? parsed.tags.slice(0, 4).map((t) => String(t)) : [],
    };
  } catch (err) {
    console.warn('[gemini] composeOutfit error:', err.message);
    return fallbackOutfit(pool, weather, event);
  }
}

// Heuristic outfit builder used when Gemini is unavailable or fails.
function fallbackOutfit(items, weather, event) {
  const byCat = (c) =>
    items
      .filter((i) => i.category === c)
      .sort((a, b) => (a.wearCount || 0) - (b.wearCount || 0));

  const picked = [];
  const dress = byCat('dress')[0];
  if (dress) {
    picked.push(dress);
  } else {
    if (byCat('top')[0]) picked.push(byCat('top')[0]);
    if (byCat('bottom')[0]) picked.push(byCat('bottom')[0]);
  }
  const cold = weather && weather.tempC != null && weather.tempC < 15;
  if (cold && byCat('outerwear')[0]) picked.push(byCat('outerwear')[0]);
  if (byCat('shoes')[0]) picked.push(byCat('shoes')[0]);
  if (byCat('accessory')[0]) picked.push(byCat('accessory')[0]);

  const final = picked.length ? picked : items.slice(0, 3);
  const weatherNote = weather && weather.available ? `Учли погоду: ${weather.summary}. ` : '';
  const eventNote = event ? `Подобрано под событие «${event.title}». ` : '';

  return {
    itemIds: final.map((i) => String(i.id)),
    title: event ? `Образ для «${event.title}»` : 'Образ дня',
    rationale: `${weatherNote}${eventNote}Сбалансированный комплект из вещей вашего гардероба.`.trim(),
    tags: cold ? ['уютно', 'многослойность'] : ['лёгкий', 'повседневный'],
  };
}

module.exports = { recognizeGarment, composeOutfit };
