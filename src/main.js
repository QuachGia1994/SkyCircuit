import { Board, Direction } from './core/board.js'
import { plusBenefits, plusRoadmap, tutorialSteps } from './data/content.js'
import { getMode, modeList } from './data/modes.js'
import { getSkin, skinList } from './data/skins.js'
import { languageList, normalizeLanguage, translate } from './data/i18n.js'

const canvas = document.querySelector('#game')
const context = canvas.getContext('2d')
const elements = {
  startupTagline: document.querySelector('#startup-tagline'),
  burnLabel: document.querySelector('#burn-label'),
  brandEyebrow: document.querySelector('#brand-eyebrow'),
  levelLabel: document.querySelector('#level-label'),
  rocketsLabel: document.querySelector('#rockets-label'),
  scoreLabel: document.querySelector('#score-label'),
  comboLabel: document.querySelector('#combo-label'),
  timeLabel: document.querySelector('#time-label'),
  bestLabel: document.querySelector('#best-label'),
  score: document.querySelector('#score'),
  combo: document.querySelector('#combo'),
  rockets: document.querySelector('#rockets'),
  target: document.querySelector('#target'),
  time: document.querySelector('#time'),
  best: document.querySelector('#best'),
  level: document.querySelector('#level'),
  modeLabel: document.querySelector('#mode-label'),
  dailyButton: document.querySelector('#daily-button'),
  dailyLabel: document.querySelector('#daily-label'),
  status: document.querySelector('#status'),
  overlay: document.querySelector('#overlay'),
  overlayTitle: document.querySelector('#overlay-title'),
  overlayCopy: document.querySelector('#overlay-copy'),
  burnBanner: document.querySelector('#burn-banner'),
  pause: document.querySelector('#pause'),
  restart: document.querySelector('#restart'),
  helpButton: document.querySelector('#help-button'),
  settingsButton: document.querySelector('#settings-button'),
  plusButton: document.querySelector('#plus-button'),
  tutorial: document.querySelector('#tutorial'),
  tutorialNumber: document.querySelector('#tutorial-number'),
  tutorialEyebrow: document.querySelector('#tutorial-eyebrow'),
  tutorialTitle: document.querySelector('#tutorial-title'),
  tutorialBody: document.querySelector('#tutorial-body'),
  tutorialDots: document.querySelector('#tutorial-dots'),
  tutorialSkip: document.querySelector('#tutorial-skip'),
  tutorialPrev: document.querySelector('#tutorial-prev'),
  tutorialNext: document.querySelector('#tutorial-next'),
  plusScreen: document.querySelector('#plus-screen'),
  plusClose: document.querySelector('#plus-close'),
  activeSkinName: document.querySelector('#active-skin-name'),
  plusEyebrow: document.querySelector('#plus-eyebrow'),
  livePreviewLabel: document.querySelector('#live-preview-label'),
  skinsLabel: document.querySelector('#skins-label'),
  skinsHint: document.querySelector('#skins-hint'),
  modesLabel: document.querySelector('#modes-label'),
  modesHint: document.querySelector('#modes-hint'),
  benefitsLabel: document.querySelector('#benefits-label'),
  benefitsHint: document.querySelector('#benefits-hint'),
  roadmapLabel: document.querySelector('#roadmap-label'),
  roadmapHint: document.querySelector('#roadmap-hint'),
  plusFooterTitle: document.querySelector('#plus-footer-title'),
  plusFooterBody: document.querySelector('#plus-footer-body'),
  skinGrid: document.querySelector('#skin-grid'),
  modeGrid: document.querySelector('#mode-grid'),
  benefitGrid: document.querySelector('#benefit-grid'),
  roadmap: document.querySelector('#roadmap'),
  startupSplash: document.querySelector('#startup-splash'),
  settingsScreen: document.querySelector('#settings-screen'),
  settingsClose: document.querySelector('#settings-close'),
  settingsTitle: document.querySelector('#settings-title'),
  languageLabel: document.querySelector('#language-label'),
  musicLabel: document.querySelector('#music-label'),
  effectsLabel: document.querySelector('#effects-label'),
  hapticsLabel: document.querySelector('#haptics-label'),
  languageSelect: document.querySelector('#language-select'),
  musicToggle: document.querySelector('#music-toggle'),
  effectsToggle: document.querySelector('#effects-toggle'),
  hapticsToggle: document.querySelector('#haptics-toggle'),
}

const betaUnlocked = globalThis.__SKYCIRCUIT_BETA__ === true
const layout = Object.freeze({ canvasWidth: 768, canvasHeight: 720, rows: 8, cols: 8, cell: 72, boardX: 96, boardY: 72, boardSize: 576 })
const burnTiming = Object.freeze({
  stageSeconds: 0.14,
  rocketFlightSeconds: 1.55,
  fireworkStartProgress: 0.58,
  rocketVisibleUntilBurstProgress: 0.24,
})
const tutorialAccents = Object.freeze({ cyan: '#7be8ff', gold: '#ffd166', violet: '#c58cff' })
const tilePool = [
  Direction.NORTH | Direction.SOUTH,
  Direction.NORTH | Direction.SOUTH,
  Direction.NORTH | Direction.EAST,
  Direction.NORTH | Direction.EAST,
  Direction.NORTH | Direction.EAST,
  Direction.NORTH | Direction.EAST | Direction.SOUTH,
  Direction.NORTH | Direction.EAST | Direction.SOUTH | Direction.WEST,
]

let board
let state
let lastFrame = performance.now()
let audioContext = null
let ambientGain = null
let ambientStarted = false
const ambientNodes = []
const particles = []
const startupShownAt = performance.now()

function createState(modeKey = localStorage.getItem('skycircuit.mode') ?? 'classic') {
  const requestedMode = getMode(modeKey)
  const mode = requestedMode.plus && !betaUnlocked ? getMode('classic') : requestedMode
  return {
    score: 0,
    best: Number(localStorage.getItem('skycircuit.best') ?? 0),
    level: 1,
    launched: 0,
    target: mode.initialTarget,
    timeLeft: mode.initialTime,
    paused: false,
    uiPaused: false,
    resolving: false,
    gameOver: false,
    combo: 1,
    modeKey: mode.key,
    skinKey: localStorage.getItem('skycircuit.skin') ?? 'classic',
    powered: new Set(),
    burning: new Set(),
    launchingRows: new Set(),
    burn: null,
    tutorialStep: 0,
    language: normalizeLanguage(localStorage.getItem('skycircuit.language') ?? 'en'),
    musicEnabled: localStorage.getItem('skycircuit.music') !== '0',
    effectsEnabled: localStorage.getItem('skycircuit.effects') !== '0',
    hapticsEnabled: localStorage.getItem('skycircuit.haptics') !== '0',
    dailyActive: false,
    dailyProgress: 0,
    dailyStreak: Math.max(1, Number(localStorage.getItem('skycircuit.dailyStreak') ?? 1)),
  }
}

function t(key) {
  const language = state?.language ?? normalizeLanguage(localStorage.getItem('skycircuit.language') ?? 'en')
  return translate(language, key)
}

function tf(key, values) {
  return Object.entries(values).reduce((text, [name, value]) => text.replaceAll(`{${name}}`, String(value)), t(key))
}

function translatedModeName(mode) {
  return t(mode.key)
}

function translatedModeDescription(mode) {
  if (mode.key === 'zen') return t('zenDesc')
  if (mode.key === 'blitz') return t('blitzDesc')
  return t('classicDesc')
}

function applyTranslations() {
  document.documentElement.lang = state.language
  setText(elements.startupTagline, t('startupTagline'))
  setText(elements.burnLabel, t('ignition'))
  setText(elements.brandEyebrow, t('tagline'))
  setText(elements.levelLabel, t('level'))
  setText(elements.rocketsLabel, t('rockets'))
  setText(elements.scoreLabel, t('score'))
  setText(elements.comboLabel, t('combo'))
  setText(elements.timeLabel, t('time'))
  setText(elements.bestLabel, t('best'))
  setText(elements.pause, state.paused ? t('resume') : t('pause'))
  setText(elements.restart, t('newGame'))
  setText(elements.dailyLabel, t('daily'))
  setText(elements.settingsTitle, t('settings'))
  setText(elements.languageLabel, t('language'))
  setText(elements.musicLabel, t('music'))
  setText(elements.effectsLabel, t('effects'))
  setText(elements.hapticsLabel, t('haptics'))
  renderLanguageOptions()
  applyPlusTranslations()
}

function renderLanguageOptions() {
  elements.languageSelect.innerHTML = languageList.map(({ key, name }) => `<option value="${key}">${name}</option>`).join('')
  elements.languageSelect.value = state.language
}

function applyPlusTranslations() {
  setText(elements.plusEyebrow, t('plusEyebrow'))
  setText(elements.livePreviewLabel, t('livePreview'))
  setText(elements.skinsLabel, t('skins'))
  setText(elements.skinsHint, t('tapSkin'))
  setText(elements.modesLabel, t('modes'))
  setText(elements.modesHint, t('modesHint'))
  setText(elements.benefitsLabel, t('benefits'))
  setText(elements.benefitsHint, t('productDirection'))
  setText(elements.roadmapLabel, t('roadmap'))
  setText(elements.roadmapHint, t('noBackend'))
  setText(elements.plusFooterTitle, t('plusFooterTitle'))
  setText(elements.plusFooterBody, t('plusFooterBody'))
}

function newGame(modeKey = state?.modeKey ?? localStorage.getItem('skycircuit.mode') ?? 'classic') {
  const skinKey = state?.skinKey ?? localStorage.getItem('skycircuit.skin') ?? 'classic'
  board = new Board(layout.rows, layout.cols, Math.random, tilePool)
  state = createState(modeKey)
  const restoredSkin = getSkin(skinKey)
  state.skinKey = restoredSkin.plus && !betaUnlocked ? 'classic' : restoredSkin.key
  particles.length = 0
  hideOverlay()
  hideBurnBanner()
  applySkin(state.skinKey, false)
  syncSettingsControls()
  applyTranslations()
  elements.status.textContent = t('statusConnect')
  setAmbientEnergy(state.combo, false)
  updateHud()
  if (localStorage.getItem('skycircuit.tutorialSeen') !== '1') openTutorial(0)
}

function updateHud() {
  setText(elements.score, String(state.score))
  setText(elements.combo, `×${state.combo}`)
  setText(elements.rockets, String(state.launched))
  setText(elements.target, String(state.target))
  setText(elements.time, Number.isFinite(state.timeLeft) ? String(Math.max(0, Math.ceil(state.timeLeft))) : '∞')
  setText(elements.best, String(state.best))
  setText(elements.level, String(state.level))
  setText(elements.modeLabel, translatedModeName(getMode(state.modeKey)))
  elements.dailyButton.classList.toggle('active', state.dailyActive)
}

function setText(element, value) {
  if (element.textContent !== value) element.textContent = value
}

function canvasPoint(event) {
  const rect = canvas.getBoundingClientRect()
  return {
    x: (event.clientX - rect.left) * (layout.canvasWidth / rect.width),
    y: (event.clientY - rect.top) * (layout.canvasHeight / rect.height),
  }
}

function tileAt(point) {
  const col = Math.floor((point.x - layout.boardX) / layout.cell)
  const row = Math.floor((point.y - layout.boardY) / layout.cell)
  if (row < 0 || row >= layout.rows || col < 0 || col >= layout.cols) return null
  return { row, col }
}

function handleBoardTap(event) {
  if (state.paused || state.uiPaused || state.gameOver || state.resolving) return
  const tile = tileAt(canvasPoint(event))
  if (!tile) return
  ensureAudio()
  board.rotate(tile.row, tile.col)
  const quality = board.connectionQuality(tile.row, tile.col)
  playPlacementSound(quality)
  vibrate(Math.round(16 - quality * 8))
  const launch = board.resolveLaunch()
  if (launch.rocketRows.length > 0) startBurn(launch, 1)
  else state.combo = 1
}

function startBurn(launch, combo) {
  state.resolving = true
  state.combo = combo
  state.powered.clear()
  state.burning.clear()
  state.launchingRows.clear()
  state.burn = {
    launch,
    elapsed: 0,
    activeStage: -1,
    stageProgress: 0,
    phase: 'burn',
    hold: 0,
    fireworkTriggered: false,
  }
  elements.status.textContent = t('statusIgnition')
  setAmbientEnergy(state.combo, true)
  elements.burnBanner.hidden = false
  playTone(190, 0.12, 'triangle', 0.035)
  updateHud()
}

function updateBurn(deltaSeconds) {
  if (!state.burn) return
  if (state.burn.phase === 'rocket') return updateRocketHold(deltaSeconds)

  const stages = state.burn.launch.burnStages
  state.burn.elapsed += deltaSeconds
  const rawProgress = state.burn.elapsed / burnTiming.stageSeconds
  const completedCount = Math.min(stages.length, Math.floor(rawProgress))
  const activeStage = completedCount < stages.length ? completedCount : -1
  state.burn.stageProgress = activeStage >= 0 ? rawProgress - Math.floor(rawProgress) : 1
  state.powered = stageSet(stages, completedCount)
  state.burning = activeStage >= 0 ? cellSet(stages[activeStage]) : new Set()

  if (activeStage >= 0 && activeStage !== state.burn.activeStage) {
    state.burn.activeStage = activeStage
    spawnBurnSparks(stages[activeStage])
    if (activeStage % 2 === 0) playTone(210 + activeStage * 16, 0.055, 'triangle', 0.018)
  }

  if (completedCount >= stages.length) beginRocketLaunch()
}

function beginRocketLaunch() {
  const launch = state.burn.launch
  state.powered = cellSet(launch.burned)
  state.burning.clear()
  state.launchingRows = new Set(launch.rocketRows)
  state.burn.phase = 'rocket'
  state.burn.hold = 0
  hideBurnBanner()
  applyLaunchScore(launch)
  playLaunchSound(state.combo)
  vibrate(Math.min(95, 26 + launch.rocketRows.length * 14))
  elements.status.textContent = launch.rocketRows.length > 1
    ? tf('statusRocketMulti', { count: launch.rocketRows.length, combo: state.combo })
    : tf('statusRocketSingle', { combo: state.combo })
}

function updateRocketHold(deltaSeconds) {
  state.burn.hold += deltaSeconds
  const progress = Math.min(1, state.burn.hold / burnTiming.rocketFlightSeconds)
  if (!state.burn.fireworkTriggered && progress >= burnTiming.fireworkStartProgress) {
    state.burn.fireworkTriggered = true
    state.burn.launch.rocketRows.forEach((row, index) => spawnFirework(row, index))
    playFireworkSound(state.burn.launch.rocketRows.length)
  }
  if (state.burn.hold >= burnTiming.rocketFlightSeconds) finishLaunch(state.burn.launch)
}

function applyLaunchScore(launch) {
  const rocketCount = launch.rocketRows.length
  const multiRocketBonus = Math.max(0, rocketCount - 1) * 175
  const comboBonus = Math.max(0, state.combo - 1) * 125
  state.score += rocketCount * 100 + multiRocketBonus + comboBonus + launch.burned.length * 5
  state.launched += rocketCount
  if (state.dailyActive) state.dailyProgress = Math.min(1, state.dailyProgress + rocketCount / Math.max(state.target, 1))
  if (state.score > state.best) {
    state.best = state.score
    localStorage.setItem('skycircuit.best', String(state.best))
  }
  updateHud()
}

function finishLaunch(launch) {
  const previousCombo = state.combo
  board.consume(launch.burned)
  state.powered.clear()
  state.burning.clear()
  state.launchingRows.clear()
  state.burn = null
  state.resolving = false
  setAmbientEnergy(state.combo, false)
  if (state.launched >= state.target) return advanceLevel()
  const cascade = board.resolveLaunch()
  if (cascade.rocketRows.length > 0) startBurn(cascade, Math.min(9, previousCombo + 1))
  else state.combo = 1
}

function advanceLevel() {
  const mode = getMode(state.modeKey)
  state.level += 1
  state.launched = 0
  state.combo = 1
  state.target = mode.levelTarget(state.level)
  state.timeLeft = mode.levelTime(state.level)
  board = new Board(layout.rows, layout.cols, Math.random, tilePool)
  showOverlay(`${t('level')} ${state.level}`, t('statusConnect'), 820)
  updateHud()
}

function setGameMode(modeKey) {
  const mode = getMode(modeKey)
  if (mode.plus && !betaUnlocked) return
  localStorage.setItem('skycircuit.mode', mode.key)
  closePlusScreen()
  newGame(mode.key)
  elements.status.textContent = `${translatedModeName(mode)} · ${translatedModeDescription(mode)}`
}

function startDailyRun() {
  if (state.resolving) {
    elements.status.textContent = t('statusWaitIgnition')
    return
  }
  refreshDailyStreak()
  state.dailyActive = true
  state.dailyProgress = 0
  elements.status.textContent = `${t('daily')} · 🔥 ${state.dailyStreak}`
  updateHud()
}

function refreshDailyStreak() {
  const today = localDayKey(new Date())
  const lastDay = localStorage.getItem('skycircuit.lastDaily')
  if (lastDay === today) return
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  state.dailyStreak = lastDay === localDayKey(yesterday) ? state.dailyStreak + 1 : 1
  localStorage.setItem('skycircuit.lastDaily', today)
  localStorage.setItem('skycircuit.dailyStreak', String(state.dailyStreak))
}

function localDayKey(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function togglePause() {
  if (state.gameOver || state.resolving || state.uiPaused) return
  state.paused = !state.paused
  elements.pause.textContent = state.paused ? t('resume') : t('pause')
  elements.status.textContent = state.paused ? t('statusPaused') : t('statusResumed')
  if (state.paused) showOverlay(t('pause'), t('statusPaused'))
  else hideOverlay()
}

function endGame() {
  state.gameOver = true
  state.timeLeft = 0
  updateHud()
  showOverlay(t('gameOver'), `${t('score')} ${state.score} · ${t('best')} ${state.best}`)
  elements.status.textContent = t('statusTimeExpired')
  playTone(120, 0.3, 'sawtooth', 0.04)
}

function showOverlay(title, copy, autoHideMs = 0) {
  elements.overlayTitle.textContent = title
  elements.overlayCopy.textContent = copy
  elements.overlay.hidden = false
  if (autoHideMs > 0) setTimeout(() => { if (!state.paused && !state.gameOver) hideOverlay() }, autoHideMs)
}

function hideOverlay() {
  elements.overlay.hidden = true
}

function hideBurnBanner() {
  elements.burnBanner.hidden = true
}

function dismissStartupSplash() {
  const elapsed = performance.now() - startupShownAt
  const delay = Math.max(0, 4_000 - elapsed)
  setTimeout(() => {
    if (elements.startupSplash.hidden) return
    elements.startupSplash.classList.add('is-hiding')
    setTimeout(() => { elements.startupSplash.hidden = true }, 300)
  }, delay)
}

function openTutorial(step = 0) {
  if (state.resolving) {
    elements.status.textContent = t('statusWaitIgnition')
    return
  }
  state.tutorialStep = Math.max(0, Math.min(tutorialSteps.length - 1, step))
  elements.tutorial.hidden = false
  syncUiPause()
  renderTutorial()
}

function renderTutorial() {
  const step = tutorialSteps[state.tutorialStep]
  elements.tutorial.dataset.step = String(state.tutorialStep)
  elements.tutorial.style.setProperty('--accent', tutorialAccents[step.accent])
  elements.tutorialNumber.textContent = String(step.number)
  const prefix = `tutorial${state.tutorialStep + 1}`
  elements.tutorialEyebrow.textContent = t(`${prefix}Eyebrow`)
  elements.tutorialTitle.textContent = t(`${prefix}Title`)
  elements.tutorialBody.textContent = t(`${prefix}Body`)
  elements.tutorialDots.innerHTML = tutorialSteps.map((_, index) => `<i class="${index === state.tutorialStep ? 'active' : ''}"></i>`).join('')
  elements.tutorialPrev.hidden = state.tutorialStep === 0
  elements.tutorialSkip.textContent = t('skip')
  elements.tutorialPrev.textContent = t('back')
  elements.tutorialNext.textContent = state.tutorialStep === tutorialSteps.length - 1 ? t('gotIt') : t('next')
}

function nextTutorialStep() {
  if (state.tutorialStep < tutorialSteps.length - 1) {
    state.tutorialStep += 1
    renderTutorial()
    return
  }
  closeTutorial(true)
}

function previousTutorialStep() {
  if (state.tutorialStep === 0) return
  state.tutorialStep -= 1
  renderTutorial()
}

function closeTutorial(markSeen) {
  elements.tutorial.hidden = true
  if (markSeen) localStorage.setItem('skycircuit.tutorialSeen', '1')
  syncUiPause()
}

function openPlusScreen() {
  if (state.resolving) {
    elements.status.textContent = t('statusWaitIgnition')
    return
  }
  renderPlusScreen()
  elements.plusScreen.hidden = false
  syncUiPause()
}

function closePlusScreen() {
  elements.plusScreen.hidden = true
  syncUiPause()
}

function openSettingsScreen() {
  syncSettingsControls()
  elements.settingsScreen.hidden = false
  syncUiPause()
}

function closeSettingsScreen() {
  elements.settingsScreen.hidden = true
  syncUiPause()
}

function syncSettingsControls() {
  elements.musicToggle.checked = state.musicEnabled
  elements.effectsToggle.checked = state.effectsEnabled
  elements.hapticsToggle.checked = state.hapticsEnabled
  renderLanguageOptions()
}

function setLanguage(language) {
  state.language = normalizeLanguage(language)
  localStorage.setItem('skycircuit.language', state.language)
  applyTranslations()
  updateHud()
  if (!elements.tutorial.hidden) renderTutorial()
  if (!elements.plusScreen.hidden) renderPlusScreen()
  if (!state.gameOver && !state.resolving) elements.status.textContent = t('statusConnect')
}

function setMusicEnabled(enabled) {
  state.musicEnabled = enabled
  localStorage.setItem('skycircuit.music', enabled ? '1' : '0')
  if (enabled) ensureAudio()
  setAmbientEnergy(state.combo, Boolean(state.burn))
}

function setEffectsEnabled(enabled) {
  state.effectsEnabled = enabled
  localStorage.setItem('skycircuit.effects', enabled ? '1' : '0')
}

function setHapticsEnabled(enabled) {
  state.hapticsEnabled = enabled
  localStorage.setItem('skycircuit.haptics', enabled ? '1' : '0')
}

function syncUiPause() {
  state.uiPaused = !elements.tutorial.hidden || !elements.plusScreen.hidden || !elements.settingsScreen.hidden
  document.body.classList.toggle('modal-open', state.uiPaused)
}

function renderPlusScreen() {
  renderSkinSelection()
  elements.modeGrid.innerHTML = modeList.map((mode) => modeCardMarkup(mode, mode.key === state.modeKey)).join('')
  elements.benefitGrid.innerHTML = translatedBenefits().map((benefit) => `<article class="benefit-card"><span class="benefit-icon">${benefit.icon}</span><div><strong>${benefit.title}</strong><p>${benefit.body}</p></div></article>`).join('')
  elements.roadmap.innerHTML = translatedRoadmap().map((item) => `<span class="roadmap-item"><b>${item.label}</b><span>${item.status}</span></span>`).join('')
}

function renderSkinSelection() {
  const activeSkin = getSkin(state.skinKey)
  elements.activeSkinName.textContent = activeSkin.name
  elements.skinGrid.innerHTML = skinList.map((skin) => skinCardMarkup(skin, skin.key === activeSkin.key)).join('')
}

function translatedRoadmap() {
  const rows = [
    ['plusSkins', 'ready'],
    ['zenBlitz', 'ready'],
    ['dailyChallenge', 'nextStatus'],
    ['weeklyEvents', 'later'],
    ['leaderboards', 'later'],
    ['seasonalThemes', 'later'],
  ]
  return plusRoadmap.map((_, index) => ({ label: t(rows[index][0]), status: t(rows[index][1]) }))
}

function translatedBenefits() {
  const keys = [
    ['exclusiveSkins', 'exclusiveSkinsBody'],
    ['zenMode', 'zenModeBody'],
    ['blitzMode', 'blitzModeBody'],
    ['dailyChallenge', 'dailyChallengeBody'],
  ]
  return plusBenefits.map((benefit, index) => ({ icon: benefit.icon, title: t(keys[index][0]), body: t(keys[index][1]) }))
}

function skinCardMarkup(skin, active) {
  const badge = skin.plus ? t('plusPreview') : t('free')
  const style = `--preview-top:${skin.backgroundTop};--preview-bottom:${skin.backgroundBottom};--preview-conduit:${skin.conduit};--preview-powered:${skin.powered};--preview-rocket:${skin.rocket}`
  return `<button class="skin-card ${active ? 'active' : ''}" type="button" data-skin="${skin.key}" style="${style}"><span class="skin-preview"></span><strong>${skin.name}</strong><small>${badge}</small></button>`
}

function modeCardMarkup(mode, active) {
  const badge = mode.plus ? t('plusPreview') : t('free')
  return `<button class="mode-card ${active ? 'active' : ''}" type="button" data-mode="${mode.key}"><strong>${translatedModeName(mode)}</strong><span>${translatedModeDescription(mode)}</span><small>${badge}</small></button>`
}

function handlePlusClick(event) {
  if (event.target === elements.plusScreen) {
    closePlusScreen()
    return
  }
  const skinButton = event.target.closest('[data-skin]')
  if (skinButton) {
    applySkin(skinButton.dataset.skin)
    renderSkinSelection()
    return
  }
  const modeButton = event.target.closest('[data-mode]')
  if (modeButton) setGameMode(modeButton.dataset.mode)
}

function applySkin(skinKey, persist = true) {
  const skin = getSkin(skinKey)
  if (skin.plus && !betaUnlocked) return
  state.skinKey = skin.key
  if (persist) localStorage.setItem('skycircuit.skin', skin.key)
  document.documentElement.style.setProperty('--accent', skin.cssAccent)
  document.documentElement.style.setProperty('--accent-alt', skin.cssAccentAlt)
  document.documentElement.style.setProperty('--pink', skin.rocket)
  document.documentElement.style.setProperty('--powered', skin.powered)
  document.documentElement.style.setProperty('--powered-core', skin.poweredCore)
  document.documentElement.style.setProperty('--rocket-dark', skin.rocketDark)
  document.documentElement.style.setProperty('--page-top', skin.backgroundTop)
  document.documentElement.style.setProperty('--page-mid', skin.cssAccentAlt)
  document.documentElement.style.setProperty('--page-bottom', skin.backgroundBottom)
}

function render() {
  drawBackground()
  drawBoardChassis()
  drawBoard()
  drawSources()
  drawRockets()
  drawParticles()
}

function drawBackground() {
  const skin = getSkin(state.skinKey)
  const gradient = context.createLinearGradient(0, 0, 0, layout.canvasHeight)
  gradient.addColorStop(0, skin.backgroundTop)
  gradient.addColorStop(0.52, '#071226')
  gradient.addColorStop(1, skin.backgroundBottom)
  context.fillStyle = gradient
  context.fillRect(0, 0, layout.canvasWidth, layout.canvasHeight)

  drawNebula(170, 120, 260, 'rgba(35, 105, 210, 0.24)')
  drawNebula(610, 185, 230, 'rgba(77, 63, 175, 0.18)')
  drawNebula(390, 650, 310, 'rgba(27, 86, 152, 0.15)')

  for (let index = 0; index < 78; index += 1) {
    const x = (index * 137 + 29) % layout.canvasWidth
    const y = (index * 83 + 17) % layout.canvasHeight
    const radius = 0.7 + (index % 4) * 0.28
    context.globalAlpha = 0.35 + (index % 5) * 0.11
    context.fillStyle = index % 7 === 0 ? '#a7ddff' : '#ffffff'
    context.beginPath()
    context.arc(x, y, radius, 0, Math.PI * 2)
    context.fill()
    if (index % 13 === 0) {
      context.strokeStyle = '#dff6ff'
      context.lineWidth = 0.7
      context.beginPath()
      context.moveTo(x - 5, y)
      context.lineTo(x + 5, y)
      context.moveTo(x, y - 5)
      context.lineTo(x, y + 5)
      context.stroke()
    }
  }
  context.globalAlpha = 1
  drawSkyTower(14, 700, 170, 38, '#0a1730')
  drawSkyTower(61, 700, 116, 28, '#09162b')
  drawSkyTower(706, 700, 184, 42, '#08152c')
  drawSkyTower(666, 700, 122, 26, '#09162b')
}

function drawNebula(x, y, radius, color) {
  const nebula = context.createRadialGradient(x, y, 0, x, y, radius)
  nebula.addColorStop(0, color)
  nebula.addColorStop(0.48, color.replace(/0\.(\d+)\)/, '0.08)'))
  nebula.addColorStop(1, 'rgba(0,0,0,0)')
  context.fillStyle = nebula
  context.fillRect(x - radius, y - radius, radius * 2, radius * 2)
}

function drawSkyTower(x, baseY, height, width, color) {
  context.save()
  context.globalAlpha = 0.82
  context.fillStyle = color
  context.beginPath()
  context.moveTo(x, baseY)
  context.lineTo(x, baseY - height + 20)
  context.lineTo(x + width * 0.35, baseY - height + 12)
  context.lineTo(x + width * 0.5, baseY - height)
  context.lineTo(x + width * 0.65, baseY - height + 12)
  context.lineTo(x + width, baseY - height + 20)
  context.lineTo(x + width, baseY)
  context.closePath()
  context.fill()
  context.fillStyle = 'rgba(89,190,255,0.55)'
  for (let row = 0; row < 5; row += 1) {
    for (let col = 0; col < 2; col += 1) {
      const wx = x + 8 + col * 12
      const wy = baseY - 28 - row * 20
      if (wy < baseY - height + 25) continue
      context.fillRect(wx, wy, 3, 6)
    }
  }
  context.restore()
}

function drawBoardChassis() {
  const skin = getSkin(state.skinKey)
  const metal = context.createLinearGradient(24, 38, 744, 690)
  metal.addColorStop(0, skin.tileEdge)
  metal.addColorStop(0.08, '#111b28')
  metal.addColorStop(0.48, '#04080e')
  metal.addColorStop(0.88, '#162437')
  metal.addColorStop(1, skin.tileEdge)
  context.fillStyle = metal
  context.strokeStyle = '#02050a'
  context.lineWidth = 5
  roundRect(24, 38, 720, 646, 32)
  context.fill()
  context.stroke()

  context.strokeStyle = 'rgba(142, 193, 235, 0.22)'
  context.lineWidth = 2
  roundRect(34, 48, 700, 626, 25)
  context.stroke()
  context.strokeStyle = 'rgba(0,0,0,0.72)'
  context.lineWidth = 8
  roundRect(80, 58, 608, 604, 19)
  context.stroke()

  const corners = [[40, 54], [728, 54], [40, 668], [728, 668]]
  for (const [x, y] of corners) drawBolt(x, y, 5, skin.bolt)
}

function drawBoard() {
  for (let row = 0; row < layout.rows; row += 1) {
    for (let col = 0; col < layout.cols; col += 1) drawTile(row, col, board.get(row, col))
  }
}

function drawTile(row, col, mask) {
  const skin = getSkin(state.skinKey)
  const x = layout.boardX + col * layout.cell
  const y = layout.boardY + row * layout.cell
  const key = `${row}:${col}`
  const powered = state.powered.has(key)
  const burning = state.burning.has(key)
  const hot = powered || burning

  const plate = context.createLinearGradient(x + 5, y + 5, x + layout.cell - 5, y + layout.cell - 5)
  plate.addColorStop(0, skin.tileTop)
  plate.addColorStop(0.28, skin.tile)
  plate.addColorStop(0.72, skin.tileBottom)
  plate.addColorStop(1, '#05080d')
  context.fillStyle = plate
  context.strokeStyle = hot ? skin.powered : '#05080d'
  context.lineWidth = hot ? 2.4 : 2.2
  roundRect(x + 3, y + 3, layout.cell - 6, layout.cell - 6, 9)
  context.fill()
  context.stroke()

  context.strokeStyle = hot ? 'rgba(255,201,96,0.5)' : 'rgba(157,190,222,0.19)'
  context.lineWidth = 1
  roundRect(x + 7, y + 7, layout.cell - 14, layout.cell - 14, 7)
  context.stroke()
  context.strokeStyle = 'rgba(0,0,0,0.55)'
  context.beginPath()
  context.moveTo(x + 10, y + layout.cell - 8)
  context.lineTo(x + layout.cell - 10, y + layout.cell - 8)
  context.stroke()

  drawBolt(x + 11, y + 11, 2.2, skin.bolt)
  drawBolt(x + layout.cell - 11, y + 11, 2.2, skin.bolt)
  drawBolt(x + 11, y + layout.cell - 11, 2.2, skin.bolt)
  drawBolt(x + layout.cell - 11, y + layout.cell - 11, 2.2, skin.bolt)
  drawConduit(x + layout.cell / 2, y + layout.cell / 2, mask, powered, burning)
  if (burning) drawBurnHead(row, col, mask, x + layout.cell / 2, y + layout.cell / 2)
}

function drawConduit(centerX, centerY, mask, powered, burning) {
  const skin = getSkin(state.skinKey)
  const reach = layout.cell / 2 - 7
  context.save()
  context.lineCap = 'round'
  context.lineJoin = 'round'

  context.strokeStyle = 'rgba(0,0,0,0.78)'
  context.lineWidth = 24
  strokeConduitShape(centerX, centerY, mask, reach)

  const pipe = context.createLinearGradient(centerX - reach, centerY - reach, centerX + reach, centerY + reach)
  pipe.addColorStop(0, skin.pipeDark)
  pipe.addColorStop(0.22, skin.pipeMid)
  pipe.addColorStop(0.42, skin.pipeLight)
  pipe.addColorStop(0.58, skin.pipeMid)
  pipe.addColorStop(0.82, skin.pipeDark)
  pipe.addColorStop(1, skin.pipeLight)
  context.strokeStyle = pipe
  context.lineWidth = 17
  strokeConduitShape(centerX, centerY, mask, reach)

  context.globalAlpha = 0.46
  context.strokeStyle = '#ffffff'
  context.lineWidth = 2.2
  strokeConduitShape(centerX - 1.5, centerY - 1.5, mask, reach - 1)
  context.globalAlpha = 1

  context.strokeStyle = skin.copper
  context.globalAlpha = 0.54
  context.lineWidth = 2.4
  strokeConduitShape(centerX, centerY, mask, reach)
  context.globalAlpha = 1

  drawCouplers(centerX, centerY, mask, reach, skin)
  drawJunctionHub(centerX, centerY, mask, skin)

  if (powered || burning) {
    const alpha = powered ? 1 : 0.45 + state.burn.stageProgress * 0.55
    context.globalAlpha = alpha
    context.shadowBlur = burning ? 22 : 13
    context.shadowColor = skin.powered
    context.strokeStyle = skin.powered
    context.lineWidth = burning ? 9 : 8
    strokeConduitShape(centerX, centerY, mask, reach - 1)
    context.shadowBlur = 8
    context.strokeStyle = skin.poweredCore
    context.lineWidth = 3
    strokeConduitShape(centerX, centerY, mask, reach - 2)
    context.globalAlpha = 1
    context.shadowBlur = 0
  }
  context.restore()
}

function strokeConduitShape(centerX, centerY, mask, reach) {
  const endpoints = conduitEndpoints(centerX, centerY, mask, reach)
  context.beginPath()
  if (endpoints.length === 0) return
  if (endpoints.length === 1) {
    context.moveTo(centerX, centerY)
    context.lineTo(endpoints[0].x, endpoints[0].y)
  } else if (endpoints.length === 2 && areOpposite(endpoints[0].bit, endpoints[1].bit)) {
    context.moveTo(endpoints[0].x, endpoints[0].y)
    context.lineTo(endpoints[1].x, endpoints[1].y)
  } else if (endpoints.length === 2) {
    context.moveTo(endpoints[0].x, endpoints[0].y)
    context.quadraticCurveTo(centerX, centerY, endpoints[1].x, endpoints[1].y)
  } else {
    for (const endpoint of endpoints) {
      context.moveTo(centerX, centerY)
      context.lineTo(endpoint.x, endpoint.y)
    }
  }
  context.stroke()
}

function conduitEndpoints(centerX, centerY, mask, reach) {
  const endpoints = []
  if ((mask & Direction.NORTH) !== 0) endpoints.push({ bit: Direction.NORTH, x: centerX, y: centerY - reach, angle: -Math.PI / 2 })
  if ((mask & Direction.EAST) !== 0) endpoints.push({ bit: Direction.EAST, x: centerX + reach, y: centerY, angle: 0 })
  if ((mask & Direction.SOUTH) !== 0) endpoints.push({ bit: Direction.SOUTH, x: centerX, y: centerY + reach, angle: Math.PI / 2 })
  if ((mask & Direction.WEST) !== 0) endpoints.push({ bit: Direction.WEST, x: centerX - reach, y: centerY, angle: Math.PI })
  return endpoints
}

function areOpposite(first, second) {
  return (first === Direction.NORTH && second === Direction.SOUTH) || (first === Direction.SOUTH && second === Direction.NORTH) || (first === Direction.EAST && second === Direction.WEST) || (first === Direction.WEST && second === Direction.EAST)
}

function drawCouplers(centerX, centerY, mask, reach, skin) {
  for (const endpoint of conduitEndpoints(centerX, centerY, mask, reach - 3)) {
    context.save()
    context.translate(endpoint.x, endpoint.y)
    context.rotate(endpoint.angle)
    context.fillStyle = skin.copper
    context.strokeStyle = 'rgba(18,10,5,0.88)'
    context.lineWidth = 1.4
    roundRect(-5, -12, 10, 24, 3)
    context.fill()
    context.stroke()
    context.fillStyle = 'rgba(255,232,187,0.48)'
    context.fillRect(-2.7, -9, 1.4, 18)
    context.fillStyle = 'rgba(68,35,12,0.5)'
    context.fillRect(2.1, -9, 1.2, 18)
    context.restore()
  }
}

function drawJunctionHub(centerX, centerY, mask, skin) {
  const endpoints = conduitEndpoints(centerX, centerY, mask, 1)
  if (endpoints.length < 3) return
  const hub = context.createRadialGradient(centerX - 3, centerY - 4, 1, centerX, centerY, 12)
  hub.addColorStop(0, skin.pipeLight)
  hub.addColorStop(0.45, skin.pipeMid)
  hub.addColorStop(1, skin.pipeDark)
  context.fillStyle = hub
  context.strokeStyle = skin.copper
  context.lineWidth = 2
  context.beginPath()
  context.arc(centerX, centerY, 10.5, 0, Math.PI * 2)
  context.fill()
  context.stroke()
  context.fillStyle = '#111820'
  context.beginPath()
  context.arc(centerX, centerY, 3.4, 0, Math.PI * 2)
  context.fill()
}

function drawBolt(x, y, radius, color) {
  context.fillStyle = color
  context.strokeStyle = 'rgba(0,0,0,0.82)'
  context.lineWidth = 0.8
  context.beginPath()
  context.arc(x, y, radius, 0, Math.PI * 2)
  context.fill()
  context.stroke()
  context.fillStyle = 'rgba(255,255,255,0.45)'
  context.beginPath()
  context.arc(x - radius * 0.28, y - radius * 0.3, Math.max(0.6, radius * 0.2), 0, Math.PI * 2)
  context.fill()
  context.strokeStyle = 'rgba(25,30,36,0.85)'
  context.beginPath()
  context.moveTo(x - radius * 0.5, y)
  context.lineTo(x + radius * 0.5, y)
  context.stroke()
}

function drawBurnHead(row, col, mask, centerX, centerY) {
  const skin = getSkin(state.skinKey)
  const positions = burnHeadPositions(row, col, mask, centerX, centerY)
  for (const position of positions) drawBurnOrb(position.x, position.y, skin)
}

function burnHeadPositions(row, col, mask, centerX, centerY) {
  const reach = layout.cell / 2 - 9
  const endpoints = conduitEndpoints(centerX, centerY, mask, reach)
  const incoming = endpoints.filter((endpoint) => burnComesFrom(row, col, endpoint.bit))
  const outgoing = endpoints.filter((endpoint) => burnGoesTo(row, col, endpoint.bit))
  const progress = Math.max(0, Math.min(1, state.burn?.stageProgress ?? 0))
  const center = { x: centerX, y: centerY }

  if (incoming.length === 1 && outgoing.length === 1) return [quadraticPoint(incoming[0], center, outgoing[0], progress)]
  if (progress < 0.5 && incoming.length > 0) return incoming.map((endpoint) => lerpPoint(endpoint, center, progress * 2))
  if (outgoing.length > 0) return outgoing.map((endpoint) => lerpPoint(center, endpoint, Math.max(0, (progress - 0.5) * 2)))
  if (incoming.length > 0) return incoming.map((endpoint) => lerpPoint(endpoint, center, progress))
  return [center]
}

function burnComesFrom(row, col, bit) {
  if (bit === Direction.WEST && col === 0) return true
  const neighbor = neighborFor(row, col, bit)
  return neighbor ? state.powered.has(`${neighbor.row}:${neighbor.col}`) : false
}

function burnGoesTo(row, col, bit) {
  if (bit === Direction.EAST && col === layout.cols - 1 && state.burn?.launch.rocketRows.includes(row)) return true
  const neighbor = neighborFor(row, col, bit)
  if (!neighbor) return false
  const nextStage = state.burn?.launch.burnStages[(state.burn?.activeStage ?? -1) + 1] ?? []
  return nextStage.some((cell) => cell.row === neighbor.row && cell.col === neighbor.col)
}

function neighborFor(row, col, bit) {
  if (bit === Direction.NORTH) return row > 0 ? { row: row - 1, col } : null
  if (bit === Direction.EAST) return col < layout.cols - 1 ? { row, col: col + 1 } : null
  if (bit === Direction.SOUTH) return row < layout.rows - 1 ? { row: row + 1, col } : null
  if (bit === Direction.WEST) return col > 0 ? { row, col: col - 1 } : null
  return null
}

function quadraticPoint(start, control, end, t) {
  const inverse = 1 - t
  return {
    x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
    y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y,
  }
}

function lerpPoint(start, end, t) {
  return { x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t }
}

function easeOut(value) {
  const clamped = Math.min(1, Math.max(0, value))
  return 1 - (1 - clamped) * (1 - clamped)
}

function rocketFlightTarget(row) {
  return { x: 585 + (row % 3) * 55, y: 70 + row * 25 }
}

function drawBurnOrb(x, y, skin) {
  const pulse = 1 + Math.sin(performance.now() * 0.02) * 0.1
  context.save()
  const aura = context.createRadialGradient(x, y, 1, x, y, 17 * pulse)
  aura.addColorStop(0, '#ffffff')
  aura.addColorStop(0.2, skin.poweredCore)
  aura.addColorStop(0.52, skin.powered)
  aura.addColorStop(1, 'rgba(255,120,30,0)')
  context.fillStyle = aura
  context.beginPath()
  context.arc(x, y, 17 * pulse, 0, Math.PI * 2)
  context.fill()
  context.strokeStyle = skin.poweredCore
  context.lineWidth = 1.7
  for (let index = 0; index < 5; index += 1) {
    const angle = performance.now() * 0.005 + index * Math.PI * 0.4
    context.beginPath()
    context.moveTo(x + Math.cos(angle) * 7, y + Math.sin(angle) * 7)
    context.lineTo(x + Math.cos(angle) * 14, y + Math.sin(angle) * 14)
    context.stroke()
  }
  context.restore()
}

function drawSources() {
  const skin = getSkin(state.skinKey)
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    const hot = state.powered.has(`${row}:0`) || state.burning.has(`${row}:0`)

    context.lineCap = 'round'
    context.strokeStyle = '#05080d'
    context.lineWidth = 18
    context.beginPath()
    context.moveTo(71, y)
    context.lineTo(layout.boardX + 2, y)
    context.stroke()
    const connector = context.createLinearGradient(71, y - 8, 71, y + 8)
    connector.addColorStop(0, skin.pipeLight)
    connector.addColorStop(0.45, skin.pipeMid)
    connector.addColorStop(1, skin.pipeDark)
    context.strokeStyle = connector
    context.lineWidth = 11
    context.beginPath()
    context.moveTo(71, y)
    context.lineTo(layout.boardX + 2, y)
    context.stroke()

    const housing = context.createRadialGradient(51, y - 6, 2, 57, y, 21)
    housing.addColorStop(0, skin.pipeLight)
    housing.addColorStop(0.35, skin.pipeMid)
    housing.addColorStop(0.68, skin.pipeDark)
    housing.addColorStop(1, '#05080d')
    context.fillStyle = housing
    context.strokeStyle = hot ? skin.powered : skin.copper
    context.lineWidth = hot ? 2.8 : 1.8
    context.beginPath()
    context.arc(57, y, 20, 0, Math.PI * 2)
    context.fill()
    context.stroke()

    context.strokeStyle = 'rgba(185,205,225,0.35)'
    context.lineWidth = 1
    context.beginPath()
    context.arc(57, y, 15, 0, Math.PI * 2)
    context.stroke()
    for (let index = 0; index < 6; index += 1) {
      const angle = index * Math.PI / 3
      drawBolt(57 + Math.cos(angle) * 16, y + Math.sin(angle) * 16, 1.8, skin.bolt)
    }

    const core = context.createRadialGradient(54, y - 3, 1, 57, y, hot ? 13 : 10)
    core.addColorStop(0, '#ffffff')
    core.addColorStop(0.2, skin.poweredCore)
    core.addColorStop(0.5, hot ? skin.powered : skin.spark)
    core.addColorStop(1, 'rgba(255,110,35,0)')
    context.fillStyle = core
    context.beginPath()
    context.arc(57, y, hot ? 13 : 10, 0, Math.PI * 2)
    context.fill()
    context.strokeStyle = hot ? skin.poweredCore : skin.spark
    context.lineWidth = 1.2
    for (let ray = 0; ray < 4; ray += 1) {
      const angle = ray * Math.PI / 2 + Math.PI / 4
      context.beginPath()
      context.moveTo(57 + Math.cos(angle) * 5, y + Math.sin(angle) * 5)
      context.lineTo(57 + Math.cos(angle) * 11, y + Math.sin(angle) * 11)
      context.stroke()
    }
  }
}

function drawRockets() {
  const skin = getSkin(state.skinKey)
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    const launching = state.launchingRows.has(row)
    const hot = launching || state.powered.has(`${row}:${layout.cols - 1}`)
    const launchProgress = launching ? Math.min(1, state.burn?.hold / burnTiming.rocketFlightSeconds ?? 0) : 0
    const flightProgress = Math.min(1, launchProgress / 0.62)
    const burstProgress = Math.min(1, Math.max(0, (launchProgress - burnTiming.fireworkStartProgress) / (1 - burnTiming.fireworkStartProgress)))
    const target = rocketFlightTarget(row)
    const rocketPosition = launching
      ? lerpPoint({ x: 718, y }, target, easeOut(flightProgress))
      : { x: 718, y }

    context.lineCap = 'round'
    context.strokeStyle = '#05080d'
    context.lineWidth = 19
    context.beginPath()
    context.moveTo(layout.boardX + layout.boardSize - 2, y)
    context.lineTo(694, y)
    context.stroke()
    const feed = context.createLinearGradient(674, y - 8, 674, y + 8)
    feed.addColorStop(0, skin.pipeLight)
    feed.addColorStop(0.48, skin.pipeMid)
    feed.addColorStop(1, skin.pipeDark)
    context.strokeStyle = feed
    context.lineWidth = 11
    context.beginPath()
    context.moveTo(layout.boardX + layout.boardSize - 2, y)
    context.lineTo(694, y)
    context.stroke()

    const socket = context.createRadialGradient(688, y - 5, 1, 692, y, 19)
    socket.addColorStop(0, skin.pipeLight)
    socket.addColorStop(0.42, skin.pipeMid)
    socket.addColorStop(0.75, skin.pipeDark)
    socket.addColorStop(1, '#05080d')
    context.fillStyle = socket
    context.strokeStyle = hot ? skin.powered : skin.copper
    context.lineWidth = hot ? 2.8 : 1.8
    context.beginPath()
    context.arc(692, y, 18, 0, Math.PI * 2)
    context.fill()
    context.stroke()
    context.fillStyle = hot ? skin.powered : '#0e151e'
    context.beginPath()
    context.arc(692, y, 7, 0, Math.PI * 2)
    context.fill()

    if (launching && burstProgress >= burnTiming.rocketVisibleUntilBurstProgress) continue

    context.save()
    context.translate(rocketPosition.x, rocketPosition.y)
    if (launching) drawRocketFlame(flightProgress, skin)

    const hull = context.createLinearGradient(-14, 0, 14, 0)
    hull.addColorStop(0, skin.rocketDark)
    hull.addColorStop(0.24, skin.rocket)
    hull.addColorStop(0.5, skin.rocketLight)
    hull.addColorStop(0.72, skin.rocket)
    hull.addColorStop(1, skin.rocketDark)
    context.fillStyle = hull
    context.strokeStyle = skin.rocketDark
    context.lineWidth = 1.3
    context.beginPath()
    context.moveTo(0, -30)
    context.bezierCurveTo(10, -23, 13, -7, 12, 9)
    context.lineTo(8, 21)
    context.lineTo(-8, 21)
    context.lineTo(-12, 9)
    context.bezierCurveTo(-13, -7, -10, -23, 0, -30)
    context.closePath()
    context.fill()
    context.stroke()

    context.fillStyle = skin.rocketDark
    context.beginPath()
    context.moveTo(-9, 9)
    context.lineTo(-18, 22)
    context.lineTo(-8, 18)
    context.closePath()
    context.fill()
    context.beginPath()
    context.moveTo(9, 9)
    context.lineTo(18, 22)
    context.lineTo(8, 18)
    context.closePath()
    context.fill()

    const windowGlow = context.createRadialGradient(-2, -9, 1, 0, -8, 7)
    windowGlow.addColorStop(0, '#e9ffff')
    windowGlow.addColorStop(0.35, skin.glass)
    windowGlow.addColorStop(1, '#0c5f91')
    context.fillStyle = windowGlow
    context.strokeStyle = '#d6f6ff'
    context.lineWidth = 1.1
    context.beginPath()
    context.arc(0, -8, 6, 0, Math.PI * 2)
    context.fill()
    context.stroke()
    context.fillStyle = 'rgba(255,255,255,0.55)'
    context.beginPath()
    context.ellipse(-2, -10, 1.8, 1.2, -0.5, 0, Math.PI * 2)
    context.fill()

    context.fillStyle = '#252b35'
    context.strokeStyle = skin.copper
    context.lineWidth = 1.2
    roundRect(-7, 18, 14, 6, 2)
    context.fill()
    context.stroke()
    context.restore()
  }
}

function drawRocketFlame(progress, skin) {
  context.save()
  context.globalAlpha = 0.72 + progress * 0.28
  const outer = context.createLinearGradient(0, 21, 0, 49 + progress * 14)
  outer.addColorStop(0, '#fff5b2')
  outer.addColorStop(0.35, skin.powered)
  outer.addColorStop(0.75, skin.spark)
  outer.addColorStop(1, 'rgba(255,70,110,0)')
  context.fillStyle = outer
  context.beginPath()
  context.moveTo(-7, 22)
  context.quadraticCurveTo(-11, 34, 0, 50 + progress * 13)
  context.quadraticCurveTo(11, 34, 7, 22)
  context.closePath()
  context.fill()
  context.fillStyle = '#fff8dc'
  context.beginPath()
  context.moveTo(-3, 23)
  context.quadraticCurveTo(-5, 31, 0, 40 + progress * 8)
  context.quadraticCurveTo(5, 31, 3, 23)
  context.closePath()
  context.fill()
  context.restore()
}

function spawnBurnSparks(stage) {
  const skin = getSkin(state.skinKey)
  for (const { row, col } of stage) {
    const x = layout.boardX + col * layout.cell + layout.cell / 2
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    for (let index = 0; index < 5; index += 1) {
      const angle = Math.random() * Math.PI * 2
      const speed = 20 + Math.random() * 45
      particles.push({ x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: 0.25 + Math.random() * 0.25, age: 0, gravity: 12, size: 2 + Math.random() * 2, color: skin.powered })
    }
  }
}

function spawnFirework(row, variant) {
  const skin = getSkin(state.skinKey)
  const center = rocketFlightTarget(row)
  const colors = [skin.poweredCore, skin.powered, skin.rocketLight, '#ffffff']
  for (let index = 0; index < 22; index += 1) {
    const angle = Math.PI * 2 * index / 22 + variant * 0.37
    const speed = 105 + ((index * 17 + variant * 11) % 29) * 4.2
    particles.push({
      x: center.x,
      y: center.y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: 0.88 + (index % 5) * 0.055,
      age: 0,
      gravity: 42,
      size: index % 4 === 0 ? 3.4 : 2.2,
      color: colors[index % colors.length],
    })
  }
}

function updateParticles(deltaSeconds) {
  for (const particle of particles) {
    particle.age += deltaSeconds
    particle.x += particle.vx * deltaSeconds
    particle.y += particle.vy * deltaSeconds
    particle.vy += particle.gravity * deltaSeconds
  }
  for (let index = particles.length - 1; index >= 0; index -= 1) if (particles[index].age >= particles[index].life) particles.splice(index, 1)
}

function drawParticles() {
  for (const particle of particles) {
    const alpha = Math.max(0, 1 - particle.age / particle.life)
    context.globalAlpha = alpha
    context.fillStyle = particle.color
    context.beginPath()
    context.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2)
    context.fill()
    context.globalAlpha = alpha * 0.4
    context.beginPath()
    context.arc(particle.x, particle.y, particle.size * 2.1, 0, Math.PI * 2)
    context.fill()
  }
  context.globalAlpha = 1
}

function stageSet(stages, count) {
  const cells = []
  for (let index = 0; index < count; index += 1) cells.push(...stages[index])
  return cellSet(cells)
}

function cellSet(cells) {
  return new Set(cells.map(({ row, col }) => `${row}:${col}`))
}

function roundRect(x, y, width, height, radius) {
  context.beginPath()
  if (typeof context.roundRect === 'function') {
    context.roundRect(x, y, width, height, radius)
    return
  }
  const safeRadius = Math.max(0, Math.min(radius, width / 2, height / 2))
  context.moveTo(x + safeRadius, y)
  context.lineTo(x + width - safeRadius, y)
  context.quadraticCurveTo(x + width, y, x + width, y + safeRadius)
  context.lineTo(x + width, y + height - safeRadius)
  context.quadraticCurveTo(x + width, y + height, x + width - safeRadius, y + height)
  context.lineTo(x + safeRadius, y + height)
  context.quadraticCurveTo(x, y + height, x, y + height - safeRadius)
  context.lineTo(x, y + safeRadius)
  context.quadraticCurveTo(x, y, x + safeRadius, y)
  context.closePath()
}

function ensureAudio() {
  if (!audioContext) {
    const AudioContextType = globalThis.AudioContext ?? globalThis.webkitAudioContext
    if (!AudioContextType) return
    audioContext = new AudioContextType()
  }
  if (audioContext.state === 'suspended') void audioContext.resume()
  if (!ambientStarted) startAmbientMusic()
  setAmbientEnergy(state.combo, Boolean(state.burn))
}

function bootstrapAmbientAudio() {
  if (!state?.musicEnabled) return
  ensureAudio()
}

function startAmbientMusic() {
  if (!audioContext || ambientStarted) return
  const source = audioContext.createBufferSource()
  source.buffer = makeAmbientBuffer(audioContext)
  source.loop = true
  ambientGain = audioContext.createGain()
  source.connect(ambientGain).connect(audioContext.destination)
  ambientGain.gain.value = 0
  source.start()
  ambientNodes.push(source)
  ambientStarted = true
}

function makeAmbientBuffer(audio) {
  const duration = 8
  const frameCount = Math.floor(audio.sampleRate * duration)
  const buffer = audio.createBuffer(1, frameCount, audio.sampleRate)
  const channel = buffer.getChannelData(0)
  const roots = [110, 130.81, 146.83, 98]
  for (let frame = 0; frame < frameCount; frame += 1) {
    const time = frame / audio.sampleRate
    const root = roots[Math.min(roots.length - 1, Math.floor(time / 2))]
    const breath = 0.72 + 0.28 * Math.sin(Math.PI * time / 2)
    const pad = Math.sin(2 * Math.PI * root * time)
      + 0.48 * Math.sin(2 * Math.PI * root * 1.5 * time + 0.7)
      + 0.24 * Math.sin(2 * Math.PI * root * 2 * time + 1.4)
    const shimmer = 0.15 * Math.sin(2 * Math.PI * 0.19 * time) * Math.sin(2 * Math.PI * root * 4 * time)
    channel[frame] = (pad * 0.068 + shimmer * 0.030) * breath
  }
  return buffer
}

function setAmbientEnergy(combo, igniting) {
  if (!audioContext || !ambientGain) return
  const comboLift = Math.min(combo, 8) * 0.02
  const target = state.musicEnabled ? Math.min(0.88, 0.62 + comboLift + (igniting ? 0.10 : 0)) : 0
  ambientGain.gain.cancelScheduledValues(audioContext.currentTime)
  ambientGain.gain.linearRampToValueAtTime(target, audioContext.currentTime + 0.28)
}

function playTone(frequency, duration, type, gainValue) {
  if (!audioContext || !state.effectsEnabled) return
  const oscillator = audioContext.createOscillator()
  const gain = audioContext.createGain()
  oscillator.type = type
  oscillator.frequency.value = frequency
  gain.gain.setValueAtTime(gainValue, audioContext.currentTime)
  gain.gain.exponentialRampToValueAtTime(0.0001, audioContext.currentTime + duration)
  oscillator.connect(gain).connect(audioContext.destination)
  oscillator.start()
  oscillator.stop(audioContext.currentTime + duration)
}

function playPlacementSound(quality) {
  const normalized = Math.min(1, Math.max(0, quality))
  playTone(240 + normalized * 420, 0.045, 'sine', 0.05)
}

function playLaunchSound(combo) {
  ensureAudio()
  playTone(430 + Math.min(combo, 8) * 55, 0.16, 'sine', 0.06)
}

function playFireworkSound(count) {
  ensureAudio()
  const lift = Math.min(count, 4) * 26
  for (const frequency of [659.25 + lift, 783.99 + lift, 1046.5 + lift]) {
    playTone(frequency, 0.32, 'sine', 0.035)
  }
}

function vibrate(duration) {
  if (state.hapticsEnabled && 'vibrate' in navigator) navigator.vibrate(duration)
}

function frame(now) {
  const deltaSeconds = Math.min(0.05, (now - lastFrame) / 1000)
  lastFrame = now
  if (state.uiPaused) {
    requestAnimationFrame(frame)
    return
  }
  if (state.resolving) updateBurn(deltaSeconds)
  if (!state.paused && !state.gameOver && !state.resolving && Number.isFinite(state.timeLeft)) {
    state.timeLeft -= deltaSeconds
    if (state.timeLeft <= 0) endGame()
  }
  updateParticles(deltaSeconds)
  updateHud()
  render()
  requestAnimationFrame(frame)
}

function configureCanvasResolution() {
  const ratio = Math.min(2, window.devicePixelRatio || 1)
  canvas.width = Math.round(layout.canvasWidth * ratio)
  canvas.height = Math.round(layout.canvasHeight * ratio)
  context.setTransform(ratio, 0, 0, ratio, 0, 0)
}

canvas.addEventListener('pointerdown', handleBoardTap)
elements.pause.addEventListener('click', togglePause)
elements.restart.addEventListener('click', () => newGame())
elements.dailyButton.addEventListener('click', startDailyRun)
elements.helpButton.addEventListener('click', () => openTutorial(0))
elements.settingsButton.addEventListener('click', openSettingsScreen)
elements.plusButton.addEventListener('click', openPlusScreen)
elements.tutorialSkip.addEventListener('click', () => closeTutorial(true))
elements.tutorialPrev.addEventListener('click', previousTutorialStep)
elements.tutorialNext.addEventListener('click', nextTutorialStep)
elements.plusClose.addEventListener('click', closePlusScreen)
elements.plusScreen.addEventListener('click', handlePlusClick)
elements.settingsClose.addEventListener('click', closeSettingsScreen)
elements.languageSelect.addEventListener('change', (event) => setLanguage(event.target.value))
elements.musicToggle.addEventListener('change', (event) => setMusicEnabled(event.target.checked))
elements.effectsToggle.addEventListener('change', (event) => setEffectsEnabled(event.target.checked))
elements.hapticsToggle.addEventListener('change', (event) => setHapticsEnabled(event.target.checked))
window.addEventListener('resize', configureCanvasResolution)
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) bootstrapAmbientAudio()
  if (document.hidden && state && !state.gameOver && !state.paused && !state.resolving && !state.uiPaused) togglePause()
})
window.addEventListener('pointerdown', bootstrapAmbientAudio, { capture: true, passive: true })
window.addEventListener('keydown', bootstrapAmbientAudio, { capture: true })

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return
  if (!elements.settingsScreen.hidden) closeSettingsScreen()
  else if (!elements.plusScreen.hidden) closePlusScreen()
  else if (!elements.tutorial.hidden) closeTutorial(false)
})

configureCanvasResolution()
newGame()
bootstrapAmbientAudio()
render()
requestAnimationFrame(() => requestAnimationFrame(dismissStartupSplash))
requestAnimationFrame(frame)
