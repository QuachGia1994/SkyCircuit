import { Board, Direction } from './core/board.js'
import { plusBenefits, plusRoadmap, tutorialSteps } from './data/content.js'
import { getMode, modeList } from './data/modes.js'
import { getSkin, skinList } from './data/skins.js'

const canvas = document.querySelector('#game')
const context = canvas.getContext('2d')
const elements = {
  score: document.querySelector('#score'),
  combo: document.querySelector('#combo'),
  rockets: document.querySelector('#rockets'),
  target: document.querySelector('#target'),
  time: document.querySelector('#time'),
  best: document.querySelector('#best'),
  level: document.querySelector('#level'),
  modeLabel: document.querySelector('#mode-label'),
  status: document.querySelector('#status'),
  overlay: document.querySelector('#overlay'),
  overlayTitle: document.querySelector('#overlay-title'),
  overlayCopy: document.querySelector('#overlay-copy'),
  burnBanner: document.querySelector('#burn-banner'),
  pause: document.querySelector('#pause'),
  restart: document.querySelector('#restart'),
  helpButton: document.querySelector('#help-button'),
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
  skinGrid: document.querySelector('#skin-grid'),
  modeGrid: document.querySelector('#mode-grid'),
  benefitGrid: document.querySelector('#benefit-grid'),
  roadmap: document.querySelector('#roadmap'),
  startupSplash: document.querySelector('#startup-splash'),
}

const layout = Object.freeze({ canvasWidth: 768, canvasHeight: 720, rows: 8, cols: 8, cell: 72, boardX: 96, boardY: 72, boardSize: 576 })
const burnTiming = Object.freeze({ stageSeconds: 0.24, rocketHoldSeconds: 0.72 })
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
const particles = []
const startupShownAt = performance.now()

function createState(modeKey = localStorage.getItem('skycircuit.mode') ?? 'classic') {
  const mode = getMode(modeKey)
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
  }
}

function newGame(modeKey = state?.modeKey ?? localStorage.getItem('skycircuit.mode') ?? 'classic') {
  const skinKey = state?.skinKey ?? localStorage.getItem('skycircuit.skin') ?? 'classic'
  board = new Board(layout.rows, layout.cols, Math.random, tilePool)
  state = createState(modeKey)
  state.skinKey = getSkin(skinKey).key
  particles.length = 0
  hideOverlay()
  hideBurnBanner()
  elements.pause.textContent = 'Pause'
  applySkin(state.skinKey, false)
  elements.status.textContent = `${getMode(state.modeKey).name} mode. Rotate tiles and connect a spark to a rocket.`
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
  setText(elements.modeLabel, getMode(state.modeKey).name)
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
  playTone(360, 0.035, 'square', 0.025)
  vibrate(8)
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
  state.burn = { launch, elapsed: 0, activeStage: -1, stageProgress: 0, phase: 'burn', hold: 0 }
  elements.status.textContent = 'Circuit complete. Ignition is traveling through the connected pipes.'
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
  launch.rocketRows.forEach((row, index) => spawnFirework(row, index))
  playLaunchSound(launch.rocketRows.length)
  vibrate(Math.min(95, 26 + launch.rocketRows.length * 14))
  elements.status.textContent = launch.rocketRows.length > 1 ? `${launch.rocketRows.length} rockets launched. Combo ×${state.combo}.` : `Rocket launched. Combo ×${state.combo}.`
}

function updateRocketHold(deltaSeconds) {
  state.burn.hold += deltaSeconds
  if (state.burn.hold >= burnTiming.rocketHoldSeconds) finishLaunch(state.burn.launch)
}

function applyLaunchScore(launch) {
  const rocketCount = launch.rocketRows.length
  const multiRocketBonus = Math.max(0, rocketCount - 1) * 175
  const comboBonus = Math.max(0, state.combo - 1) * 125
  state.score += rocketCount * 100 + multiRocketBonus + comboBonus + launch.burned.length * 5
  state.launched += rocketCount
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
  showOverlay(`Level ${state.level}`, `${mode.name} circuit refreshed. Keep the sky lit.`, 820)
  updateHud()
}

function setGameMode(modeKey) {
  const mode = getMode(modeKey)
  localStorage.setItem('skycircuit.mode', mode.key)
  closePlusScreen()
  newGame(mode.key)
  elements.status.textContent = `${mode.name} mode started. ${mode.description}`
}

function togglePause() {
  if (state.gameOver || state.resolving || state.uiPaused) return
  state.paused = !state.paused
  elements.pause.textContent = state.paused ? 'Resume' : 'Pause'
  elements.status.textContent = state.paused ? 'Game paused.' : 'Game resumed.'
  if (state.paused) showOverlay('Paused', 'Resume when ready.')
  else hideOverlay()
}

function endGame() {
  state.gameOver = true
  state.timeLeft = 0
  updateHud()
  showOverlay('Show over', `Score ${state.score}. Best ${state.best}.`)
  elements.status.textContent = 'Time expired. Start a new game to try again.'
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
  const delay = Math.max(0, 720 - elapsed)
  setTimeout(() => {
    if (elements.startupSplash.hidden) return
    elements.startupSplash.classList.add('is-hiding')
    setTimeout(() => { elements.startupSplash.hidden = true }, 300)
  }, delay)
}

function openTutorial(step = 0) {
  if (state.resolving) {
    elements.status.textContent = 'Watch the ignition finish before opening the tutorial.'
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
  elements.tutorialEyebrow.textContent = step.eyebrow
  elements.tutorialTitle.textContent = step.title
  elements.tutorialBody.textContent = step.body
  elements.tutorialDots.innerHTML = tutorialSteps.map((_, index) => `<i class="${index === state.tutorialStep ? 'active' : ''}"></i>`).join('')
  elements.tutorialPrev.hidden = state.tutorialStep === 0
  elements.tutorialNext.textContent = state.tutorialStep === tutorialSteps.length - 1 ? 'Got it' : 'Next'
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
    elements.status.textContent = 'Watch the ignition finish before opening SkyCircuit Plus.'
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

function syncUiPause() {
  state.uiPaused = !elements.tutorial.hidden || !elements.plusScreen.hidden
  document.body.classList.toggle('modal-open', state.uiPaused)
}

function renderPlusScreen() {
  renderSkinSelection()
  elements.modeGrid.innerHTML = modeList.map((mode) => modeCardMarkup(mode, mode.key === state.modeKey)).join('')
  if (elements.benefitGrid.childElementCount === 0) {
    elements.benefitGrid.innerHTML = plusBenefits.map((benefit) => `<article class="benefit-card"><span class="benefit-icon">${benefit.icon}</span><div><strong>${benefit.title}</strong><p>${benefit.body}</p></div></article>`).join('')
  }
  if (elements.roadmap.childElementCount === 0) {
    elements.roadmap.innerHTML = plusRoadmap.map((item) => `<span class="roadmap-item"><b>${item.label}</b><span>${item.status}</span></span>`).join('')
  }
}

function renderSkinSelection() {
  const activeSkin = getSkin(state.skinKey)
  elements.activeSkinName.textContent = activeSkin.name
  elements.skinGrid.innerHTML = skinList.map((skin) => skinCardMarkup(skin, skin.key === activeSkin.key)).join('')
}

function skinCardMarkup(skin, active) {
  const badge = skin.plus ? 'PLUS PREVIEW' : 'FREE'
  const style = `--preview-top:${skin.backgroundTop};--preview-bottom:${skin.backgroundBottom};--preview-conduit:${skin.conduit};--preview-powered:${skin.powered};--preview-rocket:${skin.rocket}`
  return `<button class="skin-card ${active ? 'active' : ''}" type="button" data-skin="${skin.key}" style="${style}"><span class="skin-preview"></span><strong>${skin.name}</strong><small>${badge}</small></button>`
}

function modeCardMarkup(mode, active) {
  const badge = mode.plus ? 'PLUS PREVIEW' : 'FREE'
  return `<button class="mode-card ${active ? 'active' : ''}" type="button" data-mode="${mode.key}"><strong>${mode.name}</strong><span>${mode.description}</span><small>${badge}</small></button>`
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
    const launchProgress = launching ? Math.min(1, state.burn?.hold / 0.42 ?? 0) : 0

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

    context.save()
    context.translate(718, y - launchProgress * 27)
    if (launching) drawRocketFlame(launchProgress, skin)

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
  const y = layout.boardY + row * layout.cell + layout.cell / 2
  for (let index = 0; index < 30; index += 1) {
    const angle = Math.PI * 2 * index / 30 + variant * 0.17
    const speed = 75 + Math.random() * 135
    particles.push({ x: 742, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: 0.8 + Math.random() * 0.35, age: 0, gravity: 55, size: 3.5, color: skin.powered })
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
  if (!audioContext) audioContext = new AudioContext()
  if (audioContext.state === 'suspended') audioContext.resume()
}

function playTone(frequency, duration, type, gainValue) {
  if (!audioContext) return
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

function playLaunchSound(count) {
  ensureAudio()
  playTone(250 + count * 30, 0.16, 'triangle', 0.05)
  setTimeout(() => playTone(520 + count * 45, 0.18, 'sine', 0.04), 70)
}

function vibrate(duration) {
  if ('vibrate' in navigator) navigator.vibrate(duration)
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
elements.helpButton.addEventListener('click', () => openTutorial(0))
elements.plusButton.addEventListener('click', openPlusScreen)
elements.tutorialSkip.addEventListener('click', () => closeTutorial(true))
elements.tutorialPrev.addEventListener('click', previousTutorialStep)
elements.tutorialNext.addEventListener('click', nextTutorialStep)
elements.plusClose.addEventListener('click', closePlusScreen)
elements.plusScreen.addEventListener('click', handlePlusClick)
window.addEventListener('resize', configureCanvasResolution)
document.addEventListener('visibilitychange', () => {
  if (document.hidden && state && !state.gameOver && !state.paused && !state.resolving && !state.uiPaused) togglePause()
})

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return
  if (!elements.plusScreen.hidden) closePlusScreen()
  else if (!elements.tutorial.hidden) closeTutorial(false)
})

configureCanvasResolution()
newGame()
render()
requestAnimationFrame(() => requestAnimationFrame(dismissStartupSplash))
requestAnimationFrame(frame)
