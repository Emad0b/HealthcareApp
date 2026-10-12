# HealthcareApp — Heart-Rate Monitoring Prototype

A Flutter application that reads an Android heart-rate sensor through a Kotlin platform channel, displays the latest reading, and writes readings to Firebase Firestore. An additional Express/SQL Server backend prototype is included.

## Features and implementation

- Flutter interface for the current heart-rate reading and threshold-triggered dialogs.
- Kotlin integration with Android `Sensor.TYPE_HEART_RATE` through the `com.example.heart_rate_app/heartRate` method channel.
- Periodic polling and Firestore storage under `Users/{userID}/HeartRateReadings`.
- An optional Express `POST /api/heartRate` endpoint for SQL Server persistence.

This is a development prototype. Its alert messages are not clinically validated diagnostic results.

## Flutter setup

The app is in `heart_rate_app/`. Use a Flutter installation compatible with the declared Dart SDK constraint `^3.5.3`.

```sh
cd heart_rate_app
flutter pub get
flutter run
```

Before running:

1. Configure Firebase for your own application and enable Firestore with appropriate access rules. Android configuration is stored in `android/app/google-services.json`.
2. Use an Android device with a heart-rate sensor, and configure the required sensor permissions for the target Android version. A regular emulator may not provide heart-rate readings.
3. Replace the placeholder user identity in `lib/main.dart` with the identity appropriate to your test setup.

Platform folders for other Flutter targets are present, but the sensor method-channel implementation provided here is Android-specific. Additional native implementations are needed for equivalent sensing on other targets.

## Optional Express backend

Install Node dependencies from the repository root:

```sh
npm ci
```

The server entry point is `heart_rate_app/server.js`. It requires a `heart_rate_app/dbConfig.js` module exporting `sql` and `getConnection`; that module is not included in the repository. Supply your SQL Server connection configuration and a `HeartRateReadings` table with the expected `UserID` and `HeartRateData` columns before starting it:

```sh
node heart_rate_app/server.js
```

The server uses port 3000 unless `PORT` is set. Flutter API helpers use `http://10.0.2.2:3000/api/heartRate`, the Android emulator's host-machine address; adapt this for a physical device.

The current screen writes directly to Firestore, and its SQL API call is commented out. The main-file and service-file API helpers use different user-ID/payload representations; align the selected client helper with the backend contract before enabling the SQL route.

## Source guide

- `heart_rate_app/lib/main.dart`: interface, polling, dialogs, and the active Firestore write path.
- `heart_rate_app/lib/services/`: separate API and Firestore helper functions.
- `heart_rate_app/android/app/src/main/kotlin/com/example/heart_rate_app/MainActivity.kt`: native sensor listener and platform channel.
- `heart_rate_app/server.js`: optional Express ingestion endpoint.
- `package.json`: Node dependencies.
- `heart_rate_app/pubspec.yaml`: Flutter dependencies and SDK constraint.

Use synthetic test identities and readings when evaluating the prototype. No working SQL Server configuration or production deployment is supplied.
