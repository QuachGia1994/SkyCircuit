import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

const root = new URL('../', import.meta.url)

async function text(path) {
  return readFile(new URL(path, root), 'utf8')
}

test('startup branding exists in web shell and Capacitor splash config', async () => {
  const [html, configText] = await Promise.all([
    text('index.html'),
    text('capacitor.config.json'),
  ])
  const config = JSON.parse(configText)

  assert.match(html, /id="startup-splash"/)
  assert.match(html, /assets\/icon\.svg/)
  assert.equal(config.plugins?.SplashScreen?.launchAutoHide, true)
  assert.equal(config.plugins?.SplashScreen?.launchShowDuration, 4000)
  assert.equal(config.plugins?.SplashScreen?.launchFadeOutDuration, 340)
  assert.equal(config.plugins?.SplashScreen?.backgroundColor, '#07111fff')
})

test('Plus skin preview owns a clipped block box', async () => {
  const css = await text('styles.css')
  const rule = css.match(/\.skin-preview\s*\{([^}]*)\}/)?.[1] ?? ''

  assert.match(rule, /display:\s*block/)
  assert.match(rule, /overflow:\s*hidden/)
  assert.match(rule, /contain:\s*paint/)
})

test('modal UI suspends heavy Canvas work', async () => {
  const source = await text('src/main.js')

  assert.match(source, /document\.body\.classList\.toggle\('modal-open', state\.uiPaused\)/)
  assert.match(source, /if \(state\.uiPaused\) \{\s*requestAnimationFrame\(frame\)\s*return\s*\}/)
})

test('Android and iOS share launch timing and cinematic phases', async () => {
  const [webSource, iosEngine, iosScene, iosRoot] = await Promise.all([
    text('src/main.js'),
    text('native/ios/SkyCircuitNative/Game/GameEngine.swift'),
    text('native/ios/SkyCircuitNative/Game/GameScene.swift'),
    text('native/ios/SkyCircuitNative/Views/GameRootView.swift'),
  ])

  assert.match(webSource, /stageSeconds:\s*0\.14/)
  assert.match(iosEngine, /burnStageDuration\s*=\s*0\.14/)
  assert.match(webSource, /rocketFlightSeconds:\s*1\.55/)
  assert.match(iosEngine, /rocketFlightDuration\s*=\s*1\.55/)
  assert.match(webSource, /fireworkStartProgress:\s*0\.58/)
  assert.match(iosScene, /normalized - 0\.58/)
  assert.match(webSource, /rocketFlightTarget\(row\)/)
  assert.match(iosScene, /drawLaunchingRocket/)
  assert.match(webSource, /spawnFirework\(row, index\)/)
  assert.match(iosScene, /drawFireworkBurst/)
  assert.match(webSource, /4_000 - elapsed/)
  assert.match(iosRoot, /Task\.sleep\(for: \.seconds\(4\.0\)\)/)
})

test('Android bootstrap mirrors iOS ambient audio activation and music progression', async () => {
  const [webSource, iosRoot, iosAudio] = await Promise.all([
    text('src/main.js'),
    text('native/ios/SkyCircuitNative/Views/GameRootView.swift'),
    text('native/ios/SkyCircuitNative/Audio/ProceduralAudioEngine.swift'),
  ])

  assert.match(webSource, /bootstrapAmbientAudio\(\)/)
  assert.match(webSource, /pointerdown', bootstrapAmbientAudio/)
  assert.match(webSource, /const roots = \[110, 130\.81, 146\.83, 98\]/)
  assert.match(iosAudio, /let roots = \[110\.0, 130\.81, 146\.83, 98\.0\]/)
  assert.match(webSource, /659\.25 \+ lift, 783\.99 \+ lift, 1046\.5 \+ lift/)
  assert.match(iosAudio, /659\.25 \+ lift, 783\.99 \+ lift, 1046\.50 \+ lift/)
  assert.match(iosRoot, /engine\.activateAudio\(\)/)
})

test('Android and iOS expose the same six launch languages', async () => {
  const [webI18n, iosI18n] = await Promise.all([
    text('src/data/i18n.js'),
    text('native/ios/SkyCircuitNative/Localization/Localization.swift'),
  ])

  for (const language of ['en', 'vi', 'ja', 'ko', 'zh-Hans', 'fr']) {
    assert.match(webI18n, new RegExp(`['\"]?${language.replace('-', '\\-')}['\"]?`))
    assert.match(iosI18n, new RegExp(language.replace('-', '\\-')))
  }
})

test('Android beta has explicit full-access build flag and Daily Run parity hooks', async () => {
  const [html, buildScript, workflow, source] = await Promise.all([
    text('index.html'),
    text('scripts/build.mjs'),
    text('.github/workflows/android.yml'),
    text('src/main.js'),
  ])

  assert.match(html, /__SKYCIRCUIT_BETA__ = false/)
  assert.match(buildScript, /SKYCIRCUIT_BETA === '1'/)
  assert.match(workflow, /SKYCIRCUIT_BETA: '1'/)
  assert.match(source, /mode\.plus && !betaUnlocked/)
  assert.match(source, /skin\.plus && !betaUnlocked/)
  assert.match(source, /function startDailyRun\(\)/)
  assert.match(source, /skycircuit\.dailyStreak/)
})
