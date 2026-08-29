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
}

const layout = Object.freeze({ canvasWidth: 768, canvasHeight: 720, rows: 8, cols: 8, cell: 72, boardX: 96, boardY: 72, boardSize: 576 })
const burnTiming = Object.freeze({ stageSeconds: 0.18, rocketHoldSeconds: 0.58 })
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
  elements.score.textContent = String(state.score)
  elements.combo.textContent = `×${state.combo}`
  elements.rockets.textContent = String(state.launched)
  elements.target.textContent = String(state.target)
  elements.time.textContent = Number.isFinite(state.timeLeft) ? String(Math.max(0, Math.ceil(state.timeLeft))) : '∞'
  elements.best.textContent = String(state.best)
  elements.level.textContent = String(state.level)
  elements.modeLabel.textContent = getMode(state.modeKey).name
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
}

function renderPlusScreen() {
  const activeSkin = getSkin(state.skinKey)
  elements.activeSkinName.textContent = activeSkin.name
  elements.skinGrid.innerHTML = skinList.map((skin) => skinCardMarkup(skin, skin.key === activeSkin.key)).join('')
  elements.modeGrid.innerHTML = modeList.map((mode) => modeCardMarkup(mode, mode.key === state.modeKey)).join('')
  elements.benefitGrid.innerHTML = plusBenefits.map((benefit) => `<article class="benefit-card"><span class="benefit-icon">${benefit.icon}</span><div><strong>${benefit.title}</strong><p>${benefit.body}</p></div></article>`).join('')
  elements.roadmap.innerHTML = plusRoadmap.map((item) => `<span class="roadmap-item"><b>${item.label}</b><span>${item.status}</span></span>`).join('')
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
  const skinButton = event.target.closest('[data-skin]')
  if (skinButton) {
    applySkin(skinButton.dataset.skin)
    renderPlusScreen()
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
}

function render() {
  drawBackground()
  drawSources()
  drawBoard()
  drawRockets()
  drawParticles()
}

function drawBackground() {
  const skin = getSkin(state.skinKey)
  const gradient = context.createLinearGradient(0, 0, 0, layout.canvasHeight)
  gradient.addColorStop(0, skin.backgroundTop)
  gradient.addColorStop(1, skin.backgroundBottom)
  context.fillStyle = gradient
  context.fillRect(0, 0, layout.canvasWidth, layout.canvasHeight)
  context.fillStyle = '#ffffff12'
  for (let index = 0; index < 52; index += 1) context.fillRect((index * 137) % layout.canvasWidth, (index * 83) % layout.canvasHeight, 2, 2)
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
  context.fillStyle = skin.tile
  context.strokeStyle = powered || burning ? skin.powered : skin.tileBorder
  context.lineWidth = powered || burning ? 2.7 : 2
  roundRect(x + 3, y + 3, layout.cell - 6, layout.cell - 6, 12)
  context.fill()
  context.stroke()
  drawConduit(x + layout.cell / 2, y + layout.cell / 2, mask, powered, burning)
  if (burning) drawBurnHead(x + layout.cell / 2, y + layout.cell / 2)
}

function drawConduit(centerX, centerY, mask, powered, burning) {
  const skin = getSkin(state.skinKey)
  const reach = layout.cell / 2 - 7
  context.lineCap = 'round'
  context.lineWidth = 16
  context.strokeStyle = '#06101d'
  drawMaskLines(centerX, centerY, mask, reach)
  context.lineWidth = 7
  context.strokeStyle = skin.conduit
  drawMaskLines(centerX, centerY, mask, reach)
  context.fillStyle = skin.conduit
  context.beginPath()
  context.arc(centerX, centerY, 7, 0, Math.PI * 2)
  context.fill()
  if (!powered && !burning) return

  context.save()
  context.globalAlpha = powered ? 1 : 0.38 + state.burn.stageProgress * 0.62
  context.shadowBlur = powered ? 17 : 25
  context.shadowColor = skin.powered
  context.lineWidth = powered ? 8 : 9
  context.strokeStyle = skin.powered
  drawMaskLines(centerX, centerY, mask, reach)
  context.fillStyle = skin.powered
  context.beginPath()
  context.arc(centerX, centerY, powered ? 8 : 9, 0, Math.PI * 2)
  context.fill()
  context.restore()
}

function drawBurnHead(centerX, centerY) {
  const skin = getSkin(state.skinKey)
  const pulse = 1 + Math.sin(performance.now() * 0.022) * 0.16
  context.save()
  context.shadowBlur = 30
  context.shadowColor = skin.powered
  context.fillStyle = '#fff7c2'
  context.beginPath()
  context.arc(centerX, centerY, 9 * pulse, 0, Math.PI * 2)
  context.fill()
  context.strokeStyle = skin.spark
  context.lineWidth = 2
  for (let index = 0; index < 4; index += 1) {
    const angle = performance.now() * 0.004 + index * Math.PI / 2
    context.beginPath()
    context.moveTo(centerX + Math.cos(angle) * 10, centerY + Math.sin(angle) * 10)
    context.lineTo(centerX + Math.cos(angle) * 16, centerY + Math.sin(angle) * 16)
    context.stroke()
  }
  context.restore()
}

function drawMaskLines(centerX, centerY, mask, reach) {
  const ends = [
    [Direction.NORTH, centerX, centerY - reach],
    [Direction.EAST, centerX + reach, centerY],
    [Direction.SOUTH, centerX, centerY + reach],
    [Direction.WEST, centerX - reach, centerY],
  ]
  for (const [direction, x, y] of ends) {
    if ((mask & direction) === 0) continue
    context.beginPath()
    context.moveTo(centerX, centerY)
    context.lineTo(x, y)
    context.stroke()
  }
}

function drawSources() {
  const skin = getSkin(state.skinKey)
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    const hot = state.powered.has(`${row}:0`) || state.burning.has(`${row}:0`)
    context.shadowBlur = hot ? 30 : 18
    context.shadowColor = hot ? skin.powered : skin.spark
    context.fillStyle = hot ? '#fff4b6' : skin.spark
    context.beginPath()
    context.arc(57, y, hot ? 11 : 9, 0, Math.PI * 2)
    context.fill()
  }
  context.shadowBlur = 0
}

function drawRockets() {
  const skin = getSkin(state.skinKey)
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    const launching = state.launchingRows.has(row)
    const launchProgress = launching ? Math.min(1, state.burn?.hold / 0.34 ?? 0) : 0
    const offset = launchProgress * 28
    context.save()
    context.translate(707 + offset, y)
    context.fillStyle = launching ? skin.powered : skin.rocket
    context.beginPath()
    context.moveTo(25, 0)
    context.lineTo(2, -12)
    context.lineTo(-18, -10)
    context.lineTo(-12, 0)
    context.lineTo(-18, 10)
    context.lineTo(2, 12)
    context.closePath()
    context.fill()
    context.fillStyle = '#f6f3ff'
    context.beginPath()
    context.arc(1, 0, 4, 0, Math.PI * 2)
    context.fill()
    if (launching) drawRocketFlame(launchProgress, skin)
    context.restore()
  }
}

function drawRocketFlame(progress, skin) {
  context.save()
  context.globalAlpha = 0.55 + progress * 0.45
  context.fillStyle = skin.spark
  context.shadowBlur = 22
  context.shadowColor = skin.powered
  context.beginPath()
  context.moveTo(-12, -6)
  context.lineTo(-28 - progress * 13, 0)
  context.lineTo(-12, 6)
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
    context.save()
    context.globalAlpha = Math.max(0, 1 - particle.age / particle.life)
    context.fillStyle = particle.color
    context.shadowBlur = 10
    context.shadowColor = particle.color
    context.beginPath()
    context.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2)
    context.fill()
    context.restore()
  }
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
  context.roundRect(x, y, width, height, radius)
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
  if (state.resolving && !state.uiPaused) updateBurn(deltaSeconds)
  if (!state.paused && !state.uiPaused && !state.gameOver && !state.resolving && Number.isFinite(state.timeLeft)) {
    state.timeLeft -= deltaSeconds
    if (state.timeLeft <= 0) endGame()
  }
  updateParticles(deltaSeconds)
  updateHud()
  render()
  requestAnimationFrame(frame)
}

function configureCanvasResolution() {
  const ratio = Math.min(3, window.devicePixelRatio || 1)
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
elements.plusScreen.addEventListener('pointerdown', (event) => { if (event.target === elements.plusScreen) closePlusScreen() })
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
requestAnimationFrame(frame)
