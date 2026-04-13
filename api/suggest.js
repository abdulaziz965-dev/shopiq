const {
  isFirestoreConfigured,
  suggestFirestore,
} = require('./_firestore');

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

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const q = (req.query?.q || new URL(req.url, 'http://localhost').searchParams.get('q') || '').toString().trim();
  const rawLimit = Number(req.query?.limit || new URL(req.url, 'http://localhost').searchParams.get('limit') || 8);
  const limit = Math.min(Number.isFinite(rawLimit) ? rawLimit : 8, 12);

  if (!q) {
    res.status(200).json({ suggestions: SUGGESTION_SEED.slice(0, limit) });
    return;
  }

  if (isFirestoreConfigured()) {
    const firestoreSuggestions = await suggestFirestore(q, limit);
    if (firestoreSuggestions.length > 0) {
      res.status(200).json({ suggestions: firestoreSuggestions });
      return;
    }
  }

  const lower = q.toLowerCase();
  const suggestions = SUGGESTION_SEED
    .filter((item) => item.toLowerCase().includes(lower))
    .slice(0, limit);

  res.status(200).json({ suggestions });
};
