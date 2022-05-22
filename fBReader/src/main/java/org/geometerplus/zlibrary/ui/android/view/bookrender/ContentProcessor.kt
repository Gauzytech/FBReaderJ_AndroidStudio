package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import org.geometerplus.zlibrary.core.view.ZLViewEnums
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex

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

    fun drawOnBitmapFlutter(
        index: PageIndex,
        width: Int,
        height: Int,
        verticalScrollbarWidth: Int
    ): ByteArray

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
    fun onFingerLongPress(x: Int, y: Int): Boolean
    fun onFingerSingleTap(x: Int, y: Int)
    fun onFingerPress(x: Int, y: Int)
    fun onFingerMove(x: Int, y: Int)
    fun onFingerDoubleTap(x: Int, y: Int)
    fun onFingerEventCancelled()
    fun onFingerReleaseAfterLongPress(x: Int, y: Int)
    fun onFingerMoveAfterLongPress(x: Int, y: Int)

    /**
     * 是否双击支持
     *
     * @return 是否双击支持
     */
    val isDoubleTapSupported: Boolean
    fun onFingerRelease(x: Int, y: Int)
    fun onTrackballRotated(diffX: Int, diffY: Int): Boolean

    /** 获得图书内容可渲染区域的高度  */
    fun getMainAreaHeight(widgetHeight: Int): Int
    fun setPreview(preview: Boolean)
    fun runActionByKey(key: Int, longPress: Boolean): Boolean
    fun hasKeyBinding(key: Int, longPress: Boolean): Boolean
}