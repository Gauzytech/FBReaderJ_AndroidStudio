package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import org.geometerplus.fbreader.util.TextSnippet
import org.geometerplus.zlibrary.core.view.ZLViewEnums
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ContentPageResult

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName ContentProcessor
 * @Date 4/24/22, 4:49 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
interface ContentProcessor {
    fun drawOnBitmap(
        bitmap: Bitmap,
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    )

    /**
     * 获得[index]相关page的绘制数据
     */
    fun buildPageData(
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    ): ContentPageResult

    fun buildPageDataAsync(
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int,
        resultCallBack: FlutterBridge.ResultCallBack,
    )

    fun prepareAdjacentPage(width: Int, height: Int, verticalScrollbarWidth: Int)
    fun prepareAdjacentPage(
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int,
        updatePrevPage: Boolean,
        updateNextPage: Boolean,
        resultCallBack: FlutterBridge.ResultCallBack,
    )

    fun onScrollingFinished(index: PageIndex)
    fun onRepaintFinished()
    fun canScroll(pageToScrollTo: PageIndex): Boolean
    val animationType: ZLViewEnums.Animation
    val isScrollbarShown: Boolean
    fun getScrollbarThumbPosition(pageIndex: PageIndex): Int
    val scrollbarFullSize: Int
    fun getScrollbarThumbLength(pageIndex: PageIndex): Int

    /**
     * @return 是否可以使用放大镜
     */
    fun canMagnifier(): Boolean

    /**
     * @return 有选中的
     */
    fun hasSelection(): Boolean

    /**
     * @return 是否水平方向
     */
    val isHorizontal: Boolean

    /** 点击事件 */
    fun onFingerSingleTap(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?
    )

    fun onFingerPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    )

    fun onFingerMove(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    )

    fun onFingerRelease(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
        size: Pair<Int, Int>?
    )

    fun onFingerDoubleTap(x: Int, y: Int)
    fun onFingerEventCancelled()

    /** 长按事件 */
    fun onFingerLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    ): Boolean

    /** 长按移动事件 */
    fun onFingerMoveAfterLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    )

    /** 长按结束事件 */
    fun onFingerReleaseAfterLongPress(
        x: Int,
        y: Int,
        selectionListener: SelectionListener?,
    )

    /** 是否双击支持 */
    val isDoubleTapSupported: Boolean

    fun onTrackballRotated(diffX: Int, diffY: Int): Boolean

    /** 获得图书内容可渲染区域的高度  */
    fun getMainAreaHeight(widgetHeight: Int): Int
    fun setPreview(preview: Boolean)
    fun runActionByKey(key: Int, longPress: Boolean): Boolean
    fun hasKeyBinding(key: Int, longPress: Boolean): Boolean

    /** 清除所有选中内容 */
    fun cleaAllSelectedSections(
        resultCallBack: FlutterBridge.ResultCallBack?,
        size: Pair<Int, Int>
    )

    /** 获得选中文字 */
    fun getSelectedText(): TextSnippet
}