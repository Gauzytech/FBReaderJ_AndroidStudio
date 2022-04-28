package org.geometerplus.zlibrary.ui.android.view.bookrender;

import android.graphics.Bitmap;

import org.geometerplus.zlibrary.core.view.ZLView;
import org.geometerplus.zlibrary.core.view.ZLViewEnums;

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName ContentProcessor
 * @Date 4/24/22, 4:49 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public interface ContentProcessor {

    void drawOnBitmap(Bitmap bitmap, ZLView.PageIndex index, int width, int height, int verticalScrollbarWidth);

    void prepareAdjacentPage(int width, int height, int verticalScrollbarWidth);

    void onScrollingFinished(ZLViewEnums.PageIndex index);

    void onRepaintFinished();

    boolean canScroll(ZLViewEnums.PageIndex pageToScrollTo);

    ZLViewEnums.Animation getAnimationType();

    boolean isScrollbarShown();

    int getScrollbarThumbPosition(ZLViewEnums.PageIndex pageIndex);

    int getScrollbarFullSize();

    int getScrollbarThumbLength(ZLViewEnums.PageIndex pageIndex);

    /**
     * @return 是否可以使用放大镜
     */
    boolean canMagnifier();

    /**
     * @return 有选中的
     */
    boolean hasSelection();

    /**
     * @return 是否水平方向
     */
    boolean isHorizontal();

    boolean onFingerLongPress(int x, int y);

    void onFingerSingleTap(int x, int y);

    void onFingerPress(int x, int y);

    void onFingerMove(int x, int y);

    void onFingerDoubleTap(int x, int y);

    void onFingerEventCancelled();

    void onFingerReleaseAfterLongPress(int x, int y);

    void onFingerMoveAfterLongPress(int x, int y);

    /**
     * 是否双击支持
     *
     * @return 是否双击支持
     */
    boolean isDoubleTapSupported();

    void onFingerRelease(int x, int y);

    boolean onTrackballRotated(int diffX, int diffY);

    /** 获得图书内容可渲染区域的高度 */
    int getMainAreaHeight(int widgetHeight);

    void setPreview(boolean preview);

    boolean runActionByKey(int key, boolean longPress);

    boolean hasKeyBinding(int key, boolean longPress);

}
