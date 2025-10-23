# Angaza (decoy: Notes)

**Angaza** is an MVP safety app with a decoy **Notes** launcher and a protected emergency UI.

## Quick start

cd mobile
flutter pub get
flutter run

## Key flows

Long-press inside Notes → opens Angaza • Emergency

Big SOS button → starts background job (record, location, outbox, SMS)

10s cancel sheet → "I'm safe" to abort

## Security

Local AES-256-GCM; keys in Android Keystore

No PII in logs; neutral launcher label/icon

## Tests

flutter test

## Build

flutter build apk --release


---

## Next items

1) **CryptoService** (Keystore + AES-GCM)  
2) **OutboxService** (encrypted Hive; exponential backoff)  
3) **RecordingService** (silent record, time-boxed)  
4) **LocationService** (GPS→Wi-Fi→Cell fallback)  
5) **SMS sending** to trusted contacts (device plan)  
6) **Android Quick Settings tile + Home widget** → call the same trigger  
7) **Supabase Free** schema + tiny dashboard later

Launcher decoy name remains “Notes”