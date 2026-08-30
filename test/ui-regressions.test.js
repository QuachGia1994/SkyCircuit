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

test('Android and iOS share the fast ignition stage duration', async () => {
  const [webSource, iosSource] = await Promise.all([
    text('src/main.js'),
    text('native/ios/SkyCircuitNative/Game/GameEngine.swift'),
  ])

  assert.match(webSource, /stageSeconds:\s*0\.14/)
  assert.match(iosSource, /burnStageDuration\s*=\s*0\.14/)
})
