# Vipra Setu Flutter App

Mobile-first Flutter frontend for the local `server` backend.

## Backend

Start the backend from the repo `server` folder. Default API port is `5000`.

For Android emulator run with:

```text
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For a physical Android phone, pass your computer LAN IP:

```text
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
```

Production builds default to `https://vipra-setu.onrender.com/api`. Override it
with `--dart-define=API_BASE_URL=...` for another deployment.

## Roles

- Service taker: search services, find providers, call/WhatsApp, create requests.
- Service provider: admin-created login, profile, availability, leads, services, quotes.
- Admin: dashboard, users, providers, services, requests, ads, moderation.

## Working Feature Set

- Phone/password login and service taker registration.
- Role-based mobile navigation for service taker, service provider, and admin.
- Admin-created provider account login flow.
- Password change for all logged-in roles.
- Local service categories with backend fallback data.
- Provider search by service/category/city.
- Call and WhatsApp launch from provider cards.
- Dedicated contact log tracking API for every call/WhatsApp tap.
- Admin contact log screen for who contacted whom, when, and for which service.
- Provider incoming contact lead screen.
- Service taker request creation.
- Provider service creation and moderation-ready status.
- Admin provider creation.
- Admin ad creation and listing.
- Provider manual location update endpoint for nearby-provider search.
- Traditional modern mobile UI with community-first colors and compact cards.

## Google Maps

The Tracking screen is included and provider location update API is wired. Automatic live GPS still needs native location permission setup and a GPS package such as `geolocator`. Add your Google Maps API key in Android/iOS native configuration before rendering a real map.
