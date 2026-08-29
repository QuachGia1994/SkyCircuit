export const tutorialSteps = Object.freeze([
  Object.freeze({
    number: 1,
    eyebrow: 'ROTATE',
    title: 'Tap a tile to rotate',
    body: 'Turn conduit tiles until their open ends line up. Every tap rotates one tile clockwise.',
    accent: 'cyan',
  }),
  Object.freeze({
    number: 2,
    eyebrow: 'CONNECT',
    title: 'Connect spark to rocket',
    body: 'Build a complete route from a spark on the left edge to one or more rockets on the right.',
    accent: 'gold',
  }),
  Object.freeze({
    number: 3,
    eyebrow: 'IGNITE',
    title: 'Watch the circuit burn',
    body: 'A completed route ignites from the source, burns through the pipes step by step, then launches the rockets.',
    accent: 'violet',
  }),
])

export const plusBenefits = Object.freeze([
  Object.freeze({ icon: '◇', title: 'Exclusive skins', body: 'Nova Gold, Nebula Violet, and Plasma Chrome visual themes.' }),
  Object.freeze({ icon: '∞', title: 'Zen Mode', body: 'No timer pressure. Keep solving and enjoy the ignition loop.' }),
  Object.freeze({ icon: '⚡', title: 'Blitz Mode', body: 'Short rounds, faster targets, and more pressure on every rotation.' }),
  Object.freeze({ icon: '★', title: 'Daily Challenge', body: 'A future seeded puzzle with one shared daily objective.' }),
])

export const plusRoadmap = Object.freeze([
  Object.freeze({ label: 'Plus skins', status: 'Prototype ready' }),
  Object.freeze({ label: 'Zen + Blitz', status: 'Prototype ready' }),
  Object.freeze({ label: 'Daily Challenge', status: 'Next' }),
  Object.freeze({ label: 'Weekly Events', status: 'Later' }),
  Object.freeze({ label: 'Leaderboards', status: 'Later' }),
  Object.freeze({ label: 'Seasonal themes', status: 'Later' }),
])
