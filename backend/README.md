# ShopIQ Backend

Minimal Express backend for live listings used by the Flutter app.

## 1) Install

```bash
cd backend
npm install
```

## 2) Configure

```bash
cp .env.example .env
```

Set values in `.env`:

- `PORT` (default `8080`)
- `SERP_API_KEY`
- `RAPID_API_KEY`
- Optional endpoint overrides (if your RapidAPI subscription uses a different host/path):
  - `AMAZON_API_HOST`
  - `AMAZON_SEARCH_PATH`
  - `FLIPKART_API_HOST`
  - `FLIPKART_SEARCH_PATH`
  - `FLIPKART_ALT_SEARCH_PATH`
  - `FLIPKART_CATEGORY_ID` (fallback category for category-list APIs)

Example for `flipkart-apis.p.rapidapi.com`:

```env
FLIPKART_API_HOST=flipkart-apis.p.rapidapi.com
FLIPKART_SEARCH_PATH=/backend/rapidapi/category-products-list
FLIPKART_CATEGORY_ID=axc
FLIPKART_CATEGORY_PHONE=tyy,4io
FLIPKART_CATEGORY_LAPTOP=6bo,b5g
FLIPKART_CATEGORY_AUDIO=0pm,fcn
FLIPKART_CATEGORY_SHOES=osp,cil
```

## 3) Run

```bash
npm --prefix backend run dev
```

Health check:

- `http://localhost:8080/health`

Search endpoint:

- `GET http://localhost:8080/api/search?q=iphone`

## 4) Connect Flutter app

Add to `dart_define.json` in project root:

```json
{
  "BACKEND_BASE_URL": "http://localhost:8080"
}
```

Run app:

```bash
flutter run --dart-define-from-file=dart_define.json
```
