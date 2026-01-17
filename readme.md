# RepertoireTrainer (Flutter MVP)

## Running locally
1. Install Flutter (3.22+ recommended) and ensure `flutter doctor` is clean.
2. Run `flutter pub get` from the repo root.
3. Launch on iOS/Android:
   - iOS: `flutter run -d ios` (requires Xcode).
   - Android: `flutter run -d android` (requires Android Studio/emulator).

## PGN file placement
To add opening lines or GM games as PGN files:
1. Place `.pgn` files under `assets/pgn/` (e.g. `assets/pgn/ruy_lopez.pgn`).
2. Ensure `pubspec.yaml` lists the assets directory (already configured).
3. Run `flutter pub get` after adding new files.
4. In the app, open **Paste PGN** and use the **Load PGN from assets** dropdown to load the file into the editor and save it as a card.

You can still paste PGN text directly into the editor if you prefer.
