import test from 'node:test'
import assert from 'node:assert/strict'
import { Board, Direction, rotateMaskClockwise } from '../src/core/board.js'

test('rotateMaskClockwise rotates north to east', () => {
  assert.equal(rotateMaskClockwise(Direction.NORTH), Direction.EAST)
})

test('resolveLaunch finds a straight source-to-rocket path', () => {
  const board = Board.fromMasks([
    [Direction.WEST | Direction.EAST, Direction.WEST | Direction.EAST, Direction.WEST | Direction.EAST],
  ])

  const result = board.resolveLaunch()

  assert.deepEqual(result.rocketRows, [0])
  assert.deepEqual(result.burned, [
    { row: 0, col: 0 },
    { row: 0, col: 1 },
    { row: 0, col: 2 },
  ])
  assert.deepEqual(result.burnStages, [
    [{ row: 0, col: 0 }],
    [{ row: 0, col: 1 }],
    [{ row: 0, col: 2 }],
  ])
})

test('resolveLaunch burns only source components that reach a rocket', () => {
  const board = Board.fromMasks([
    [Direction.WEST | Direction.EAST, Direction.WEST | Direction.EAST, Direction.WEST | Direction.EAST],
    [Direction.WEST, Direction.NORTH | Direction.SOUTH, Direction.NORTH | Direction.SOUTH],
  ])

  const result = board.resolveLaunch()

  assert.deepEqual(result.rocketRows, [0])
  assert.ok(result.burned.every(({ row }) => row === 0))
})

test('resolveLaunch only fires the rocket paired to its source row', () => {
  const board = Board.fromMasks([
    [Direction.SOUTH, Direction.SOUTH, Direction.SOUTH | Direction.EAST],
    [Direction.WEST | Direction.EAST | Direction.SOUTH, Direction.NORTH | Direction.EAST | Direction.WEST, Direction.NORTH | Direction.EAST | Direction.SOUTH | Direction.WEST],
    [Direction.NORTH, Direction.NORTH, Direction.NORTH | Direction.EAST],
  ])

  const result = board.resolveLaunch()

  assert.deepEqual(result.rocketRows, [1])
  assert.deepEqual(result.burned, [
    { row: 1, col: 0 },
    { row: 1, col: 1 },
    { row: 1, col: 2 },
  ])
})

test('burn stages ignite from every source in one connected component', () => {
  const board = Board.fromMasks([
    [Direction.WEST | Direction.EAST | Direction.SOUTH, Direction.WEST | Direction.EAST | Direction.SOUTH],
    [Direction.WEST | Direction.EAST | Direction.NORTH, Direction.WEST | Direction.EAST | Direction.NORTH],
  ])

  const result = board.resolveLaunch()

  assert.deepEqual(result.burnStages, [
    [{ row: 0, col: 0 }, { row: 1, col: 0 }],
    [{ row: 0, col: 1 }, { row: 1, col: 1 }],
  ])
})

test('resolveLaunch handles closed loops without revisiting forever', () => {
  const cornerNE = Direction.NORTH | Direction.EAST
  const cornerES = Direction.EAST | Direction.SOUTH
  const cornerSW = Direction.SOUTH | Direction.WEST
  const cornerWN = Direction.WEST | Direction.NORTH
  const board = Board.fromMasks([
    [cornerES, cornerSW],
    [cornerNE, cornerWN],
  ])

  const result = board.resolveLaunch()

  assert.deepEqual(result, { burned: [], rocketRows: [], burnStages: [] })
})

test('consume collapses surviving tiles downward and refills from the top', () => {
  const refillMask = Direction.NORTH | Direction.SOUTH
  const board = Board.fromMasks([
    [Direction.NORTH | Direction.EAST],
    [Direction.NORTH | Direction.SOUTH],
    [Direction.SOUTH | Direction.WEST],
  ], () => 0, [refillMask])

  board.consume([{ row: 1, col: 0 }])

  assert.deepEqual(board.toMasks(), [
    [refillMask],
    [Direction.NORTH | Direction.EAST],
    [Direction.SOUTH | Direction.WEST],
  ])
})
