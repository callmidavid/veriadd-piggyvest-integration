# Veriadd PiggyVest integration

This repository contains a copied PiggyVest Flutter app plus a secure Veriadd KYC flow.

## Requirements

- Flutter SDK
- Dart SDK ^3.7.2
- A Veriadd API key with `vr_live_...` or `vr_test_...` format
- A running backend with `VERIADD_KEY` in the environment

## Install frontend dependencies

```bash
cd frontend
flutter pub get
```

## Run backend

```bash
cd backend
export VERIADD_KEY=vr_test_your_key_here
export PORT=8080
dart pub get
dart run server.dart
```

## Run frontend app

```bash
cd frontend
flutter run
```

## Configure backend URL

The Flutter app defaults to `http://localhost:8080`.

You can override it at build time:

```bash
cd frontend
flutter run --dart-define=VERIADD_BACKEND_URL=http://localhost:8080
```

## Test flow

1. Start the backend.
2. Launch the Flutter app.
3. Navigate to the dashboard quick action `Address KYC`.
4. Submit a valid postcode/state/BVN/phone combination.
5. The backend calls `VeriaddClient.verifyAddress(...)` and returns the result.

The app never sends a private Veriadd key from mobile code.

## Notes

- Real verification requires a valid Veriadd key and internet access.
- The backend is the only place where the secret key should live.
