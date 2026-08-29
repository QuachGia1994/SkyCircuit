package com.skycircuit.nativev2

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.os.Build
import android.view.Choreographer
import android.view.MotionEvent
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import kotlin.math.min

class CircuitRenderView(
    context: Context,
    private val engine: GameEngine,
) : SurfaceView(context), SurfaceHolder.Callback, Choreographer.FrameCallback {

    private val frameClock = Choreographer.getInstance()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { strokeCap = Paint.Cap.ROUND }
    private val rotations = IntArray(64)
    private var frameCount = 0
    private var running = false

    init {
        holder.addCallback(this)
        setZOrderOnTop(false)
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        running = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            holder.surface.setFrameRate(120f, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
        }
        frameClock.postFrameCallback(this)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        running = false
        frameClock.removeFrameCallback(this)
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (!running) return
        val started = System.nanoTime()
        val canvas = holder.lockCanvas()
        if (canvas != null) {
            try {
                drawScene(canvas)
            } finally {
                holder.unlockCanvasAndPost(canvas)
            }
        }
        frameCount += 1
        if (frameCount % 30 == 0) {
            val elapsedMs = (System.nanoTime() - started) / 1_000_000f
            engine.recordRenderTime(elapsedMs)
        }
        frameClock.postFrameCallback(this)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action != MotionEvent.ACTION_UP) return true
        val board = boardGeometry(width.toFloat(), height.toFloat())
        if (event.x !in board.left..board.right || event.y !in board.top..board.bottom) return true
        val column = ((event.x - board.left) / board.cell).toInt().coerceIn(0, 7)
        val row = ((event.y - board.top) / board.cell).toInt().coerceIn(0, 7)
        val index = row * 8 + column
        rotations[index] = (rotations[index] + 1) % 4
        val target = (row + column) % 4
        val delta = kotlin.math.abs(rotations[index] - target)
        val wrapped = min(delta, 4 - delta)
        val quality = when (wrapped) {
            0 -> 1f
            1 -> 0.62f
            else -> 0.2f
        }
        engine.registerRotationQuality(quality)
        if (quality > 0.95f && (row + column) % 5 == 0) engine.registerLaunch()
        return true
    }

    private fun drawScene(canvas: Canvas) {
        canvas.drawColor(Color.rgb(3, 10, 24))
        val board = boardGeometry(canvas.width.toFloat(), canvas.height.toFloat())
        drawStars(canvas)
        drawBoardFrame(canvas, board)
        for (row in 0 until 8) {
            for (column in 0 until 8) {
                drawTile(canvas, board, row, column, rotations[row * 8 + column])
            }
        }
    }

    private fun drawStars(canvas: Canvas) {
        paint.style = Paint.Style.FILL
        for (index in 0 until 48) {
            val x = ((index * 137 + 19) % maxOf(1, canvas.width)).toFloat()
            val y = ((index * 83 + 31) % maxOf(1, canvas.height)).toFloat()
            paint.color = if (index % 7 == 0) Color.rgb(126, 220, 255) else Color.WHITE
            paint.alpha = 70 + (index % 5) * 28
            canvas.drawCircle(x, y, 1f + (index % 3) * 0.45f, paint)
        }
        paint.alpha = 255
    }

    private fun drawBoardFrame(canvas: Canvas, board: BoardGeometry) {
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(10, 18, 30)
        canvas.drawRoundRect(board.left - 18, board.top - 18, board.right + 18, board.bottom + 18, 30f, 30f, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 4f
        paint.color = Color.rgb(80, 116, 150)
        canvas.drawRoundRect(board.left - 18, board.top - 18, board.right + 18, board.bottom + 18, 30f, 30f, paint)
    }

    private fun drawTile(canvas: Canvas, board: BoardGeometry, row: Int, column: Int, rotation: Int) {
        val left = board.left + column * board.cell + 4f
        val top = board.top + row * board.cell + 4f
        val right = left + board.cell - 8f
        val bottom = top + board.cell - 8f
        val centerX = (left + right) / 2f
        val centerY = (top + bottom) / 2f

        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(14, 31, 52)
        canvas.drawRoundRect(left, top, right, bottom, board.cell * 0.12f, board.cell * 0.12f, paint)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        paint.color = Color.rgb(57, 86, 116)
        canvas.drawRoundRect(left, top, right, bottom, board.cell * 0.12f, board.cell * 0.12f, paint)

        canvas.save()
        canvas.rotate(rotation * 90f, centerX, centerY)
        val path = Path().apply {
            moveTo(left + board.cell * 0.12f, centerY)
            lineTo(centerX, centerY)
            lineTo(centerX, top + board.cell * 0.12f)
        }
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = maxOf(9f, board.cell * 0.17f)
        paint.color = Color.rgb(17, 23, 31)
        canvas.drawPath(path, paint)
        paint.strokeWidth = maxOf(5f, board.cell * 0.1f)
        paint.color = Color.rgb(112, 216, 255)
        canvas.drawPath(path, paint)
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(255, 194, 85)
        canvas.drawCircle(centerX, centerY, maxOf(3f, board.cell * 0.055f), paint)
        canvas.restore()
    }

    private fun boardGeometry(width: Float, height: Float): BoardGeometry {
        val size = min(width * 0.92f, height * 0.78f)
        val cell = size / 8f
        return BoardGeometry(
            left = (width - size) / 2f,
            top = (height - size) / 2f,
            right = (width + size) / 2f,
            bottom = (height + size) / 2f,
            cell = cell,
        )
    }

    private data class BoardGeometry(
        val left: Float,
        val top: Float,
        val right: Float,
        val bottom: Float,
        val cell: Float,
    )
}
