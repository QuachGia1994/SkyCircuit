# SkyCircuit

Original mobile circuit puzzle inspired by the rotate-and-connect fireworks gameplay pattern of early 2000s puzzle games. SkyCircuit does not include PopCap code, branding, art, audio, or level data. Completed circuits visibly ignite from spark to rocket before launch; the prototype also includes tutorial, skins, Classic/Zen/Blitz modes, and a non-transactional Plus roadmap preview.

## Local checks

```bash
npm test
npm run build
```

`npm run build` creates `dist/` using only Node.js file APIs, so gameplay itself has no game-engine or bundler dependency.

## Native packaging

Capacitor is used only as the Android/iOS container. Install dependencies, build the web payload, then add/sync the native platform:

```bash
npm install
npm run build
npx cap add android
npx capacitor-assets generate --android
npx cap sync android
```

For iOS, use the same flow with `ios` and `npx capacitor-assets generate --ios`; Xcode/macOS is required for the native build. The original `assets/icon.svg` is the source for generated native icons. GitHub Actions workflows are included for an Android debug APK and an unsigned iOS Simulator app. A device-installable IPA additionally requires Apple signing credentials and provisioning.

## Native V2 experiment

`native/` contains additive native sidecars; the Capacitor app remains the shipping fallback until parity and CI are proven.

- iOS: SwiftUI + SpriteKit/SpriteView, `@Observable` GameEngine, CoreHaptics placement-quality feedback, AVAudioEngine procedural tones, ActivityKit Daily Run Live Activity + WidgetKit mini rank, and StoreKit 2 Plus shell.
- Android: Jetpack Compose shell + SurfaceView native Canvas renderer, primitive-aware `VibrationEffect`, procedural AudioTrack, Daily Run promoted ongoing notification, Glance widget, and Play Billing boundary.
- Both follow `native/spec/game-contract.md`: 120 Hz target frame budget under 8.3 ms where supported, graceful 60 Hz fallback, and a procedural/vector payload target under 25 MB.

Xcode 27/Swift 6.4 and Android API 37/AGP 9.3 workflows are experimental and do not replace the stable Capacitor workflows.
