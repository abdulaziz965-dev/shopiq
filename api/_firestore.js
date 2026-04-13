const admin = require('firebase-admin');

let _initState = { initialized: false, available: false, db: null, reason: '' };

function _readServiceAccount() {
  const raw = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed && parsed.private_key) {
        parsed.private_key = String(parsed.private_key).replace(/\\n/g, '\n');
      }
      return parsed;
    } catch {
      return null;
    }
  }

  const projectId = (process.env.FIREBASE_PROJECT_ID || '').trim();
  const clientEmail = (process.env.FIREBASE_CLIENT_EMAIL || '').trim();
  const privateKeyRaw = (process.env.FIREBASE_PRIVATE_KEY || '').trim();
  if (!projectId || !clientEmail || !privateKeyRaw) return null;

  return {
    project_id: projectId,
    client_email: clientEmail,
    private_key: privateKeyRaw.replace(/\\n/g, '\n'),
  };
}

function _ensureFirestore() {
  if (_initState.initialized) return _initState;

  _initState.initialized = true;
  const serviceAccount = _readServiceAccount();
  if (!serviceAccount) {
    _initState.reason = 'missing-service-account';
    return _initState;
  }

  try {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    _initState.db = admin.firestore();
    _initState.available = true;
    return _initState;
  } catch (e) {
    _initState.available = false;
    _initState.reason = e?.message || 'firebase-init-failed';
    return _initState;
  }
}

function isFirestoreConfigured() {
  return _ensureFirestore().available;
}

function normalizeForSearch(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function queryTokens(query) {
  return normalizeForSearch(query).split(' ').filter(Boolean);
}

function scoreMatch(tokens, haystack) {
  if (!tokens.length || !haystack) return 0;
  let score = 0;
  for (const t of tokens) {
    if (haystack === t) score += 20;
    else if (haystack.startsWith(t)) score += 14;
    else if (haystack.includes(` ${t}`)) score += 10;
    else if (haystack.includes(t)) score += 6;
  }
  return score;
}

function mapDocToItem(doc) {
  const d = doc.data() || {};
  const title = String(d.title || d.name || 'Product');
  const platform = String(d.platform || d.store || 'Online');
  const price = Number(d.price || 0) || 0;
  const originalPrice = Number(d.originalPrice || d.mrp || d.listPrice || 0) || 0;
  const delivery = String(d.delivery || d.deliveryText || '2-4 days');

  return {
    id: String(d.id || doc.id),
    title,
    platform,
    price,
    originalPrice,
    rating: Number(d.rating || 0) || 0,
    reviews: Number(d.reviews || d.reviewCount || 0) || 0,
    delivery,
    deliveryDays: Number(d.deliveryDays || 3) || 3,
    discount: Number(d.discount || d.discountPercent || 0) || 0,
    affiliateUrl: String(d.affiliateUrl || d.url || d.link || ''),
    imageUrl: d.imageUrl || d.image || d.thumbnail || null,
    _searchText: normalizeForSearch(`${title} ${platform} ${d.brand || ''} ${d.category || ''} ${d.keywords || ''}`),
  };
}

async function searchFirestoreProducts(query, limit = 40) {
  const state = _ensureFirestore();
  if (!state.available) return [];

  const tokens = queryTokens(query);
  if (!tokens.length) return [];

  const first = tokens[0];
  const productsRef = state.db.collection('products');

  const [tokenSnap, prefixSnap] = await Promise.all([
    productsRef.where('searchTokens', 'array-contains', first).limit(limit).get().catch(() => null),
    productsRef
      .where('normalizedTitle', '>=', first)
      .where('normalizedTitle', '<=', `${first}\uf8ff`)
      .limit(limit)
      .get()
      .catch(() => null),
  ]);

  const seen = new Set();
  const merged = [];
  for (const snap of [tokenSnap, prefixSnap]) {
    if (!snap || snap.empty) continue;
    for (const doc of snap.docs) {
      if (seen.has(doc.id)) continue;
      seen.add(doc.id);
      merged.push(mapDocToItem(doc));
    }
  }

  merged.sort((a, b) => {
    const byScore = scoreMatch(tokens, b._searchText) - scoreMatch(tokens, a._searchText);
    if (byScore !== 0) return byScore;
    return (b.rating || 0) - (a.rating || 0);
  });

  return merged
    .filter((item) => scoreMatch(tokens, item._searchText) > 0)
    .slice(0, limit)
    .map(({ _searchText, ...rest }) => rest);
}

async function suggestFirestore(query, limit = 8) {
  const state = _ensureFirestore();
  if (!state.available) return [];

  const q = normalizeForSearch(query);
  if (!q) return [];

  const suggestionsRef = state.db.collection('searchSuggestions');
  const productsRef = state.db.collection('products');

  const [suggestSnap, productsSnap] = await Promise.all([
    suggestionsRef
      .where('normalized', '>=', q)
      .where('normalized', '<=', `${q}\uf8ff`)
      .limit(limit)
      .get()
      .catch(() => null),
    productsRef.where('searchTokens', 'array-contains', q.split(' ')[0]).limit(limit * 2).get().catch(() => null),
  ]);

  const out = [];
  const seen = new Set();

  const add = (value) => {
    const text = String(value || '').trim();
    if (!text) return;
    const key = text.toLowerCase();
    if (seen.has(key)) return;
    seen.add(key);
    out.push(text);
  };

  if (suggestSnap && !suggestSnap.empty) {
    for (const doc of suggestSnap.docs) {
      const d = doc.data() || {};
      add(d.text || d.label || d.value || doc.id);
      if (out.length >= limit) break;
    }
  }

  if (productsSnap && !productsSnap.empty && out.length < limit) {
    for (const doc of productsSnap.docs) {
      const d = doc.data() || {};
      const title = String(d.title || d.name || '').trim();
      if (normalizeForSearch(title).includes(q)) add(title);
      if (out.length >= limit) break;
    }
  }

  return out.slice(0, limit);
}

module.exports = {
  isFirestoreConfigured,
  searchFirestoreProducts,
  suggestFirestore,
};
