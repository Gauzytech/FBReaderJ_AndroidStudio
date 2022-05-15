package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
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
class FlutterBridge(
    private val context: Context,
    private val readerController: FBReaderApp,
    messenger: BinaryMessenger
) :
    MethodCallHandler {

    private var channel: MethodChannel = MethodChannel(messenger, "com.flutter.book.reader")
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Timber.v("flutter内容绘制流程, onMethodCall: ${call.method}, Thread: ${Thread.currentThread().name}")

        if (call.method == "draw_on_bitmap") {
            // 获取Flutter传递的参数
            val index = requireNotNull(call.argument<Int>("page_index"))
            val width = requireNotNull(call.argument<Double>("width")).toInt()
            val height = requireNotNull(call.argument<Double>("height")).toInt()
            val pageIndex = PageIndex.getPageIndex(index)
            Timber.v("flutter内容绘制流程 开始绘制: $pageIndex, [$width, $height]")

            // 绘制内容的bitmap
            val bytes = readerController.contentProcessorImpl.drawOnBitmapFlutter(
                pageIndex,
                width,
                height,
                0
            )

            if (DebugHelper.SAVE_BITMAP) {
                val targetPath = "${context.cacheDir}/images/"
                val parent = File(targetPath)
                if (!parent.exists()) {
                    parent.mkdirs()
                }
                Timber.v("flutter内容绘制流程, save path $targetPath")
                val saveFile = File(targetPath, "图书内容bitmap")
                val ops = FileOutputStream(saveFile)
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, ops)
                ops.flush()
                ops.close()
                Timber.v("flutter内容绘制流程, save success!")
            } else {
                result.success(bytes)
            }
        } else if (call.method == "prepare_page") {
            val width = requireNotNull(call.argument<Double>("width")).toInt()
            val height = requireNotNull(call.argument<Double>("height")).toInt()
            val prev = requireNotNull(call.argument<Boolean>("update_prev_page_cache"))
            val next = requireNotNull(call.argument<Boolean>("update_next_page_cache"))
            readerController.contentProcessorImpl.prepareAdjacentPage(
                width,
                height,
                0,
                prev,
                next,
                result
            )
        }
    }

    @MainThread
    fun invokeMethod(method: String, arguments: Any?, callback: MethodChannel.Result?) {
        channel.invokeMethod(method, arguments, callback)
    }

    private fun getTestNativeImage(result: MethodChannel.Result) {
        val drawableId: Int =
            context.resources.getIdentifier("test_img", "drawable", context.packageName)
        val bitmap = BitmapFactory.decodeResource(context.resources, drawableId)
        val baos = ByteArrayOutputStream()
        val isSuccess = bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
        result.success(if (isSuccess) baos.toByteArray() else "")
    }
}