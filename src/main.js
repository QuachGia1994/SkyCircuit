import { Board, Direction } from './core/board.js'

const canvas = document.querySelector('#game')
const context = canvas.getContext('2d')
const elements = {
  score: document.querySelector('#score'),
  rockets: document.querySelector('#rockets'),
  target: document.querySelector('#target'),
  time: document.querySelector('#time'),
  best: document.querySelector('#best'),
  level: document.querySelector('#level'),
  status: document.querySelector('#status'),
  overlay: document.querySelector('#overlay'),
  overlayTitle: document.querySelector('#overlay-title'),
  overlayCopy: document.querySelector('#overlay-copy'),
  pause: document.querySelector('#pause'),
  restart: document.querySelector('#restart'),
}

const layout = Object.freeze({ canvasWidth: 768, canvasHeight: 720, rows: 8, cols: 8, cell: 72, boardX: 96, boardY: 72, boardSize: 576 })
const colors = Object.freeze({ tile: '#101d34', tileBorder: '#2b4261', conduit: '#80e9ff', powered: '#ffd166', spark: '#ff8f5a', rocket: '#ff7ab8' })
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

function createState() {
  return {
    score: 0,
    best: Number(localStorage.getItem('skycircuit.best') ?? 0),
    level: 1,
    launched: 0,
    target: 8,
    timeLeft: 70,
    paused: false,
    resolving: false,
    gameOver: false,
    powered: new Set(),
    launchingRows: new Set(),
  }
}

function newGame() {
  board = new Board(layout.rows, layout.cols, Math.random, tilePool)
  state = createState()
  particles.length = 0
  hideOverlay()
  elements.pause.textContent = 'Pause'
  elements.status.textContent = 'Tap a circuit tile to rotate it. Connect a spark on the left to a rocket on the right.'
  updateHud()
}

function updateHud() {
  elements.score.textContent = String(state.score)
  elements.rockets.textContent = String(state.launched)
  elements.target.textContent = String(state.target)
  elements.time.textContent = String(Math.max(0, Math.ceil(state.timeLeft)))
  elements.best.textContent = String(state.best)
  elements.level.textContent = String(state.level)
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
  if (state.paused || state.gameOver || state.resolving) return
  const tile = tileAt(canvasPoint(event))
  if (!tile) return
  ensureAudio()
  board.rotate(tile.row, tile.col)
  playTone(360, 0.035, 'square', 0.025)
  vibrate(8)
  const launch = board.resolveLaunch()
  if (launch.rocketRows.length > 0) resolveLaunch(launch)
}

function resolveLaunch(launch) {
  state.resolving = true
  state.powered = new Set(launch.burned.map(({ row, col }) => `${row}:${col}`))
  state.launchingRows = new Set(launch.rocketRows)
  applyLaunchScore(launch)
  launch.rocketRows.forEach((row, index) => spawnFirework(row, index))
  playLaunchSound(launch.rocketRows.length)
  vibrate(Math.min(80, 20 + launch.rocketRows.length * 12))
  elements.status.textContent = launch.rocketRows.length > 1 ? `${launch.rocketRows.length} rockets launched in one circuit.` : 'Rocket launched.'
  setTimeout(() => finishLaunch(launch), 380)
}

function applyLaunchScore(launch) {
  const rocketCount = launch.rocketRows.length
  const comboBonus = Math.max(0, rocketCount - 1) * 175
  state.score += rocketCount * 100 + comboBonus + launch.burned.length * 5
  state.launched += rocketCount
  if (state.score > state.best) {
    state.best = state.score
    localStorage.setItem('skycircuit.best', String(state.best))
  }
  updateHud()
}

function finishLaunch(launch) {
  board.consume(launch.burned)
  state.powered.clear()
  state.launchingRows.clear()
  state.resolving = false
  if (state.launched >= state.target) return advanceLevel()
  const cascade = board.resolveLaunch()
  if (cascade.rocketRows.length > 0) setTimeout(() => resolveLaunch(cascade), 90)
}

function advanceLevel() {
  state.level += 1
  state.launched = 0
  state.target = Math.min(18, 6 + state.level * 2)
  state.timeLeft = Math.min(90, 62 + state.level * 4)
  board = new Board(layout.rows, layout.cols, Math.random, tilePool)
  showOverlay(`Level ${state.level}`, 'Fresh circuit. Keep the show alive.', 750)
  updateHud()
}

function togglePause() {
  if (state.gameOver || state.resolving) return
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

function render() {
  drawBackground()
  drawSources()
  drawBoard()
  drawRockets()
  drawParticles()
}

function drawBackground() {
  const gradient = context.createLinearGradient(0, 0, 0, layout.canvasHeight)
  gradient.addColorStop(0, '#0b1d38')
  gradient.addColorStop(1, '#050b14')
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
  const x = layout.boardX + col * layout.cell
  const y = layout.boardY + row * layout.cell
  const powered = state.powered.has(`${row}:${col}`)
  context.fillStyle = powered ? '#473b22' : colors.tile
  context.strokeStyle = powered ? '#8b6b2d' : colors.tileBorder
  context.lineWidth = 2
  roundRect(x + 3, y + 3, layout.cell - 6, layout.cell - 6, 12)
  context.fill()
  context.stroke()
  drawConduit(x + layout.cell / 2, y + layout.cell / 2, mask, powered)
}

function drawConduit(centerX, centerY, mask, powered) {
  const reach = layout.cell / 2 - 7
  const color = powered ? colors.powered : colors.conduit
  context.lineCap = 'round'
  context.lineWidth = 16
  context.strokeStyle = '#06101d'
  drawMaskLines(centerX, centerY, mask, reach)
  context.lineWidth = 7
  context.strokeStyle = color
  drawMaskLines(centerX, centerY, mask, reach)
  context.fillStyle = color
  context.beginPath()
  context.arc(centerX, centerY, 7, 0, Math.PI * 2)
  context.fill()
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
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    context.shadowBlur = 18
    context.shadowColor = colors.spark
    context.fillStyle = colors.spark
    context.beginPath()
    context.arc(57, y, 9, 0, Math.PI * 2)
    context.fill()
  }
  context.shadowBlur = 0
}

function drawRockets() {
  for (let row = 0; row < layout.rows; row += 1) {
    const y = layout.boardY + row * layout.cell + layout.cell / 2
    const launching = state.launchingRows.has(row)
    const offset = launching ? 15 : 0
    context.save()
    context.translate(707 + offset, y)
    context.fillStyle = launching ? colors.powered : colors.rocket
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
    context.restore()
  }
}

function spawnFirework(row, variant) {
  const y = layout.boardY + row * layout.cell + layout.cell / 2
  for (let index = 0; index < 30; index += 1) {
    const angle = (Math.PI * 2 * index) / 30 + variant * 0.17
    const speed = 75 + Math.random() * 135
    particles.push({ x: 742, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: 0.8 + Math.random() * 0.35, age: 0 })
  }
}

function updateParticles(deltaSeconds) {
  for (const particle of particles) {
    particle.age += deltaSeconds
    particle.x += particle.vx * deltaSeconds
    particle.y += particle.vy * deltaSeconds
    particle.vy += 55 * deltaSeconds
  }
  for (let index = particles.length - 1; index >= 0; index -= 1) if (particles[index].age >= particles[index].life) particles.splice(index, 1)
}

function drawParticles() {
  for (const particle of particles) {
    const alpha = 1 - particle.age / particle.life
    context.fillStyle = `rgba(255, 209, 102, ${Math.max(0, alpha)})`
    context.beginPath()
    context.arc(particle.x, particle.y, 3.5, 0, Math.PI * 2)
    context.fill()
  }
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
  if (!state.paused && !state.gameOver && !state.resolving) {
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
elements.restart.addEventListener('click', newGame)
document.addEventListener('visibilitychange', () => {
  if (document.hidden && state && !state.gameOver && !state.paused) togglePause()
})

configureCanvasResolution()
newGame()
requestAnimationFrame(frame)
