# SkyCircuit

Original mobile circuit puzzle inspired by the rotate-and-connect fireworks gameplay pattern of early 2000s puzzle games. SkyCircuit does not include PopCap code, branding, art, audio, or level data.

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
npx cap sync android
```

For iOS, use the same flow with `ios`; Xcode/macOS is required for the native build. GitHub Actions workflows are included for an Android debug APK and an unsigned iOS Simulator app. A device-installable IPA additionally requires Apple signing credentials and provisioning.
