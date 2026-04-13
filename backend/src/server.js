import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../.env') });

const AMAZON_HOST = process.env.AMAZON_API_HOST || 'real-time-amazon-data.p.rapidapi.com';
const AMAZON_SEARCH_PATH = process.env.AMAZON_SEARCH_PATH || '/search';
const FLIPKART_HOST = process.env.FLIPKART_API_HOST || 'flipkart-product-scrapper.p.rapidapi.com';
const FLIPKART_SEARCH_PATH = process.env.FLIPKART_SEARCH_PATH || '/search';
const FLIPKART_ALT_SEARCH_PATH = (process.env.FLIPKART_ALT_SEARCH_PATH || '').trim();
const FLIPKART_CATEGORY_ID = process.env.FLIPKART_CATEGORY_ID || 'axc';
const FLIPKART_CATEGORY_PHONE = process.env.FLIPKART_CATEGORY_PHONE || 'tyy,4io';
const FLIPKART_CATEGORY_LAPTOP = process.env.FLIPKART_CATEGORY_LAPTOP || '6bo,b5g';
const FLIPKART_CATEGORY_AUDIO = process.env.FLIPKART_CATEGORY_AUDIO || '0pm,fcn';
const FLIPKART_CATEGORY_SHOES = process.env.FLIPKART_CATEGORY_SHOES || 'osp,cil';
const SUGGESTION_SEED = [
  'iPhone 15',
  'Samsung Galaxy S24',
  'OnePlus 12',
  'Nothing Phone',
  'MacBook Air M3',
  'Gaming Laptop',
  'Sony WH-1000XM5',
  'Boat Airdopes',
  'Bluetooth Speaker',
  'Smartwatch',
  'Running Shoes',
  'DSLR Camera',
  'Air Conditioner',
  'Refrigerator',
];

const app = express();
const port = Number(process.env.PORT || 8080);

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'shopiq-backend' });
});

app.get('/api/search', async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  if (!q) {
    return res.status(400).json({ error: 'Missing query parameter q' });
  }

  try {
    const [serpItems, amazonItems, flipkartItems] = await Promise.all([
      searchSerp(q).catch((e) => ({ items: [], error: `SerpAPI: ${e.message}` })),
      searchAmazon(q).catch((e) => ({ items: [], error: `Amazon RapidAPI: ${e.message}` })),
      searchFlipkart(q).catch((e) => ({ items: [], error: `Flipkart RapidAPI: ${e.message}` })),
    ]);

    const items = dedupeByTitle([
      ...serpItems.items,
      ...amazonItems.items,
      ...flipkartItems.items,
    ]);

    const errors = [serpItems.error, amazonItems.error, flipkartItems.error].filter(Boolean);

    if (items.length === 0) {
      return res.status(502).json({
        error: 'No live listings returned',
        providers: {
          serp: serpItems.error || 'ok',
          amazon: amazonItems.error || 'ok',
          flipkart: flipkartItems.error || 'ok',
        },
      });
    }

    return res.json({
      items,
      meta: {
        query: q,
        count: items.length,
        warnings: errors,
      },
    });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Unexpected backend failure' });
  }
});

app.get('/api/suggest', async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  const limit = Math.min(Number(req.query.limit || 8) || 8, 12);
  if (!q) {
    return res.json({ suggestions: SUGGESTION_SEED.slice(0, limit) });
  }

  try {
    const [serpItems, amazonItems, flipkartItems] = await Promise.all([
      searchSerp(q).catch(() => ({ items: [] })),
      searchAmazon(q).catch(() => ({ items: [] })),
      searchFlipkart(q).catch(() => ({ items: [] })),
    ]);

    const live = dedupeSuggestions([
      ...extractSuggestionTitles(serpItems.items, q),
      ...extractSuggestionTitles(amazonItems.items, q),
      ...extractSuggestionTitles(flipkartItems.items, q),
    ]);

    const merged = dedupeSuggestions([
      ...live,
      ...extractSeedSuggestions(q),
    ]).slice(0, limit);

    return res.json({ suggestions: merged });
  } catch {
    return res.json({ suggestions: extractSeedSuggestions(q).slice(0, limit) });
  }
});

app.listen(port, () => {
  console.log(`ShopIQ backend running on http://localhost:${port}`);
});

async function searchSerp(query) {
  const key = process.env.SERP_API_KEY || '';
  if (!key) throw new Error('Missing SERP_API_KEY');

  const url = new URL('https://serpapi.com/search.json');
  url.searchParams.set('engine', 'google_shopping');
  url.searchParams.set('q', query);
  url.searchParams.set('gl', 'in');
  url.searchParams.set('hl', 'en');
  url.searchParams.set('currency', 'INR');
  url.searchParams.set('api_key', key);

  const resp = await fetch(url, { method: 'GET' });
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

  const data = await resp.json();
  const raw = Array.isArray(data.shopping_results) ? data.shopping_results : [];

  const items = raw.slice(0, 20).map((item, i) => {
    const source = String(item.source || 'Online Store');
    const platform = normalizePlatform(source);
    const price = parsePrice(item.price);
    const originalPrice = price > 0 ? Number((price * 1.15).toFixed(2)) : 0;

    return {
      id: `serp_${item.position || i + 1}`,
      title: String(item.title || 'Product'),
      platform,
      price,
      originalPrice,
      rating: Number(item.rating || 4.0),
      reviews: Number(item.reviews || 0),
      delivery: 'Check site',
      deliveryDays: 3,
      discount: calcDiscount(price, originalPrice),
      affiliateUrl: ensureListingUrl(platform, query, item.link),
      imageUrl: item.thumbnail || null,
    };
  });

  return { items };
}

async function searchAmazon(query) {
  const key = process.env.RAPID_API_KEY || '';
  if (!key) throw new Error('Missing RAPID_API_KEY');

  const url = new URL(`https://${AMAZON_HOST}${AMAZON_SEARCH_PATH}`);
  url.searchParams.set('query', query);
  url.searchParams.set('page', '1');
  url.searchParams.set('country', 'IN');
  url.searchParams.set('sort_by', 'RELEVANCE');

  const resp = await fetch(url, {
    method: 'GET',
    headers: {
      'x-rapidapi-host': AMAZON_HOST,
      'x-rapidapi-key': key,
    },
  });

  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);

  const data = await resp.json();
  const raw = Array.isArray(data?.data?.products) ? data.data.products : [];

  const items = raw.slice(0, 12).map((item, i) => {
    const price = parsePrice(item.product_price);
    const originalPrice = parsePrice(item.product_original_price) || Number((price * 1.2).toFixed(2));
    const asin = String(item.asin || '').trim();

    return {
      id: `amz_${asin || i + 1}`,
      title: String(item.product_title || 'Amazon Product'),
      platform: 'Amazon',
      price,
      originalPrice,
      rating: Number(item.product_star_rating || 4.0),
      reviews: parseIntSafe(item.product_num_ratings),
      delivery: normalizeDelivery(item.delivery),
      deliveryDays: deliveryDays(item.delivery),
      discount: calcDiscount(price, originalPrice),
      affiliateUrl: asin ? `https://www.amazon.in/dp/${asin}` : ensureListingUrl('Amazon', query),
      imageUrl: item.product_photo || null,
    };
  });

  return { items };
}

async function searchFlipkart(query) {
  const key = process.env.RAPID_API_KEY || '';
  if (!key) throw new Error('Missing RAPID_API_KEY');

  const attempts = [{ host: FLIPKART_HOST, path: FLIPKART_SEARCH_PATH }];
  if (FLIPKART_ALT_SEARCH_PATH && FLIPKART_ALT_SEARCH_PATH !== FLIPKART_SEARCH_PATH) {
    attempts.push({ host: FLIPKART_HOST, path: FLIPKART_ALT_SEARCH_PATH });
  }

  let data = null;
  let lastError = '';

  for (const attempt of attempts) {
    const url = new URL(`https://${attempt.host}${attempt.path}`);
    if (isFlipkartCategoryEndpoint(attempt.path)) {
      url.searchParams.set('categoryID', resolveFlipkartCategoryId(query));
      url.searchParams.set('page', '1');
    } else {
      url.searchParams.set('q', query);
    }

    const resp = await fetch(url, {
      method: 'GET',
      headers: {
        'x-rapidapi-host': attempt.host,
        'x-rapidapi-key': key,
      },
    });

    if (resp.ok) {
      data = await resp.json();
      break;
    }

    let body = '';
    try {
      body = await resp.text();
    } catch {
      body = '';
    }
    lastError = `HTTP ${resp.status} @ ${attempt.host}${attempt.path}${body ? ` - ${body.slice(0, 180)}` : ''}`;
  }

  if (data == null) {
    if (lastError.includes('HTTP 429')) {
      return { items: [] };
    }
    throw new Error(lastError || 'Flipkart endpoint not reachable');
  }

  const raw = Array.isArray(data)
    ? data
    : Array.isArray(data?.products)
      ? data.products
      : Array.isArray(data?.data?.products)
        ? data.data.products
        : [];

  const items = raw.slice(0, 10).map((item, i) => {
    const price = parsePrice(item.price);
    const originalPrice = parsePrice(item.originalPrice ?? item.mrp) || Number((price * 1.2).toFixed(2));

    return {
      id: `fk_${item.id || i + 1}`,
      title: String(item.name || item.title || 'Flipkart Product'),
      platform: 'Flipkart',
      price,
      originalPrice,
      rating: Number(item.rating || 4.0),
      reviews: parseIntSafe(item.ratingCount ?? item.rating_count),
      delivery: '2-3 days',
      deliveryDays: 2,
      discount: calcDiscount(price, originalPrice),
      affiliateUrl: ensureListingUrl('Flipkart', query, item.url),
      imageUrl: item.image || item.imageUrl || item.thumbnail || null,
    };
  });

  return { items };
}

function isFlipkartCategoryEndpoint(path) {
  return String(path || '').toLowerCase().includes('category-products-list');
}

function resolveFlipkartCategoryId(query) {
  const q = String(query || '').toLowerCase();
  if (q.includes('iphone') || q.includes('phone') || q.includes('mobile') || q.includes('samsung') || q.includes('oneplus')) {
    return FLIPKART_CATEGORY_PHONE;
  }
  if (q.includes('laptop') || q.includes('macbook') || q.includes('notebook') || q.includes('dell') || q.includes('lenovo') || q.includes('asus')) {
    return FLIPKART_CATEGORY_LAPTOP;
  }
  if (q.includes('headphone') || q.includes('earphone') || q.includes('earbud') || q.includes('audio') || q.includes('speaker')) {
    return FLIPKART_CATEGORY_AUDIO;
  }
  if (q.includes('shoe') || q.includes('sneaker') || q.includes('footwear')) {
    return FLIPKART_CATEGORY_SHOES;
  }
  return FLIPKART_CATEGORY_ID;
}

function parsePrice(value) {
  if (value == null) return 0;
  const cleaned = String(value).replace(/[^0-9.]/g, '');
  const n = Number(cleaned);
  return Number.isFinite(n) ? n : 0;
}

function parseIntSafe(value) {
  if (value == null) return 0;
  const cleaned = String(value).replace(/[^0-9]/g, '');
  const n = Number.parseInt(cleaned, 10);
  return Number.isFinite(n) ? n : 0;
}

function calcDiscount(price, originalPrice) {
  if (!originalPrice || originalPrice <= 0 || price >= originalPrice) return 0;
  return Math.round(((originalPrice - price) / originalPrice) * 100);
}

function normalizePlatform(source) {
  const s = String(source || '').toLowerCase();
  if (s.includes('amazon')) return 'Amazon';
  if (s.includes('flipkart')) return 'Flipkart';
  if (s.includes('myntra')) return 'Myntra';
  if (s.includes('croma')) return 'Croma';
  return String(source || 'Online');
}

function ensureListingUrl(platform, query, rawUrl = '') {
  const url = String(rawUrl || '').trim();
  if (url) {
    if ((url.startsWith('http://') || url.startsWith('https://')) && !isRootDomain(url)) {
      return url;
    }
    if (url.startsWith('/') && String(platform).toLowerCase().includes('flipkart')) {
      return `https://www.flipkart.com${url}`;
    }
  }

  const q = encodeURIComponent(query);
  const p = String(platform).toLowerCase();
  if (p.includes('amazon')) return `https://www.amazon.in/s?k=${q}`;
  if (p.includes('flipkart')) return `https://www.flipkart.com/search?q=${q}`;
  if (p.includes('myntra')) return `https://www.myntra.com/${q}`;
  if (p.includes('croma')) return `https://www.croma.com/searchB?q=${q}%3Arelevance`;
  return `https://www.google.com/search?q=${q}`;
}

function isRootDomain(url) {
  try {
    const u = new URL(url);
    return !u.pathname || u.pathname === '/';
  } catch {
    return false;
  }
}

function normalizeDelivery(delivery) {
  const value = String(delivery || '').trim();
  if (!value) return '2-4 days';
  return value;
}

function deliveryDays(delivery) {
  const d = String(delivery || '').toLowerCase();
  if (d.includes('today')) return 0;
  if (d.includes('tomorrow')) return 1;
  if (d.includes('2')) return 2;
  return 3;
}

function dedupeByTitle(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    const key = String(item.title || '').toLowerCase().slice(0, 60);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}

function extractSuggestionTitles(items, query) {
  const q = String(query || '').toLowerCase();
  return (Array.isArray(items) ? items : [])
    .map((item) => normalizeSuggestion(item?.title))
    .filter(Boolean)
    .filter((title) => title.toLowerCase().includes(q))
    .slice(0, 6);
}

function extractSeedSuggestions(query) {
  const q = String(query || '').toLowerCase();
  return SUGGESTION_SEED
    .filter((item) => item.toLowerCase().includes(q))
    .slice(0, 8);
}

function dedupeSuggestions(items) {
  const out = [];
  const seen = new Set();
  for (const item of items) {
    const normalized = normalizeSuggestion(item);
    if (!normalized) continue;
    const key = normalized.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(normalized);
  }
  return out;
}

function normalizeSuggestion(value) {
  const text = String(value || '').replace(/\s+/g, ' ').trim();
  if (!text) return '';
  return text.length > 70 ? text.slice(0, 70).trim() : text;
}
