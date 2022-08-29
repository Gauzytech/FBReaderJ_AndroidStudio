package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.annotation.MainThread
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.geometerplus.DebugHelper
import org.geometerplus.fbreader.fbreader.FBReaderApp
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import timber.log.Timber
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName FlutterBridge
 * @Date 5/1/22, 2:00 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */

private const val TAG = "flutter_bridge"
private const val DRAW_ON_BITMAP = "draw_on_bitmap"
private const val PREPARE_PAGE = "prepare_page"
private const val CAN_SCROLL = "can_scroll"
private const val ON_SCROLLING_FINISHED = "on_scrolling_finished"
private const val LONG_PRESS_START = "long_press_start"
private const val LONG_PRESS_MOVE = "long_press_update"
private const val LONG_PRESS_END = "long_press_end"
private const val ON_TAP_UP = "on_tap_up"

class FlutterBridge(
    private val context: Context,
    readerController: FBReaderApp,
    messenger: BinaryMessenger
) : MethodCallHandler {

    private var channel: MethodChannel = MethodChannel(messenger, "com.flutter.book.reader")
    private val contentProcessor = readerController.contentProcessor

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Timber.v("$TAG, onMethodCall: ${call.method}, Thread: ${Thread.currentThread().name}")
        when (call.method) {
            DRAW_ON_BITMAP -> {
                // 获取Flutter传递的参数
                val index = call.argument<Int>("page_index")!!
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                val pageIndex = PageIndex.getPageIndex(index)
                Timber.v("$TAG 收到了: $pageIndex, [$width, $height]")

                // 绘制内容的bitmap
                val bitmap = drawBitmap(pageIndex, width, height)
                // 回调结果
                if (DebugHelper.SAVE_BITMAP) {
                    debugSave(bitmap.toByteArray(), "图书内容bitmap_current")
                } else {
                    result.success(bitmap.toByteArray())
                }
            }
            PREPARE_PAGE -> {
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                val prev = call.argument<Boolean>("update_prev_page_cache")!!
                val next = call.argument<Boolean>("update_next_page_cache")!!
                Timber.v("$TAG, 收到了: [$prev, $next]")

                contentProcessor.prepareAdjacentPage(
                    width, height, 0, prev, next,
                    object : ResultCallBack {
                        override fun onComplete(data: Any) {
                            result.success(data)
                        }
                    }
                )
            }
            CAN_SCROLL -> {
                val index = call.argument<Int>("page_index")!!
                val pageIndex = PageIndex.getPageIndex(index)
                val canScroll = contentProcessor.canScroll(pageIndex)
                result.success(canScroll)
            }
            ON_SCROLLING_FINISHED -> {
                val index = call.argument<Int>("page_index")!!
                val pageIndex = PageIndex.getPageIndex(index)
                contentProcessor.onScrollingFinished(pageIndex)
            }
            LONG_PRESS_START -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                Timber.v("flutter长按事件, 长按开始: [$dx, $dy], [$width, $height]")
                contentProcessor.onFingerLongPress(dx, dy, object : PaintListener {
                    override fun repaint() {
                        Timber.v("flutter长按事件, 长按开始, 需要repaint")
                        // 绘制内容的bitmap
                        val bitmap = drawBitmap(PageIndex.CURRENT, width, height)
                        // 回调结果
                        result.success(bitmap.toByteArray())
                    }
                })
            }
            LONG_PRESS_MOVE -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                Timber.v("flutter长按事件, 长按移动: [$dx, $dy], [$width, $height]")
                contentProcessor.onFingerMoveAfterLongPress(dx, dy, object : PaintListener {
                    override fun repaint() {
                        Timber.v("flutter长按事件, 长按移动, 需要repaint")
                        // 绘制内容的bitmap
                        val bitmap = drawBitmap(PageIndex.CURRENT, width, height)
                        // 回调结果
                        result.success(bitmap.toByteArray())
                    }
                })
            }
            LONG_PRESS_END -> {
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                Timber.v("flutter长按事件, 长按结束 [$width, $height]")
                contentProcessor.onFingerReleaseAfterLongPress(0, 0, object : PaintListener {
                    override fun repaint() {
                        Timber.v("flutter长按事件, 长按结束, 需要repaint")
                        // 绘制内容的bitmap
                        val bitmap = drawBitmap(PageIndex.CURRENT, width, height)
                        // 回调结果
                        result.success(bitmap.toByteArray())
                    }
                })
            }
            ON_TAP_UP -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Double>("width")!!.toInt()
                val height = call.argument<Double>("height")!!.toInt()
                contentProcessor.onFingerSingleTap(dx, dy, object : PaintListener {
                    override fun repaint() {
                        Timber.v("flutter长按事件, 点击, 需要repaint")
                        // 绘制内容的bitmap
                        val bitmap = drawBitmap(PageIndex.CURRENT, width, height)
                        // 回调结果
                        result.success(bitmap.toByteArray())
                    }
                })
            }
        }
    }

    @MainThread
    fun invokeMethod(method: String, arguments: Any?, callback: MethodChannel.Result?) {
        channel.invokeMethod(method, arguments, callback)
    }

    private fun drawBitmap(pageInt: PageIndex, width: Int, height: Int): Bitmap {
        // 绘制内容的bitmap
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
        contentProcessor.drawOnBitmap(
            bitmap,
            pageInt,
            width,
            height,
            0
        )
        return bitmap
    }

    private fun getTestNativeImage(result: MethodChannel.Result) {
        val drawableId: Int =
            context.resources.getIdentifier("test_img", "drawable", context.packageName)
        val bitmap = BitmapFactory.decodeResource(context.resources, drawableId)
        val baos = ByteArrayOutputStream()
        val isSuccess = bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
        result.success(if (isSuccess) baos.toByteArray() else "")
    }

    private fun debugSave(bytes: ByteArray, name: String) {
        val targetPath = "${context.cacheDir}/images/"
        val parent = File(targetPath)
        if (!parent.exists()) {
            parent.mkdirs()
        }
        Timber.v("$TAG, save path $targetPath")
        val saveFile = File(targetPath, name)
        val ops = FileOutputStream(saveFile)
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, ops)
        ops.flush()
        ops.close()
        Timber.v("flutter_bridge, save success!")
    }

    interface ResultCallBack {
        fun onComplete(data: Any)
    }
}