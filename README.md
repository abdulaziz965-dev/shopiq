# ShopIQ 🛍️

**AI-powered product comparison & smart shopping assistant**

Search any product by text or photo. ShopIQ fetches real listings from Amazon, Flipkart, Myntra and more, ranks them with AI, and shows you the best deal — instantly.

---

## ✨ Features

| Feature | Status |
|---|---|
| 🔍 Universal text search | ✅ Live (SerpAPI + Amazon + Flipkart APIs) |
| 📷 Camera / image search | ✅ Claude Vision identifies product → searches |
| 🤖 AI ranking & summary | ✅ Claude generates recommendations |
| ⚖️ Side-by-side comparison | ✅ Price, rating, delivery, score |
| 📈 Price history chart | ✅ 6-month trend graph |
| ❤️ Wishlist | ✅ Saved locally with SharedPreferences |
| 💬 AI chat assistant | ✅ Claude-powered shopping chat |
| 🔔 Price drop alerts | ✅ UI implemented (push notifications: add Firebase) |
| 🛡️ Fake review detection | ✅ Heuristic + badge system |
| 🌙 Dark mode | ✅ Full dark theme |

---

## 🚀 Quick Start

### 1. Prerequisites

```bash
flutter --version   # needs Flutter 3.16+ / Dart 3.0+
```

### 2. Clone & install

```bash
git clone <your-repo>
cd shopiq
flutter pub get
```

### 3. Configure local runtime keys

Use runtime defines (do not hardcode keys in Dart files):

1. Copy example file and fill your values:

```bash
cp dart_define.example.json dart_define.json
```

2. Add keys in `dart_define.json`:
- `ANTHROPIC_API_KEY`
- `SERP_API_KEY`
- `RAPID_API_KEY`
- `BACKEND_BASE_URL` (for local backend, use `http://localhost:8080`)

> **No keys?** Live search will show a setup error state until keys are configured.

### 4. Start backend (recommended)

```bash
npm run backend:dev
```

### 5. Run app

```bash
flutter run --dart-define-from-file=dart_define.json
```

Or use:

```bash
npm run app:run
```

---

## 🚀 Production Deployment

For Vercel, the cleanest setup is to deploy through GitHub Actions so Flutter runs on the GitHub runner, not inside Vercel's build image.

### Recommended Vercel flow

Use the workflow in [.github/workflows/deploy-vercel.yml](.github/workflows/deploy-vercel.yml).

Add these GitHub repository secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

Set these Vercel environment variables:

- `SERP_API_KEY`
- `RAPID_API_KEY`
- Firestore (recommended primary backend source):
        - `FIREBASE_SERVICE_ACCOUNT_JSON` (full JSON from Firebase service account, minified string)
        - or split variables: `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`

How it works:

1. GitHub Actions installs Flutter.
2. It runs `flutter build web --release`.
3. It asks Vercel to build the project from the prebuilt web output.
4. Vercel serves the app and the `api/` routes.

Notes:

- Do not use `localhost` in production.
- The web app will use the same origin as the deployed Vercel app to reach `/api/search`.
- The local `backend/` folder is still useful for local development.
- AI/chat/image features still depend on their own runtime setup.
- If Firestore is configured, `/api/search` and `/api/suggest` read Firestore first and use live providers only as fallback.

### Firestore Collections

Use these collections for best results:

- `products`
        - `title` (string)
        - `platform` (string)
        - `price` (number)
        - `originalPrice` (number)
        - `rating` (number)
        - `reviews` (number)
        - `delivery` (string)
        - `deliveryDays` (number)
        - `discount` (number)
        - `affiliateUrl` (string)
        - `imageUrl` (string)
        - `normalizedTitle` (string, lowercase)
        - `searchTokens` (array of strings)

- `searchSuggestions`
        - `text` (string)
        - `normalized` (string, lowercase)

---

## 📡 APIs Used

### Search APIs (real product listings)

| API | Purpose | Free Tier | Sign Up |
|---|---|---|---|
| **SerpAPI** | Google Shopping (India) | 100 searches/month | https://serpapi.com |
| **RapidAPI – Real-Time Amazon Data** | Amazon India listings | 500 req/month | https://rapidapi.com/search/real-time-amazon |
| **RapidAPI – Flipkart Scrapper** | Flipkart listings | 500 req/month | https://rapidapi.com/search/flipkart |

### AI APIs

| API | Purpose |
|---|---|
| **Anthropic Claude** (claude-sonnet-4) | Shopping summaries, chat, image product identification |

### RapidAPI Setup (step by step)

1. Go to https://rapidapi.com and create a free account
2. Search **"Real-Time Amazon Data"** → Subscribe to Basic (free)
3. Search **"Flipkart Product Scrapper"** → Subscribe to Basic (free)
4. Your RapidAPI key is shown in the dashboard → paste into `real_search_service.dart`

> You no longer need to edit service files manually. Put the key in `dart_define.json`.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry, theme, providers
├── models/
│   └── product.dart             # Product model + scoring algorithm
├── services/
│   ├── search_service.dart      # Search state manager (text + image)
│   ├── real_search_service.dart # Live API calls (SerpAPI, Amazon, Flipkart)
│   ├── image_search_service.dart# Claude Vision product identification
│   ├── ai_service.dart          # Claude AI summaries + chat
│   ├── wishlist_service.dart    # Wishlist with local persistence
│   └── mock_data_service.dart   # Fallback demo data + price history
├── screens/
│   ├── main_shell.dart          # Bottom nav shell
│   ├── home_screen.dart         # Home: trending, deals, price drops
│   ├── search_screen.dart       # Search: text + camera + results
│   ├── wishlist_screen.dart     # Saved products
│   ├── chat_screen.dart         # AI shopping assistant chat
│   └── profile_screen.dart      # User profile + settings
├── widgets/
│   ├── product_card.dart        # Product listing card with score bar
│   ├── ai_summary_card.dart     # AI recommendation banner
│   ├── compare_sheet.dart       # Side-by-side comparison modal
│   ├── deal_card.dart           # Home screen deal card
│   ├── price_history_chart.dart # fl_chart price trend
│   └── section_header.dart      # Reusable section header
└── utils/
    └── app_colors.dart          # Design system: colors + text styles
```

---

## 🧠 Ranking Algorithm

```
Score = (Rating × 20) + (Discount% × 0.8) + DeliverySpeedScore

DeliverySpeedScore = (5 - deliveryDays).clamp(0, 5) × 10

Max possible score = (5 × 20) + (50 × 0.8) + 50 = 190
```

Badges are assigned per-search:
- 🏆 **Best Value** — highest overall score
- 💚 **Cheapest** — lowest price
- ⭐ **Top Rated** — highest rating
- ⚡ **Fastest** — fewest delivery days

---

## 📷 Image Search Flow

```
User takes photo / picks from gallery
        ↓
Claude Vision (claude-sonnet-4)
  • Identifies: product name, brand, model, category
  • Returns: optimized search query for Indian e-commerce
        ↓
RealSearchService.searchGoogleShopping(query)
RealSearchService.searchAmazon(query)           } parallel
RealSearchService.searchFlipkart(query)         }
        ↓
Deduplicate → assignBadges → sort by score
        ↓
Results shown with "Identified: [product]" banner
```

---

## 🔔 Adding Push Notifications (Firebase)

1. Create Firebase project at https://console.firebase.google.com
2. Add Android/iOS apps
3. Download `google-services.json` → `android/app/`
4. Download `GoogleService-Info.plist` → `ios/Runner/`
5. Add to `pubspec.yaml`:
   ```yaml
   firebase_core: ^2.27.0
   firebase_messaging: ^14.7.19
   ```
6. In `main.dart`, initialize Firebase and request notification permissions

---

## 🏗️ Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires Mac + Xcode)
flutter build ios --release
```

---

## 💰 Monetization

Each product card's "Buy on [Platform]" button uses the `affiliateUrl` field.
To earn affiliate commission:
- **Amazon Associates India**: https://affiliate-program.amazon.in
- **Flipkart Affiliate**: https://affiliate.flipkart.com
- Replace `affiliateUrl` values with your tagged affiliate links

---

## 🐛 Troubleshooting

| Issue | Fix |
|---|---|
| `MissingPluginException` for image_picker | Run `flutter clean && flutter pub get` |
| Camera not working on iOS simulator | Use physical device for camera; gallery works on simulator |
| API returns 401 | Check API key is correct and not expired |
| API returns 429 | Rate limit hit — add delays or upgrade plan |
| `FormatException` parsing prices | Some APIs return prices in unexpected formats — `_parsePrice` handles most cases |
