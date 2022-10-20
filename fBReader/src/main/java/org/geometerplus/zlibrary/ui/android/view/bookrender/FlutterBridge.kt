package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.appcompat.app.AppCompatActivity
import com.google.gson.Gson
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.geometerplus.DebugHelper
import org.geometerplus.fbreader.fbreader.FBReaderApp
import org.geometerplus.zlibrary.core.view.Hull
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.SelectionResult
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
private const val METHOD_CHANNEL_PATH = "platform_channel_methods"

private const val DRAW_ON_BITMAP = "draw_on_bitmap"
private const val PREPARE_PAGE = "prepare_page"
private const val CAN_SCROLL = "can_scroll"
private const val ON_SCROLLING_FINISHED = "on_scrolling_finished"
private const val LONG_PRESS_START = "long_press_start"
private const val LONG_PRESS_MOVE = "long_press_update"
private const val LONG_PRESS_END = "long_press_end"
private const val ON_TAP_UP = "on_tap_up"
private const val ON_DRAG_START = "on_selection_drag_start"
private const val ON_DRAG_MOVE = "on_selection_drag_move"
private const val ON_DRAG_END = "on_selection_drag_end"
private const val SELECTION_CLEAR = "selection_clear"
private const val SELECTED_TEXT = "selected_text"

class FlutterBridge(
    private val context: Context,
    readerController: FBReaderApp,
    messenger: BinaryMessenger
) : MethodCallHandler {

    // flutter method通信 有返回值
    private val channel = MethodChannel(messenger, METHOD_CHANNEL_PATH)
    private val contentProcessor = readerController.contentProcessor
    private val gson = Gson()

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Timber.v("$TAG, onMethodCall: ${call.method}, Thread: ${Thread.currentThread().name}")
        when (call.method) {
            DRAW_ON_BITMAP -> {
                // 获取Flutter传递的参数
                val index = call.argument<Int>("page_index")!!
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
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
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
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
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, $LONG_PRESS_MOVE: [$dx, $dy], [$width, $height]")
                contentProcessor.onFingerLongPress(
                    dx, dy,
                    getSelectionCallback(call.method, result), Pair(width, height)
                )
            }
            LONG_PRESS_MOVE -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件,  $LONG_PRESS_MOVE: [$dx, $dy], [$width, $height]")
                contentProcessor.onFingerMoveAfterLongPress(
                    dx, dy,
                    getResultCallback(call.method, result), Pair(width, height)
                )
            }
            LONG_PRESS_END -> {
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, $LONG_PRESS_END [$width, $height]")
                contentProcessor.onFingerReleaseAfterLongPress(
                    0, 0,
                    getSelectionCallback(call.method, result),
                    Pair(width, height)
                )
            }
            ON_TAP_UP -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.onFingerSingleTap(dx, dy, object : PaintListener {
                    override fun repaint(shouldRepaint: Boolean) {
                        Timber.v("时间测试, 重绘返回 $ON_TAP_UP")
                        // 绘制内容的bitmap
                        val bitmap = drawBitmap(PageIndex.CURRENT, width, height)
                        // 回调结果
                        result.success(mapOf("page" to bitmap.toByteArray()))
                    }
                })
            }
            ON_DRAG_START -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, $ON_DRAG_START, [$dx, $dy]")
                contentProcessor.onFingerPress(
                    dx, dy,
                    getResultCallback(call.method, result),
                    Pair(width, height)
                )
            }
            ON_DRAG_MOVE -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, $ON_DRAG_MOVE, [$dx, $dy]")
                contentProcessor.onFingerMove(
                    dx, dy,
                    getResultCallback(call.method, result),
                    Pair(width, height)
                )
            }
            ON_DRAG_END -> {
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.onFingerRelease(
                    0, 0,
                    getSelectionCallback(call.method, result),
                    Pair(width, height)
                )
            }
            SELECTION_CLEAR -> {
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.cleaAllSelectedSections(
                    getResultCallback(
                        call.method,
                        result,
                    ), Pair(width, height)
                )
            }
            SELECTED_TEXT -> {
                val textSnippet = contentProcessor.getSelectedText()
                Timber.v("flutter长按事件, 获得选中文字: $textSnippet")
                result.success(mapOf("text" to textSnippet.text))
            }
        }
    }

    fun invokeMethod(method: String, arguments: Any?, callback: MethodChannel.Result? = null) {
        Timber.v("屏幕尺寸, density = ${context.resources.displayMetrics.density}")
        (context as AppCompatActivity).runOnUiThread {
            channel.invokeMethod(method, arguments, callback)
        }
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
        val drawableId =
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

    private fun getSelectionCallback(
        name: String,
        result: MethodChannel.Result,
    ): SelectionListener {
        return object : SelectionListener {
            override fun onSelection(selectionResult: SelectionResult, img: ByteArray?) {
                Timber.v("时间测试, 重绘返回 $name")
                when (selectionResult) {
                    is SelectionResult.HighlightRegion -> {
                        if (selectionResult.highlightType == Hull.DrawMode.Outline) {
                            result.success(
                                mapOf("highlight_draw_data" to gson.toJson(selectionResult))
                            )
                        } else {
                            result.success(mapOf("page" to img))
                        }
                    }
                    is SelectionResult.ShowMenu -> {
                        result.success(
                            mapOf(
                                "page" to img,
                                "selectionStartY" to selectionResult.selectionStartY,
                                "selectionEndY" to selectionResult.selectionEndY
                            )
                        )
                    }
                    SelectionResult.NoMenu,
                    SelectionResult.None -> result.success(mapOf("page" to img))
                }
            }
        }
    }

    private fun getResultCallback(
        name: String,
        result: MethodChannel.Result,
    ): ResultCallBack {
        return object : ResultCallBack {
            override fun onComplete(data: Any) {
                Timber.v("时间测试, 重绘返回 $name")
                result.success(mapOf("page" to data))
            }
        }
    }

    interface ResultCallBack {
        fun onComplete(data: Any)
    }
}