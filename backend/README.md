# Veriadd KYC backend

This backend uses the Veriadd SDK server-side and keeps the `VERIADD_KEY` in the environment.

## Run

```bash
cd backend
export VERIADD_KEY=vr_test_your_key_here
export PORT=8080
dart pub get
dart run server.dart
```

## Endpoint

`POST /kyc/verify-address`

Example request:

```bash
curl -X POST http://localhost:8080/kyc/verify-address \
  -H 'Content-Type: application/json' \
  -d '{
    "postcode": "LA-11-W06-TC-10",
    "state": "LAGOS",
    "bvn": "22233344455",
    "phone": "08031234567",
    "level": 3
  }'
```

The app should never send a Veriadd key from the Flutter client.
