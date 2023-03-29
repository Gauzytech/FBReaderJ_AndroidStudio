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
import org.geometerplus.fbreader.fbreader.FBReaderApp
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.BUILD_PAGE_PAINT_DATA
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.CAN_SCROLL
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.DRAW_ON_BITMAP
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.LONG_PRESS_END
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.LONG_PRESS_MOVE
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.LONG_PRESS_START
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.ON_SCROLLING_FINISHED
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.ON_SELECTION_DRAG_END
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.ON_SELECTION_DRAG_MOVE
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.ON_SELECTION_DRAG_START
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.ON_TAP_UP
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.PREPARE_PAGE
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.SELECTED_TEXT
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.SELECTION_CLEAR
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ContentPageResult
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
                Timber.v("$TAG[${System.currentTimeMillis()}] 请求数据: pageIndex = $pageIndex, size = [$width, $height")

                // 绘制内容的bitmap
                contentProcessor.buildPageData(
                    pageIndex,
                    width,
                    height,
                    0
                ).also { pageResult ->
                    when (pageResult) {
                        ContentPageResult.NoOp -> Timber.v("$TAG, no draw")
                        is ContentPageResult.Paint -> {
                            Timber.v("flutter_perf, 发送, ${System.currentTimeMillis()}")
                            result.success(
                                mapOf(
                                    "page_data" to gson.toJson(pageResult),
                                    "width" to width,
                                    "height" to height
                                )
                            )
                        }
                    }
                }

                // 回调结果
                // todo toByteArray这一步太耗时了, 要将绘制bitmap逻辑移到flutter
//                if (DebugHelper.SAVE_BITMAP) {
//                    debugSave(bitmap.toByteArray(), "图书内容bitmap_current.png")
//                } else {
//                    result.success(bitmap.toByteArray())
//                }
            }
            BUILD_PAGE_PAINT_DATA -> {
                val index = call.argument<Int>("page_index")!!

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
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, ${call.method}: [$dx, $dy]")
                contentProcessor.onFingerLongPress(
                    dx,
                    dy,
                    getSelectionCallback(call.method, result),
                    Pair(
                        call.argument<Double>("width")!!.toInt(),
                        call.argument<Double>("height")!!.toInt()
                    )
                )
            }
            LONG_PRESS_MOVE -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件,  ${call.method}: [$dx, $dy]")
                contentProcessor.onFingerMoveAfterLongPress(
                    dx,
                    dy,
                    getSelectionCallback(call.method, result),
                    Pair(call.argument<Int>("width")!!, call.argument<Int>("height")!!)
                )
            }
            LONG_PRESS_END -> {
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, ${call.method} [$width, $height]")
                contentProcessor.onFingerReleaseAfterLongPress(
                    0, 0,
                    getSelectionCallback(call.method, result),
                    Pair(width, height)
                )
            }
            ON_TAP_UP -> {
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.onFingerSingleTap(
                    call.argument<Int>("touch_x")!!.toInt(),
                    call.argument<Int>("touch_y")!!.toInt(),
                    getSelectionCallback(call.method, result)
                )
            }
            ON_SELECTION_DRAG_START -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, ${call.method}, [$dx, $dy]")
                contentProcessor.onFingerPress(
                    dx, dy,
                    getSelectionCallback(call.method, result),
                    Pair(call.argument<Int>("width")!!, call.argument<Int>("height")!!)
                )
            }
            ON_SELECTION_DRAG_MOVE -> {
                val dx = call.argument<Int>("touch_x")!!.toInt()
                val dy = call.argument<Int>("touch_y")!!.toInt()
                val time = call.argument<Long>("time_stamp")!!
                Timber.v("flutter长按事件, ${call.method}, [$dx, $dy]")
                contentProcessor.onFingerMove(
                    dx, dy,
                    getSelectionCallback(call.method, result),
                    Pair(call.argument<Int>("width")!!, call.argument<Int>("height")!!)
                )
            }
            ON_SELECTION_DRAG_END -> {
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.onFingerRelease(
                    0, 0,
                    getSelectionCallback(call.method, result),
                    Pair(call.argument<Int>("width")!!, call.argument<Int>("height")!!)
                )
            }
            SELECTION_CLEAR -> {
                val time = call.argument<Long>("time_stamp")!!
                contentProcessor.cleaAllSelectedSections(
                    getResultCallback(
                        call.method,
                        result,
                    ), Pair(call.argument<Int>("width")!!, call.argument<Int>("height")!!)
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

    private fun drawBitmap(pageIdx: PageIndex, width: Int, height: Int): ContentPageResult {
        // 绘制内容的bitmap
//        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
//        contentProcessor.drawOnBitmap(
//            bitmap,
//            pageIdx,
//            width,
//            height,
//            0
//        )

        return contentProcessor.buildPageData(
            pageIdx,
            width,
            height,
            0)
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
        Timber.v("debug, $targetPath")
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
                    is SelectionResult.Highlight -> {
                        result.success(
                            mapOf("highlights_data" to gson.toJson(selectionResult))
                        )
                    }
                    is SelectionResult.ShowMenu -> {
                        result.success(
                            mapOf("selection_menu_data" to gson.toJson(selectionResult))
                        )
                    }
                    SelectionResult.NoMenu,
                    SelectionResult.NoOp -> result.success(mapOf("page" to img))
                    SelectionResult.OpenDirectory,
                    SelectionResult.OpenImage -> Timber.v("时间测试, outline行为 ${selectionResult.javaClass.simpleName}, 功能待实现")
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

    fun tearDown() {
        channel.setMethodCallHandler(null)
    }

    interface ResultCallBack {
        fun onComplete(data: Any)
    }
}