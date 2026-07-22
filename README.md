# Vipra Sewa Setu

Flutter frontend plus Express/MongoDB backend for customers, service providers,
and admins.

## Local Development

```bash
npm install
npm run dev
```

The root dev script starts the backend and runs the Flutter app in Chrome with:

```text
API_BASE_URL=http://localhost:5000/api
```

## Production Checklist

- Set `NODE_ENV=production`, `MONGO_URI`, and a long random `JWT_SECRET`.
- Keep `SEED_ADMIN_ON_START=false` in production.
- Create or update the first admin with `cd server && npm run seed` after setting
  `ADMIN_PHONE` and a strong `ADMIN_PASSWORD`.
- Build Flutter with the production API URL:
  `flutter build web --dart-define=API_BASE_URL=https://your-api-domain/api`
- Configure Android signing properties before publishing:
  `VIPRA_UPLOAD_STORE_FILE`, `VIPRA_UPLOAD_STORE_PASSWORD`,
  `VIPRA_UPLOAD_KEY_ALIAS`, and `VIPRA_UPLOAD_KEY_PASSWORD`.
# vipra-setu-
