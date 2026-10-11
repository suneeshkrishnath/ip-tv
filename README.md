# Nerampokku

Flutter IPTV app: load an M3U playlist, browse channels, save favorites, and play live streams in the app (Android/iOS).

## Playlist sources

- Malayalam: https://iptv-org.github.io/iptv/languages/mal.m3u
- All channels: https://iptv-org.github.io/iptv/index.m3u

## Run in development

```powershell
cd c:\_D\work_dir\Mobile\IP-TV
flutter pub get
flutter devices
flutter run -d <device-id>
```

Press `R` for hot restart and `q` to quit. Android emulators with very new system images may play audio but show no video (EGL error); use a physical phone or set the AVD graphics to Software.

## Build an Android APK

```powershell
cd c:\_D\work_dir\Mobile\IP-TV
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

Output is in `build\app\outputs\flutter-apk\`:

- `app-arm64-v8a-release.apk`: most modern phones.
- `app-armeabi-v7a-release.apk`: older 32-bit phones.
- `app-x86_64-release.apk`: emulators only.

For one APK that works on any phone, run `flutter build apk --release` and use `app-release.apk`.

The release build is signed with the debug key, so it is for personal testing only, not Play Store publishing.

## Install on a phone

USB:

1. Enable Developer options (tap Build number 7 times in Settings > About phone) and turn on USB debugging.
2. Connect the phone and accept the debugging prompt.
3. Confirm it is listed with `flutter devices`.
4. Install:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
   ```
   or `flutter install -d <device-id>`.

Manual:

1. Copy the APK to the phone (USB, Drive, or email).
2. Open it in the Files app, allow "Install unknown apps" when prompted, and tap Install.

## Test

1. Open the app, choose a playlist, tap the download icon, and tap a channel.
2. Check video and audio, fullscreen, rotation, and favorites persisting after a full restart.
3. Many public streams are dead or geo-blocked; try several channels before assuming a bug.

## Checks

```powershell
flutter analyze
flutter test
```