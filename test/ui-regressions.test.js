import assert from 'node:assert/strict'
import { readFile, stat } from 'node:fs/promises'
import test from 'node:test'

const root = new URL('../', import.meta.url)

async function text(path) {
  return readFile(new URL(path, root), 'utf8')
}

test('only the custom branded splash carries logo text and loading progress', async () => {
  const [html, configText, iosProject, iosStartup] = await Promise.all([
    text('index.html'),
    text('capacitor.config.json'),
    text('native/ios/project.yml'),
    text('native/ios/SkyCircuitNative/Views/StartupOverlay.swift'),
  ])
  const config = JSON.parse(configText)

  assert.match(html, /id="startup-splash"/)
  assert.match(html, /class="startup-wordmark"/)
  assert.match(html, /class="startup-progress"/)
  assert.equal(config.plugins?.SplashScreen?.launchAutoHide, true)
  assert.equal(config.plugins?.SplashScreen?.launchShowDuration, 120)
  assert.equal(config.plugins?.SplashScreen?.launchFadeOutDuration, 80)
  assert.equal(config.plugins?.SplashScreen?.backgroundColor, '#07111fff')
  assert.doesNotMatch(iosProject, /UIImageName:\s*LaunchLogo/)
  assert.doesNotMatch(iosStartup, /Image\("LaunchLogo"\)/)
  assert.match(iosStartup, /ignitionLine/)
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

test('Android and iOS bundle the same faster CC0 arcade BGM and keep procedural firework blast', async () => {
  const [webSource, iosRoot, iosAudio, iosProject, audioInfo] = await Promise.all([
    text('src/main.js'),
    text('native/ios/SkyCircuitNative/Views/GameRootView.swift'),
    text('native/ios/SkyCircuitNative/Audio/ProceduralAudioEngine.swift'),
    text('native/ios/project.yml'),
    stat(new URL('../assets/audio/duru-arcade-vibe.mp3', import.meta.url)),
  ])

  assert.ok(audioInfo.size > 1_000_000)
  assert.match(webSource, /assets\/audio\/duru-arcade-vibe\.mp3/)
  assert.match(webSource, /playbackRate = 1\.08/)
  assert.match(webSource, /Math\.min\(1\.16, 1\.08/)
  assert.match(iosAudio, /duru-arcade-vibe/)
  assert.match(iosAudio, /player\.rate = 1\.08/)
  assert.match(iosAudio, /min\(1\.16, 1\.08/)
  assert.match(iosProject, /duru-arcade-vibe\.mp3/)
  assert.match(webSource, /1450 \+ lift/)
  assert.match(webSource, /2350 \+ lift/)
  assert.match(iosAudio, /1_450 \+ lift/)
  assert.match(iosAudio, /2_350 \+ lift/)
  assert.match(iosRoot, /engine\.activateAudio\(\)/)
})

test('iOS play header keeps the title and mode labels single-line on compact phones', async () => {
  const iosRoot = await text('native/ios/SkyCircuitNative/Views/GameRootView.swift')

  assert.match(iosRoot, /VStack\(alignment: \.leading, spacing: 9\)/)
  assert.match(iosRoot, /Text\("SkyCircuit"\)[\s\S]*?\.layoutPriority\(1\)/)
  assert.match(iosRoot, /engine\.mode\.title[\s\S]*?\.lineLimit\(1\)/)
  assert.match(iosRoot, /L10n\.text\("daily"[\s\S]*?\.lineLimit\(1\)/)
})

test('iOS pause mirrors Android by darkening the board', async () => {
  const iosRoot = await text('native/ios/SkyCircuitNative/Views/GameRootView.swift')

  assert.match(iosRoot, /engine\.phase == \.paused/)
  assert.match(iosRoot, /pausedBoardOverlay/)
  assert.match(iosRoot, /\.fill\(\.black\.opacity\(0\.86\)\)/)
  assert.match(iosRoot, /status_paused/)
})

test('iOS Plus mirrors Android mobile hierarchy and roadmap', async () => {
  const plus = await text('native/ios/SkyCircuitNative/Views/PlusStoreView.swift')

  for (const marker of ['livePreview', 'skinSection', 'modeSection', 'benefitSection', 'roadmapSection', 'roadmapFooter', 'purchaseSection']) {
    assert.match(plus, new RegExp(marker))
  }
  assert.match(plus, /skinColumns = \[GridItem\(\.flexible\(\)\), GridItem\(\.flexible\(\)\)\]/)
  assert.match(plus, /VStack\(spacing: 10\) \{\s*ForEach\(GameMode\.allCases\)/)
  assert.match(plus, /FlowLayout\(spacing: 8\)/)
  for (const key of ['plus_skins', 'zen_blitz', 'daily_challenge', 'weekly_events', 'leaderboards', 'seasonal_themes']) {
    assert.match(plus, new RegExp(key))
  }
  assert.match(plus, /engine\.store\.isBetaUnlocked/)
  assert.match(plus, /ProductView\(id: product\.id\)/)
})

test('all iOS launch languages carry Plus roadmap localization keys', async () => {
  const files = ['en', 'vi', 'ja', 'ko', 'zh-Hans', 'fr'].map((language) => `native/ios/SkyCircuitNative/${language}.lproj/Localizable.strings`)
  const resources = await Promise.all(files.map(text))
  const keys = ['plus_eyebrow', 'live_skin_preview', 'skins', 'roadmap', 'plus_footer_title', 'plus_skins', 'weekly_events', 'leaderboards', 'seasonal_themes']

  for (const resource of resources) {
    for (const key of keys) assert.match(resource, new RegExp(`"${key}"\\s*=`))
  }
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

test('Android and iOS burn the full source component and fan out to every connected rocket', async () => {
  const [webBoard, iosEngine] = await Promise.all([
    text('src/core/board.js'),
    text('native/ios/SkyCircuitNative/Game/GameEngine.swift'),
  ])

  assert.match(webBoard, /sourceComponent\(row\)/)
  assert.match(webBoard, /component\.rocketRows\.length === 0/)
  assert.match(webBoard, /for \(const cell of component\.cells\)/)
  assert.match(webBoard, /isRocketEndpoint/)
  assert.doesNotMatch(webBoard, /nearestRocketPath|reachableRocketPaths/)
  assert.match(iosEngine, /sourceComponent\(from: source\)/)
  assert.match(iosEngine, /rocketRows\.formUnion\(component\.rocketRows\)/)
  assert.match(iosEngine, /for cell in component\.cells/)
  assert.match(iosEngine, /isRocketEndpoint/)
  assert.doesNotMatch(iosEngine, /nearestRocketPath|reachableRocketPaths/)
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
