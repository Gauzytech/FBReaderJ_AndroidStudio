package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import androidx.annotation.WorkerThread
import org.geometerplus.DebugHelper
import org.geometerplus.fbreader.fbreader.FBReaderApp
import org.geometerplus.fbreader.util.TextSnippet
import org.geometerplus.zlibrary.core.util.SystemInfo
import org.geometerplus.zlibrary.core.view.ZLViewEnums
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ContentPageResult
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.SelectionResult
import timber.log.Timber
import java.util.concurrent.Executors

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName ContentProcessorImpl
 * @Date 4/25/22, 10:27 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
class ContentProcessorImpl(private val fbReaderApp: FBReaderApp, systemInfo: SystemInfo) :
    ContentProcessor {
    // 预加载线程
    private val prepareService = Executors.newSingleThreadExecutor()
    private var drawService = Executors.newFixedThreadPool(4)
    private val bookPageProvider = BookPageProvider(systemInfo)

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

    override fun buildPageData(
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    ): ContentPageResult =
        bookPageProvider.processPageData(
            targetContentView, index,
            width,
            height,
            getMainAreaHeight(height),
            verticalScrollbarWidth
        )

    override fun buildPageDataAsync(
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int,
        resultCallBack: FlutterBridge.ResultCallBack
    ) {
        prepareService.execute {
            val result = bookPageProvider.processPageData(
                targetContentView, index,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            resultCallBack.onComplete(result)
        }
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

    override fun onFingerSingleTap(x: Int, y: Int, selectionListener: SelectionListener?) {
        if (DebugHelper.ENABLE_FLUTTER) {
            selectionListener?.onSelection(targetContentView.onFingerSingleTapFlutter(x, y))
        } else {
            targetContentView.onFingerSingleTap(x, y)
        }
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

    /** 触摸事件: 长按开始 */
    override fun onFingerLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    ): Boolean {
        return if (DebugHelper.ENABLE_FLUTTER) {
            when (val result = targetContentView.onFingerLongPressFlutter(x, y)) {
                is SelectionResult.Highlight -> selectionListener?.onSelection(result)
                else -> Unit
            }
            return false
        } else {
            targetContentView.onFingerLongPress(x, y)
        }
    }

    /** 触摸事件: 长按移动 */
    override fun onFingerMoveAfterLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    ) {
        if (DebugHelper.ENABLE_FLUTTER) {
            when(val result = targetContentView.onFingerMoveAfterLongPressFlutter(x, y)) {
                is SelectionResult.Highlight -> selectionListener?.onSelection(result)
                else -> Unit
            }
        } else {
            targetContentView.onFingerMoveAfterLongPress(x, y)
        }
    }

    /** 触摸事件: 长按结束 */
    override fun onFingerReleaseAfterLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    ) {
        if (DebugHelper.ENABLE_FLUTTER) {
            when (val result = targetContentView.onFingerReleaseAfterLongPressFlutter(x, y)) {
                is SelectionResult.ShowMenu,
                is SelectionResult.Highlight,
                is SelectionResult.OpenDirectory,
                is SelectionResult.OpenImage -> selectionListener?.onSelection(result)
                else -> Unit
            }
        } else {
            targetContentView.onFingerReleaseAfterLongPress(x, y)
        }
    }

    override val isDoubleTapSupported: Boolean
        get() = targetContentView.isDoubleTapSupported

    override fun onFingerRelease(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    ) {
        if (DebugHelper.ENABLE_FLUTTER) {
            when (val result = targetContentView.onFingerReleaseFlutter(x, y)) {
                is SelectionResult.ShowMenu,
                is SelectionResult.NoMenu -> {
//                    drawService.execute {
//                        selectionListener?.onSelection(result, drawCurrentPage(size!!))
//                    }
                    selectionListener?.onSelection(result)
                }
                is SelectionResult.Highlight -> selectionListener?.onSelection(result)
                else -> Unit
            }
        } else {
            targetContentView.onFingerRelease(x, y)
        }
    }

    override fun onFingerPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    ) {
        if (DebugHelper.ENABLE_FLUTTER) {
            when (val result = targetContentView.onFingerPressFlutter(x, y)) {
                is SelectionResult.Highlight -> selectionListener?.onSelection(result)
                else -> Unit
            }
        } else {
            targetContentView.onFingerPress(x, y)
        }
    }

    override fun onFingerMove(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    ) {
        if (DebugHelper.ENABLE_FLUTTER) {
            val result = targetContentView.onFingerMoveFlutter(x, y)
            Timber.v("时间测试, onFingerMove 返回结果 ${result.javaClass.simpleName}")
            when(result) {
                is SelectionResult.Highlight -> selectionListener?.onSelection(result)
                else -> Unit
            }
        } else {
            targetContentView.onFingerMove(x, y)
        }
    }

    @WorkerThread
    private fun drawCurrentPage(size: Pair<Int, Int>): ByteArray {
        val (width, height) = size
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        drawOnBitmap(
            bitmap,
            PageIndex.CURRENT,
            width,
            height,
            0
        )
        return bitmap.toByteArray()
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
        prepareService.execute {
            // 子线程绘制相邻页面
            Timber.v("渲染流程[相邻页面], ------------------- 准备prev开始 -------------------")
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.PREV,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            Timber.v("渲染流程[相邻页面], ------------------- 准备prev结束 -------------------")
            fbReaderApp.cachePageBitmap(PageIndex.PREV)
            Timber.v("渲染流程[相邻页面], ------------------- 准备next开始 -------------------")
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.NEXT,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            Timber.v("渲染流程[相邻页面], ------------------- 准备next结束 -------------------")
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
            val map: MutableMap<String, Any> = HashMap()
            bookPageProvider.preparePage(
                targetContentView,
                PageIndex.PREV,
                width,
                height,
                getMainAreaHeight(height),
                verticalScrollbarWidth
            )
            if (updatePrevPage) {
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                drawOnBitmap(bitmap, PageIndex.PREV, width, height, 0)
                map["prev"] = bitmap.toByteArray()
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
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                drawOnBitmap(bitmap, PageIndex.NEXT, width, height, 0)
                map["next"] = bitmap.toByteArray()
            }
            resultCallBack.onComplete(map)
        }
    }

    override fun cleaAllSelectedSections(resultCallBack: FlutterBridge.ResultCallBack?, size: Pair<Int, Int>) {
        if (targetContentView.cleaAllSelectedSections()) {
            resultCallBack?.onComplete(drawCurrentPage(size))
        }
    }

    override fun getSelectedText(): TextSnippet {
        return targetContentView.selectedSnippet
    }
}