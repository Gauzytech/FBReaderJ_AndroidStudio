package org.geometerplus.zlibrary.ui.android.view.bookrender;

import android.graphics.Bitmap;

import org.geometerplus.fbreader.fbreader.FBReaderApp;
import org.geometerplus.zlibrary.core.util.SystemInfo;
import org.geometerplus.zlibrary.core.view.ZLView;
import org.geometerplus.zlibrary.core.view.ZLViewEnums;
import org.geometerplus.zlibrary.ui.android.view.BitmapManagerImpl;

import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import timber.log.Timber;

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName ContentProcessorImpl
 * @Date 4/25/22, 10:27 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public class ContentProcessorImpl implements ContentProcessor {
    // 预加载线程
    public final ExecutorService prepareService = Executors.newSingleThreadExecutor();
    private final FBReaderApp fbReaderApp;
    private final BookPageProvider bookPageProvider;

    public ContentProcessorImpl(FBReaderApp fbReaderApp, SystemInfo systemInfo) {
        this.fbReaderApp = fbReaderApp;
        this.bookPageProvider = new BookPageProvider(systemInfo);
    }

    private ZLView targetContent() {
        return fbReaderApp.getTextView();
    }

    @Override
    public void drawOnBitmap(Bitmap bitmap, ZLView.PageIndex index, int width, int height, int verticalScrollbarWidth) {
        bookPageProvider.drawOnBitmap(targetContent(), bitmap, index, width, height, getMainAreaHeight(height), verticalScrollbarWidth);
    }

    @Override
    public void onScrollingFinished(ZLViewEnums.PageIndex index) {
        Timber.v("渲染流程, onSizeChanged -> onScrollingFinished");
        targetContent().onScrollingFinished(index);
    }

    @Override
    public void onRepaintFinished() {
        Timber.v("渲染流程, onRepaintFinished");
        fbReaderApp.onRepaintFinished();
    }

    @Override
    public boolean canScroll(ZLViewEnums.PageIndex pageToScrollTo) {
        return targetContent().canScroll(pageToScrollTo);
    }

    @Override
    public ZLViewEnums.Animation getAnimationType() {
        return targetContent().getAnimationType();
    }

    @Override
    public boolean isScrollbarShown() {
        return targetContent().isScrollbarShown();
    }

    @Override
    public int getScrollbarThumbPosition(ZLViewEnums.PageIndex pageIndex) {
        return targetContent().getScrollbarThumbPosition(pageIndex);
    }

    @Override
    public int getScrollbarFullSize() {
        return targetContent().getScrollbarFullSize();
    }

    @Override
    public int getScrollbarThumbLength(ZLViewEnums.PageIndex pageIndex) {
        return targetContent().getScrollbarThumbLength(pageIndex);
    }

    @Override
    public boolean canMagnifier() {
        return targetContent().canMagnifier();
    }

    @Override
    public boolean hasSelection() {
        return targetContent().hasSelection();
    }

    @Override
    public boolean onFingerLongPress(int x, int y) {
        return targetContent().onFingerLongPress(x, y);
    }

    @Override
    public void onFingerSingleTap(int x, int y) {
        targetContent().onFingerSingleTap(x, y);
    }

    @Override
    public boolean onTrackballRotated(int diffX, int diffY) {
        return targetContent().onTrackballRotated(diffX, diffY);
    }

    @Override
    public void onFingerEventCancelled() {
        targetContent().onFingerEventCancelled();
    }

    @Override
    public void onFingerDoubleTap(int x, int y) {
        targetContent().onFingerDoubleTap(x, y);
    }

    @Override
    public void onFingerReleaseAfterLongPress(int x, int y) {
        targetContent().onFingerReleaseAfterLongPress(x, y);
    }

    @Override
    public void onFingerMoveAfterLongPress(int x, int y) {
        targetContent().onFingerMoveAfterLongPress(x, y);
    }

    @Override
    public boolean isDoubleTapSupported() {
        return targetContent().isDoubleTapSupported();
    }

    @Override
    public void onFingerRelease(int x, int y) {
        targetContent().onFingerRelease(x, y);
    }

    @Override
    public void onFingerPress(int x, int y) {
        targetContent().onFingerPress(x, y);
    }

    @Override
    public void onFingerMove(int x, int y) {
        targetContent().onFingerMove(x, y);
    }

    @Override
    public boolean isHorizontal() {
        return targetContent().isHorizontal();
    }

    @Override
    public int getMainAreaHeight(int widgetHeight) {
        final ZLView.FooterArea footer = targetContent().getFooterArea();
        return footer != null ? widgetHeight - footer.getHeight() : widgetHeight;
    }

    @Override
    public void setPreview(boolean preview) {
        targetContent().setPreview(preview);
    }

    @Override
    public boolean runActionByKey(int key, boolean longPress) {
        return fbReaderApp.runActionByKey(key, longPress);
    }

    @Override
    public boolean hasKeyBinding(int key, boolean longPress) {
        return fbReaderApp.keyBindings().hasBinding(key, longPress);
    }

    @Override
    public void prepareAdjacentPage(int width, int height, int verticalScrollbarWidth) {
        prepareService.execute(() -> {
            bookPageProvider.preparePage(targetContent(), ZLViewEnums.PageIndex.PREV, width, height, getMainAreaHeight(height), verticalScrollbarWidth);
            fbReaderApp.cachePageBitmap(ZLViewEnums.PageIndex.PREV);
            bookPageProvider.preparePage(targetContent(), ZLViewEnums.PageIndex.NEXT, width, height, getMainAreaHeight(height), verticalScrollbarWidth);
            fbReaderApp.cachePageBitmap(ZLViewEnums.PageIndex.NEXT);
        });
    }
}
