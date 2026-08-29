export const gameModes = Object.freeze({
  classic: Object.freeze({
    key: 'classic',
    name: 'Classic',
    plus: false,
    description: 'Balanced timer and targets.',
    initialTime: 70,
    initialTarget: 8,
    levelTime: (level) => Math.min(90, 62 + level * 4),
    levelTarget: (level) => Math.min(18, 6 + level * 2),
  }),
  zen: Object.freeze({
    key: 'zen',
    name: 'Zen',
    plus: true,
    description: 'No timer. Solve at your own pace.',
    initialTime: Number.POSITIVE_INFINITY,
    initialTarget: 8,
    levelTime: () => Number.POSITIVE_INFINITY,
    levelTarget: (level) => Math.min(18, 6 + level * 2),
  }),
  blitz: Object.freeze({
    key: 'blitz',
    name: 'Blitz',
    plus: true,
    description: 'Shorter rounds with faster targets.',
    initialTime: 45,
    initialTarget: 10,
    levelTime: (level) => Math.min(60, 40 + level * 2),
    levelTarget: (level) => Math.min(22, 8 + level * 2),
  }),
})

export const modeList = Object.freeze(Object.values(gameModes))

export function getMode(key) {
  return gameModes[key] ?? gameModes.classic
}
