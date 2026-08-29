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
    const seen = new Set()
    const burned = []
    const rocketRows = new Set()

    for (let row = 0; row < this.rows; row += 1) {
      const startKey = this.key(row, 0)
      if (seen.has(startKey) || (this.cells[row][0] & Direction.WEST) === 0) continue
      const component = this.traceComponent(row, 0, seen)
      if (component.rocketRows.size === 0) continue
      burned.push(...component.cells)
      for (const rocketRow of component.rocketRows) rocketRows.add(rocketRow)
    }

    burned.sort((a, b) => a.row - b.row || a.col - b.col)
    return { burned, rocketRows: [...rocketRows].sort((a, b) => a - b) }
  }

  traceComponent(startRow, startCol, seen) {
    const queue = [{ row: startRow, col: startCol }]
    const cells = []
    const rocketRows = new Set()
    seen.add(this.key(startRow, startCol))

    while (queue.length > 0) {
      const cell = queue.shift()
      cells.push(cell)
      const mask = this.cells[cell.row][cell.col]

      for (const step of directionSteps) {
        if ((mask & step.bit) === 0) continue
        if (step.bit === Direction.EAST && cell.col === this.cols - 1) rocketRows.add(cell.row)
        const nextRow = cell.row + step.row
        const nextCol = cell.col + step.col
        if (!this.isInside(nextRow, nextCol)) continue
        if ((this.cells[nextRow][nextCol] & step.opposite) === 0) continue
        const nextKey = this.key(nextRow, nextCol)
        if (seen.has(nextKey)) continue
        seen.add(nextKey)
        queue.push({ row: nextRow, col: nextCol })
      }
    }

    return { cells, rocketRows }
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
