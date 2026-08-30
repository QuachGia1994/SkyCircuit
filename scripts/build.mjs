import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises'

await rm('dist', { recursive: true, force: true })
await mkdir('dist', { recursive: true })
await Promise.all([
  cp('index.html', 'dist/index.html'),
  cp('styles.css', 'dist/styles.css'),
  cp('src', 'dist/src', { recursive: true }),
  cp('assets', 'dist/assets', { recursive: true }),
])

const betaUnlocked = process.env.SKYCIRCUIT_BETA === '1'
const index = await readFile('dist/index.html', 'utf8')
await writeFile(
  'dist/index.html',
  index.replace('globalThis.__SKYCIRCUIT_BETA__ = false', `globalThis.__SKYCIRCUIT_BETA__ = ${betaUnlocked}`),
)
