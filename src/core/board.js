export const Direction = Object.freeze({
  NORTH: 1,
  EAST: 2,
  SOUTH: 4,
  WEST: 8,
})

const directionSteps = [
  { bit: Direction.NORTH, opposite: Direction.SOUTH, row: -1, col: 0 },
  { bit: Direction.EAST, opposite: Direction.WEST, row: 0, col: 1 },
  { bit: Direction.SOUTH, opposite: Direction.NORTH, row: 1, col: 0 },
  { bit: Direction.WEST, opposite: Direction.EAST, row: 0, col: -1 },
]

const defaultMasks = [
  Direction.NORTH | Direction.SOUTH,
  Direction.NORTH | Direction.EAST,
  Direction.NORTH | Direction.EAST | Direction.SOUTH,
  Direction.NORTH | Direction.EAST | Direction.SOUTH | Direction.WEST,
]

export function rotateMaskClockwise(mask) {
  return ((mask << 1) & 0b1111) | ((mask >> 3) & 1)
}

export class Board {
  constructor(rows = 8, cols = 8, random = Math.random, masks = defaultMasks) {
    this.rows = rows
    this.cols = cols
    this.random = random
    this.masks = masks
    this.cells = Array.from({ length: rows }, () => Array.from({ length: cols }, () => this.createRandomMask()))
  }

  static fromMasks(cells, random = Math.random, masks = defaultMasks) {
    const board = new Board(cells.length, cells[0].length, random, masks)
    board.cells = cells.map((row) => [...row])
    return board
  }

  createRandomMask() {
    const baseMask = this.masks[Math.floor(this.random() * this.masks.length)]
    const rotations = Math.floor(this.random() * 4)
    let mask = baseMask
    for (let index = 0; index < rotations; index += 1) mask = rotateMaskClockwise(mask)
    return mask
  }

  get(row, col) {
    return this.cells[row]?.[col] ?? null
  }

  rotate(row, col) {
    if (!this.isInside(row, col)) return false
    this.cells[row][col] = rotateMaskClockwise(this.cells[row][col])
    return true
  }

  resolveLaunch() {
    const accepted = new Map()
    const distances = new Map()
    const rocketRows = new Set()

    for (let row = 0; row < this.rows; row += 1) {
      if ((this.cells[row][0] & Direction.WEST) === 0) continue
      const component = this.sourceComponent(row)
      if (component.rocketRows.length === 0) continue
      for (const rocketRow of component.rocketRows) rocketRows.add(rocketRow)
      for (const cell of component.cells) {
        const key = this.key(cell.row, cell.col)
        accepted.set(key, cell)
        const distance = component.distances.get(key) ?? 0
        distances.set(key, Math.min(distances.get(key) ?? distance, distance))
      }
    }

    const burned = [...accepted.values()].sort((a, b) => a.row - b.row || a.col - b.col)
    return { burned, rocketRows: [...rocketRows].sort((a, b) => a - b), burnStages: this.makeBurnStages(burned, distances) }
  }

  sourceComponent(sourceRow) {
    const source = { row: sourceRow, col: 0 }
    const queue = [source]
    const visited = new Set([this.key(source.row, source.col)])
    const distances = new Map([[this.key(source.row, source.col), 0]])
    const cells = []
    const rocketRows = []
    let cursor = 0

    while (cursor < queue.length) {
      const cell = queue[cursor]
      cursor += 1
      cells.push(cell)
      if (this.isRocketEndpoint(cell)) rocketRows.push(cell.row)
      const distance = distances.get(this.key(cell.row, cell.col)) ?? 0
      for (const next of this.connectedNeighbors(cell.row, cell.col)) {
        const nextKey = this.key(next.row, next.col)
        if (visited.has(nextKey)) continue
        visited.add(nextKey)
        distances.set(nextKey, distance + 1)
        queue.push(next)
      }
    }
    return { cells, rocketRows, distances }
  }

  isRocketEndpoint(cell) {
    if (cell.col !== this.cols - 1) return false
    return (this.cells[cell.row][cell.col] & Direction.EAST) !== 0
  }

  makeBurnStages(cells, distances) {
    const maxDistance = cells.reduce((maximum, cell) => Math.max(maximum, distances.get(this.key(cell.row, cell.col)) ?? -1), -1)
    if (maxDistance < 0) return []
    return Array.from({ length: maxDistance + 1 }, (_, distance) => cells
      .filter((cell) => distances.get(this.key(cell.row, cell.col)) === distance)
      .sort((a, b) => a.row - b.row || a.col - b.col))
  }

  connectedNeighbors(row, col) {
    const mask = this.cells[row][col]
    const neighbors = []
    for (const step of directionSteps) {
      if ((mask & step.bit) === 0) continue
      const nextRow = row + step.row
      const nextCol = col + step.col
      if (!this.isInside(nextRow, nextCol)) continue
      if ((this.cells[nextRow][nextCol] & step.opposite) === 0) continue
      neighbors.push({ row: nextRow, col: nextCol })
    }
    return neighbors
  }

  connectionQuality(row, col) {
    const mask = this.get(row, col)
    if (mask === null) return 0
    let edges = 0
    let valid = 0
    for (const step of directionSteps) {
      if ((mask & step.bit) === 0) continue
      edges += 1
      if (step.bit === Direction.WEST && col === 0) {
        valid += 1
        continue
      }
      if (step.bit === Direction.EAST && col === this.cols - 1) {
        valid += 1
        continue
      }
      const nextRow = row + step.row
      const nextCol = col + step.col
      if (!this.isInside(nextRow, nextCol)) continue
      if ((this.cells[nextRow][nextCol] & step.opposite) !== 0) valid += 1
    }
    return edges > 0 ? valid / edges : 0
  }

  consume(cells) {
    for (const { row, col } of cells) {
      if (this.isInside(row, col)) this.cells[row][col] = null
    }

    for (let col = 0; col < this.cols; col += 1) {
      const survivors = []
      for (let row = this.rows - 1; row >= 0; row -= 1) {
        const mask = this.cells[row][col]
        if (mask !== null) survivors.push(mask)
      }
      for (let row = this.rows - 1; row >= 0; row -= 1) this.cells[row][col] = survivors[this.rows - 1 - row] ?? this.createRandomMask()
    }
  }

  toMasks() {
    return this.cells.map((row) => [...row])
  }

  isInside(row, col) {
    return row >= 0 && row < this.rows && col >= 0 && col < this.cols
  }

  key(row, col) {
    return `${row}:${col}`
  }
}
