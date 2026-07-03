# Web Release Preparation

## Generate platform files if missing

```bash
flutter create . --platforms=web
```

## Build web

```bash
flutter build web --release
```

## Optional API base URL

```bash
flutter build web --release \
  --dart-define=CAREER_CHAOS_API_BASE_URL=https://api.example.com
```

## Web release checks

- Confirm splash/icon generation has run.
- Confirm browser title shows Career Chaos Academy.
- Confirm local fallback works if API is unavailable.
- Confirm privacy policy and terms URLs are accessible from the hosting site.
