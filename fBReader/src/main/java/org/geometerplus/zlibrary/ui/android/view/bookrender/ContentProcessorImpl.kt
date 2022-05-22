package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import io.flutter.plugin.common.MethodChannel
import org.geometerplus.fbreader.fbreader.FBReaderApp
import org.geometerplus.zlibrary.core.util.SystemInfo
import org.geometerplus.zlibrary.core.view.ZLViewEnums
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import timber.log.Timber
import java.util.concurrent.Executors

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName ContentProcessorImpl
 * @Date 4/25/22, 10:27 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
class ContentProcessorImpl(private val fbReaderApp: FBReaderApp, systemInfo: SystemInfo?) :
    ContentProcessor {
    // 预加载线程
    private val prepareService = Executors.newSingleThreadExecutor()
    private val bookPageProvider: BookPageProvider = BookPageProvider(systemInfo)

    private val targetContentView = fbReaderApp.textView

    override fun drawOnBitmap(
        bitmap: Bitmap,
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    ) {
        bookPageProvider.drawOnBitmap(
            targetContentView,
            bitmap,
            index,
            width,
            height,
            getMainAreaHeight(height),
            verticalScrollbarWidth
        )
    }

    override fun drawOnBitmapFlutter(
        pageIndex: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    ): ByteArray {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
        drawOnBitmap(bitmap, pageIndex, width, height, 0)
        return bitmap.toByteArray()
    }

    override fun onScrollingFinished(index: PageIndex) {
        Timber.v("渲染流程, onSizeChanged -> onScrollingFinished")
        targetContentView.onScrollingFinished(index)
    }

    override fun onRepaintFinished() {
        Timber.v("渲染流程, onRepaintFinished")
        fbReaderApp.onRepaintFinished()
    }

    override fun canScroll(pageToScrollTo: PageIndex): Boolean {
        return targetContentView.canScroll(pageToScrollTo)
    }

    override val animationType: ZLViewEnums.Animation
        get() = targetContentView.animationType
    override val isScrollbarShown: Boolean
        get() = targetContentView.isScrollbarShown

    override fun getScrollbarThumbPosition(pageIndex: PageIndex): Int {
        return targetContentView.getScrollbarThumbPosition(pageIndex)
    }

    override val scrollbarFullSize: Int
        get() = targetContentView.scrollbarFullSize

    override fun getScrollbarThumbLength(pageIndex: PageIndex): Int {
        return targetContentView.getScrollbarThumbLength(pageIndex)
    }

    override fun canMagnifier(): Boolean {
        return targetContentView.canMagnifier()
    }

    override fun hasSelection(): Boolean {
        return targetContentView.hasSelection()
    }

    override fun onFingerLongPress(x: Int, y: Int): Boolean {
        return targetContentView.onFingerLongPress(x, y)
    }

    override fun onFingerSingleTap(x: Int, y: Int) {
        targetContentView.onFingerSingleTap(x, y)
    }

    override fun onTrackballRotated(diffX: Int, diffY: Int): Boolean {
        return targetContentView.onTrackballRotated(diffX, diffY)
    }

    override fun onFingerEventCancelled() {
        targetContentView.onFingerEventCancelled()
    }

    override fun onFingerDoubleTap(x: Int, y: Int) {
        targetContentView.onFingerDoubleTap(x, y)
    }

    override fun onFingerReleaseAfterLongPress(x: Int, y: Int) {
        targetContentView.onFingerReleaseAfterLongPress(x, y)
    }

    override fun onFingerMoveAfterLongPress(x: Int, y: Int) {
        targetContentView.onFingerMoveAfterLongPress(x, y)
    }

    override val isDoubleTapSupported: Boolean
        get() = targetContentView.isDoubleTapSupported

    override fun onFingerRelease(x: Int, y: Int) {
        targetContentView.onFingerRelease(x, y)
    }

    override fun onFingerPress(x: Int, y: Int) {
        targetContentView.onFingerPress(x, y)
    }

    override fun onFingerMove(x: Int, y: Int) {
        targetContentView.onFingerMove(x, y)
    }

    override val isHorizontal: Boolean
        get() = targetContentView.isHorizontal

    override fun getMainAreaHeight(widgetHeight: Int): Int {
        val footer = targetContentView.footerArea
        return if (footer != null) {
            widgetHeight - footer.height
        } else {
            widgetHeight
        }
    }

    override fun setPreview(preview: Boolean) {
        targetContentView.isPreview = preview
    }

    override fun runActionByKey(key: Int, longPress: Boolean): Boolean {
        return fbReaderApp.runActionByKey(key, longPress)
    }

    override fun hasKeyBinding(key: Int, longPress: Boolean): Boolean {
        return fbReaderApp.keyBindings().hasBinding(key, longPress)
    }

    override fun prepareAdjacentPage(width: Int, height: Int, verticalScrollbarWidth: Int) {
        Timber.v("渲染相邻页面, ------------------- 开始 -------------------")
        prepareService.execute {
            // 子线程绘制相邻页面
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.PREV,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            fbReaderApp.cachePageBitmap(PageIndex.PREV)
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.NEXT,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            fbReaderApp.cachePageBitmap(PageIndex.NEXT)
        }
    }

    override fun prepareAdjacentPage(
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int,
        updatePrevPage: Boolean,
        updateNextPage: Boolean,
        resultCallBack: FlutterBridge.ResultCallBack
    ) {
        prepareService.execute {
            Timber.v("flutter内容绘制流程, 准备相邻页面, %s", Thread.currentThread().name)
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.PREV,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            val map: MutableMap<String, Any> = HashMap()
            if (updatePrevPage) {
                map["prev"] = drawOnBitmapFlutter(PageIndex.PREV, width, height, 0)
            }
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.NEXT,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            if (updateNextPage) {
                map["next"] = drawOnBitmapFlutter(PageIndex.NEXT, width, height, 0)
            }
            resultCallBack.onComplete(map)
        }
    }
}