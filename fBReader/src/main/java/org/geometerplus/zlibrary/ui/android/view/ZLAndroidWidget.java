/*
 * Copyright (C) 2007-2015 FBReader.ORG Limited <contact@fbreader.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

package org.geometerplus.zlibrary.ui.android.view;

import android.animation.Animator;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PaintFlagsDrawFilter;
import android.graphics.Path;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;

import org.geometerplus.DebugHelper;
import org.geometerplus.android.fbreader.FBReader;
import org.geometerplus.android.fbreader.constant.PreviewConfig;
import org.geometerplus.android.fbreader.util.SizeUtils;
import org.geometerplus.fbreader.Paths;
import org.geometerplus.zlibrary.core.application.ZLApplication;
import org.geometerplus.zlibrary.core.util.SystemInfo;
import org.geometerplus.zlibrary.core.view.ZLView;
import org.geometerplus.zlibrary.core.view.ZLViewEnums;
import org.geometerplus.zlibrary.core.view.ZLViewWidget;
import org.geometerplus.zlibrary.ui.android.R;
import org.geometerplus.zlibrary.ui.android.view.animation.AnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.CurlAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.NoneAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.PreviewShiftAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.ShiftAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.SlideAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.animation.SlideOldStyleAnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.bookrender.ContentProcessor;
import org.geometerplus.zlibrary.ui.android.view.callbacks.BookMarkCallback;

import timber.log.Timber;

public class ZLAndroidWidget extends MainView implements ZLViewWidget, View.OnLongClickListener {

    // 放大镜的半径
    private static final float RADIUS = 124;
    private static final float TARGET_DIAMETER = 2 * RADIUS * 333 / 293;
    private static final float MAGNIFIER_MARGIN = 144;
    // 放大倍数
    private static final float FACTOR = 1f;
    /**
     * 预加载线程
     */
//    public final ExecutorService prepareService = Executors.newSingleThreadExecutor();
    private final Paint myPaint = new Paint();
    private final BitmapManagerImpl myBitmapManager = new BitmapManagerImpl(this);
    private final SystemInfo mySystemInfo;
    private Bitmap myFooterBitmap;
    /**
     * 绘制bitmap抗锯齿
     */
    private PaintFlagsDrawFilter paintFlagsDrawFilter = new PaintFlagsDrawFilter(0,
            Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    /**
     * 缩放比
     */
    private float mScale = 1f;
    private Path mPath = new Path();
    private Matrix matrix = new Matrix();
    private Bitmap ovalBitmap;
    private float mCurrentX;
    private float mCurrentY;
    private AnimationProvider myAnimationProvider;
    private ZLView.Animation myAnimationType;
    private BookMarkCallback bookMarkCallback;
    /**
     * 是否是预览模式
     */
    private boolean isPreview = false;
    /**
     * 边框
     */
    private Paint borderPaint = new Paint();
    private volatile LongClickRunnable myPendingLongClickRunnable;
    private volatile boolean myLongClickPerformed;
    private volatile ShortClickRunnable myPendingShortClickRunnable;
    private volatile boolean myPendingPress;
    private volatile boolean myPendingDoubleTap;
    private int myPressedX, myPressedY;
    private int mStartRawY;
    private boolean myScreenIsTouched;
    /**
     * 垂直方向移动
     */
    private boolean isMoveVertical = false;
    private int markState = 0;
    private int myKeyUnderTracking = -1;
    private long myTrackingStartTime;

    ContentProcessor contentProcessor;

    public ZLAndroidWidget(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        mySystemInfo = Paths.systemInfo(context);
        init();
    }

    private void init() {
        // next line prevent ignoring first onKeyDown DPad event
        // after any dialog was closed
        setFocusableInTouchMode(true);
        setDrawingCacheEnabled(false);
        setOnLongClickListener(this);

        borderPaint.setColor(0xFFFF6B00);
        borderPaint.setStrokeWidth(PreviewConfig.PREVIEW_STROKE_WIDTH * 2);
        borderPaint.setStyle(Paint.Style.STROKE);

        mPath.addCircle(RADIUS, RADIUS, RADIUS, Path.Direction.CCW);
        matrix.setScale(FACTOR, FACTOR);

        ovalBitmap = BitmapFactory.decodeResource(getResources(), R.drawable.reader_oval);
        ovalBitmap = scaleBitmap(ovalBitmap);
    }

    private Bitmap scaleBitmap(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        float scaleX = TARGET_DIAMETER / ((float) width);
        float scaleY = TARGET_DIAMETER / ((float) height);
        Matrix matrix = new Matrix();
        matrix.postScale(scaleX, scaleY);
        return Bitmap.createBitmap(bitmap, 0, 0, width, height, matrix, true);
    }

    public ZLAndroidWidget(Context context, AttributeSet attrs) {
        super(context, attrs);
        mySystemInfo = Paths.systemInfo(context);
        init();
    }

    public ZLAndroidWidget(Context context) {
        super(context);
        mySystemInfo = Paths.systemInfo(context);
        init();
    }

    private void onDrawInScrolling(Canvas canvas) {
        Timber.v("渲染流程, onDrawInScrolling -> getCurrentView");

        final AnimationProvider animator = getAnimationProvider("onDrawInScrolling");
        Timber.v("翻页动画, %s", animator.getClass().getSimpleName());
        final AnimationProvider.Mode oldMode = animator.getMode();
        animator.doStep();
        if (animator.inProgress()) {
            animator.draw(canvas);
            if (animator.getMode().Auto) {
                postInvalidate();
            }
            // drawFooter(canvas, animator);
        } else {
            Timber.v("渲染流程:绘制, call onDrawStatic");
            switch (oldMode) {
                case AnimatedScrollingForward: {
                    // progress直接记录在textPage上, 所以这里我们直接说需要上一页/下一页就行了
                    final ZLView.PageIndex index = animator.getPageToScrollTo();
                    myBitmapManager.shift(index == ZLView.PageIndex.NEXT);
                    contentProcessor.onScrollingFinished(index);
                    contentProcessor.onRepaintFinished();
                    break;
                }
                case AnimatedScrollingBackward:
                    contentProcessor.onScrollingFinished(ZLViewEnums.PageIndex.CURRENT);
                    break;
            }
            onDrawStatic(canvas, "onDrawInScrolling");
        }
    }

    @Override
    public void reset(String from) {
        Timber.v("打开图书:渲染流程, 清空bitmap缓存, %s", from);
        myBitmapManager.reset();
    }

    @Override
    public void repaint(String from) {
        // debug需求: 先把底部总页码渲染关掉
        if (!DebugHelper.FOOTER_PAGE_COUNT_ENABLE && from.equals("Footer.run")) return;
        if (!DebugHelper.ON_START_REPAINT && from.equals("onStart")) return;

        Timber.v("渲染流程:绘制, 刷新view %s", from);
        // 不是每次都会执行onDraw()
        // 不执行原因
        // 1. 自定义的View所在的布局中,自定义View计算不出位置.
        // 2. 确定不了View宽和高
        // 3. 在onMeasure()方法中没设置控件的宽和高
        // onDraw调用需要两个条件，
        // 1，View背景不透明
        // 2，View高宽不为0
        postInvalidate();
    }

    @Override
    public void startManualScrolling(int x, int y, ZLView.Direction direction) {
        final AnimationProvider animator = getAnimationProvider("startManualScrolling");
        animator.setup(direction, getWidth(), getMainAreaHeight("startManualScrolling"), myColorLevel);
        animator.startManualScrolling(x, y);
    }

    @Override
    public void scrollManuallyTo(int x, int y) {
        Timber.v("渲染流程, scrollManuallyTo -> getCurrentView");
        final AnimationProvider animator = getAnimationProvider("scrollManuallyTo");
        if (contentProcessor.canScroll(animator.getPageToScrollTo(x, y))) {
            animator.scrollTo(x, y);
            postInvalidate();
        }
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        Timber.v("渲染流程, 第一次启动 -> onSizeChanged, 之后会调用onLayout");
        if (contentProcessor != null) {
            getAnimationProvider("onSizeChanged").terminate();
            if (myScreenIsTouched) {
                myScreenIsTouched = false;
                contentProcessor.onScrollingFinished(ZLView.PageIndex.CURRENT);
            }
        }
    }

    @Override
    public void startAnimatedScrolling(ZLView.PageIndex pageIndex, int x, int y, ZLView.Direction direction, int speed) {
        Timber.v("渲染流程, startAnimatedScrolling -> getCurrentView");
        if (pageIndex == ZLView.PageIndex.CURRENT || !contentProcessor.canScroll(pageIndex)) {
            return;
        }
        final AnimationProvider animator = getAnimationProvider("startAnimatedScrolling");
        animator.setup(direction, getWidth(), getMainAreaHeight("startAnimatedScrolling"), myColorLevel);
        animator.startAnimatedScrolling(pageIndex, x, y, speed);
        if (animator.getMode().Auto) {
            postInvalidate();
        }
    }

    @Override
    public void startAnimatedScrolling(ZLView.PageIndex pageIndex, ZLView.Direction direction, int speed) {
        Timber.v("渲染流程, startAnimatedScrolling -> getCurrentView");
        if (pageIndex == ZLView.PageIndex.CURRENT || !contentProcessor.canScroll(pageIndex)) {
            return;
        }
        final AnimationProvider animator = getAnimationProvider("startAnimatedScrolling");
        animator.setup(direction, getWidth(), getMainAreaHeight("startAnimatedScrolling"), myColorLevel);
        animator.startAnimatedScrolling(pageIndex, null, null, speed);
        if (animator.getMode().Auto) {
            postInvalidate();
        }
    }

    @Override
    public void startAnimatedScrolling(int x, int y, int speed) {
        Timber.v("渲染流程, startAnimatedScrolling -> getCurrentView");
        final AnimationProvider animator = getAnimationProvider("startAnimatedScrolling");
        if (!contentProcessor.canScroll(animator.getPageToScrollTo(x, y))) {
            animator.terminate();
            return;
        }
        animator.startAnimatedScrolling(x, y, speed);
        postInvalidate();
    }

    private AnimationProvider getAnimationProvider(String from) {
        Timber.v("渲染流程, %s -> getAnimationProvider", from);
        final ZLView.Animation type = contentProcessor.getAnimationType();
        if (myAnimationProvider == null || myAnimationType != type) {
            myAnimationType = type;
            switch (type) {
                case none:
                case previewNone:
                    myAnimationProvider = new NoneAnimationProvider(myBitmapManager);
                    break;
                case curl:
                    myAnimationProvider = new CurlAnimationProvider(myBitmapManager);
                    break;
                case slide:
                    myAnimationProvider = new SlideAnimationProvider(myBitmapManager);
                    break;
                case slideOldStyle:
                    myAnimationProvider = new SlideOldStyleAnimationProvider(myBitmapManager);
                    break;
                case shift:
                    myAnimationProvider = new ShiftAnimationProvider(myBitmapManager);
                case previewShift:
                    myAnimationProvider = new PreviewShiftAnimationProvider(myBitmapManager);
                    break;
            }
        }
        return myAnimationProvider;
    }

    private int getMainAreaHeight(String from) {
        Timber.v("打开图书:渲染流程, %s -> getMainAreaHeight", from);
        return contentProcessor.getMainAreaHeight(getHeight());
    }

    public void setBookMarkCallback(BookMarkCallback bookMarkCallback) {
        this.bookMarkCallback = bookMarkCallback;
    }

    /**
     * 在Bitmap上绘制
     * 创建一个空白的canvas, 将当前页的内容绘制在canvas上面
     *
     * @param bitmap Bitmap
     * @param index  页面索引
     */
    void drawOnBitmap(Bitmap bitmap, ZLView.PageIndex index) {
        Timber.v("渲染流程, drawOnBitmap, 在Bitmap上绘制");
        contentProcessor.drawOnBitmap(bitmap, index, getWidth(), getHeight(), getVerticalScrollbarWidth());
    }

    private void drawFooter(Canvas canvas, AnimationProvider animator) {
        final ZLView view = ZLApplication.Instance().getCurrentView();
        final ZLView.FooterArea footer = view.getFooterArea();

        if (footer == null) {
            myFooterBitmap = null;
            return;
        }

        if (myFooterBitmap != null &&
                (myFooterBitmap.getWidth() != getWidth() ||
                        myFooterBitmap.getHeight() != footer.getHeight())) {
            myFooterBitmap = null;
        }
        if (myFooterBitmap == null) {
            myFooterBitmap = Bitmap.createBitmap(getWidth(), footer.getHeight(), Bitmap.Config.RGB_565);
        }
        final ZLAndroidPaintContext context = new ZLAndroidPaintContext(
                mySystemInfo,
                new Canvas(myFooterBitmap),
                new ZLAndroidPaintContext.Geometry(
                        getWidth(),
                        getHeight(),
                        getWidth(),
                        footer.getHeight(),
                        0,
                        getMainAreaHeight("drawFooter")
                ),
                view.isScrollbarShown() ? getVerticalScrollbarWidth() : 0
        );
        footer.paint(context);
        final int voffset = getHeight() - footer.getHeight();
        if (animator != null) {
            animator.drawFooterBitmap(canvas, myFooterBitmap, voffset);
        } else {
            canvas.drawBitmap(myFooterBitmap, 0, voffset, myPaint);
        }
    }

    /**
     * 设置是否是预览模式
     *
     * @param preview 预览
     */
    public void setPreview(boolean preview) {
        mScale = preview ? PreviewConfig.SCALE_VALUE : 1f;
        isPreview = preview;
        if (myAnimationProvider instanceof PreviewShiftAnimationProvider) {
            ((PreviewShiftAnimationProvider) myAnimationProvider).setPreview(isPreview);
        }
        contentProcessor.setPreview(isPreview);
        postInvalidate();
    }

    private void onDrawStatic(final Canvas canvas, String from) {
        Timber.v("渲染流程:绘制, ----------------------------- 非滚动绘制, isPreview = %s ------------%s--------->", isPreview, from);
        // 点击屏幕, 缩略图有效果
        if (isPreview) {
            canvas.drawBitmap(myBitmapManager.getBitmap(ZLView.PageIndex.PREV, "onDrawStatic.PREV"), -getWidth() - getWidth() * PreviewConfig.SCALE_MARGIN_VALUE, 0, myPaint);
            // 绘制边框
            canvas.drawRect(0, 0, getWidth(), getHeight(), borderPaint);
        }
        // 获取内容的bitmap
        Bitmap bitmap = myBitmapManager.getBitmap(ZLView.PageIndex.CURRENT, "onDrawStatic.CURRENT");
        // 将bitmap类所代表的的画布会被显示在屏幕上
        canvas.drawBitmap(bitmap, 0, 0, myPaint);
        if (isPreview) {
            canvas.drawBitmap(myBitmapManager.getBitmap(ZLView.PageIndex.NEXT, "onDrawStatic.NEXT"), getWidth() + getWidth() * PreviewConfig.SCALE_MARGIN_VALUE, 0, myPaint);
        }

        Timber.v("渲染流程, onDrawStatic -> getCurrentView.canMagnifier");

        if (contentProcessor.canMagnifier()) {
            drawMagnifier(canvas, bitmap);
        }

        if (DebugHelper.ENABLE_PRELOAD_ADJACENT_PAGE) {
            Timber.v("渲染流程[相邻页面], %s", myBitmapManager.cachedIndexString());
            post(() -> contentProcessor.prepareAdjacentPage(
                    getWidth(),
                    getHeight(),
                    getVerticalScrollbarWidth()));
        }
    }

    /**
     * 准备前后页面
     *
     * @param pageIndex 页面
     */
    @Override
    public void cacheBitmap(ZLViewEnums.PageIndex pageIndex) {
        myBitmapManager.getBitmap(pageIndex, "准备相邻页面 -> cachePageBitmap -> cacheBitmap");
        Timber.v("渲染流程[相邻页面], %s", myBitmapManager.cachedIndexString());
    }

    /**
     * 放大镜功能
     */
    private void drawMagnifier(Canvas canvas, Bitmap bitmap) {
        // 剪切
        canvas.save();
        canvas.translate(mCurrentX - RADIUS, mCurrentY - RADIUS - MAGNIFIER_MARGIN);
        canvas.clipPath(mPath);
        // 画放大后的图
        canvas.translate(RADIUS - mCurrentX * FACTOR, RADIUS - mCurrentY * FACTOR);
        canvas.drawBitmap(bitmap, matrix, null);
        canvas.restore();
        canvas.save();
        canvas.translate(mCurrentX - TARGET_DIAMETER / 2, mCurrentY - TARGET_DIAMETER / 2 - MAGNIFIER_MARGIN);
        canvas.drawBitmap(ovalBitmap, 0, 0, null);
        canvas.restore();
    }

    @Override
    public boolean onLongClick(View v) {
        return contentProcessor.onFingerLongPress(myPressedX, myPressedY);
    }

    @Override
    protected void updateColorLevel() {
        ViewUtil.setColorLevel(myPaint, myColorLevel);
    }

    private class LongClickRunnable implements Runnable {
        @Override
        public void run() {
            if (performLongClick()) {
                myLongClickPerformed = true;
            }
        }
    }

    private class ShortClickRunnable implements Runnable {
        @Override
        public void run() {
            contentProcessor.onFingerSingleTap(myPressedX, myPressedY);
            myPendingPress = false;
            myPendingShortClickRunnable = null;
        }
    }

    @Override
    protected void onDraw(final Canvas canvas) {
        Timber.v("渲染流程, 绘制被触发");
        if (contentProcessor == null) return;

        canvas.setDrawFilter(paintFlagsDrawFilter);

        // 画布缩放
        canvas.scale(mScale, mScale, getWidth() * PreviewConfig.SCALE_VALUE_PX, getHeight() * PreviewConfig.SCALE_VALUE_PY);

        final Context context = getContext();
        if (context instanceof FBReader) {
            ((FBReader) context).createWakeLock();
        } else {
            System.err.println("A surprise: view's context is not an FBReader");
        }
        super.onDraw(canvas);

        myBitmapManager.setSize(getWidth(), getMainAreaHeight("onDraw"));
        // 判断程序是否处在翻页动画中
        if (getAnimationProvider("onDraw").inProgress()) {
            onDrawInScrolling(canvas);
        } else {
            onDrawStatic(canvas, "onDraw");
            contentProcessor.onRepaintFinished();
        }
    }

    /**
     * 垂直方向
     *
     * @param y1 起始Y
     * @param y2 当前Y
     */
    private void onMoveVertical(int y1, int y2) {
        if (isPreview) {
            return;
        }
        isMoveVertical = true;
        int distance = y2 - y1;
        if (distance < 0) {
            distance = 0;
        }

        int max = SizeUtils.dp2px(getContext(), 100);

        distance = (int) Math.pow(distance, 5 / 6d);

        if (distance > max) {
            distance = max;
        }

        if (bookMarkCallback != null) {
            if (distance > max / 2) {
                if (markState != 2) {
                    bookMarkCallback.onChanging();
                    markState = 2;
                }
            } else {
                if (markState != 1) {
                    bookMarkCallback.onCanceling();
                    markState = 1;
                }
            }
        }

        setTranslationY(distance);
    }


    @Override
    public boolean onTrackballEvent(MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
            onKeyDown(KeyEvent.KEYCODE_DPAD_CENTER, null);
        } else {
            contentProcessor.onTrackballRotated((int) (10 * event.getX()), (int) (10 * event.getY()));
        }
        return true;
    }


    private void postLongClickRunnable() {
        myLongClickPerformed = false;
        myPendingPress = false;
        if (myPendingLongClickRunnable == null) {
            myPendingLongClickRunnable = new LongClickRunnable();
        }
        postDelayed(myPendingLongClickRunnable, 2 * ViewConfiguration.getLongPressTimeout());
    }


    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int x = (int) event.getX();
        int y = (int) event.getY();
        mCurrentX = x;
        mCurrentY = y;
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                markState = 0;
                if (myPendingShortClickRunnable != null) {
                    removeCallbacks(myPendingShortClickRunnable);
                    myPendingShortClickRunnable = null;
                    myPendingDoubleTap = true;
                } else {
                    postLongClickRunnable();
                    myPendingPress = true;
                }
                myScreenIsTouched = true;
                myPressedX = x;
                myPressedY = y;
                mStartRawY = (int) event.getRawY();
                break;
            case MotionEvent.ACTION_CANCEL:
                myPendingDoubleTap = false;
                myPendingPress = false;
                myScreenIsTouched = false;
                myLongClickPerformed = false;
                if (myPendingShortClickRunnable != null) {
                    removeCallbacks(myPendingShortClickRunnable);
                    myPendingShortClickRunnable = null;
                }
                if (myPendingLongClickRunnable != null) {
                    removeCallbacks(myPendingLongClickRunnable);
                    myPendingLongClickRunnable = null;
                }
                contentProcessor.onFingerEventCancelled();
                // 复位
                resetTranslateY(false);
                break;
            case MotionEvent.ACTION_UP:
                if (myPendingDoubleTap) {
                    contentProcessor.onFingerDoubleTap(x, y);
                } else if (myLongClickPerformed) {
                    contentProcessor.onFingerReleaseAfterLongPress(x, y);
                } else {
                    if (myPendingLongClickRunnable != null) {
                        removeCallbacks(myPendingLongClickRunnable);
                        myPendingLongClickRunnable = null;
                    }
                    if (myPendingPress) {
                        if (contentProcessor.isDoubleTapSupported()) {
                            if (myPendingShortClickRunnable == null) {
                                myPendingShortClickRunnable = new ShortClickRunnable();
                            }
                            postDelayed(myPendingShortClickRunnable, ViewConfiguration.getDoubleTapTimeout());
                        } else {
                            contentProcessor.onFingerSingleTap(x, y);
                        }
                    } else {
                        contentProcessor.onFingerRelease(x, y);
                    }
                }
                myPendingDoubleTap = false;
                myPendingPress = false;
                myScreenIsTouched = false;
                // 复位
                resetTranslateY(true);
                break;
            case MotionEvent.ACTION_MOVE: {
                final int slop = ViewConfiguration.get(getContext()).getScaledTouchSlop();
                final boolean isAMove = Math.abs(myPressedX - x) > slop || Math.abs(myPressedY - y) > slop;
                if (isAMove) {
                    myPendingDoubleTap = false;
                }
                if (myLongClickPerformed) {
                    contentProcessor.onFingerMoveAfterLongPress(x, y);
                } else {
                    if (myPendingPress) {
                        if (isAMove) {
                            if (myPendingShortClickRunnable != null) {
                                removeCallbacks(myPendingShortClickRunnable);
                                myPendingShortClickRunnable = null;
                            }
                            if (myPendingLongClickRunnable != null) {
                                removeCallbacks(myPendingLongClickRunnable);
                            }
                            contentProcessor.onFingerPress(myPressedX, myPressedY);
                            myPendingPress = false;
                        }
                    }
                    if (!myPendingPress) {
                        // 有选中的情况，都交给onFingerMove
                        if (contentProcessor.hasSelection() || !contentProcessor.isHorizontal()) {
                            contentProcessor.onFingerMove(x, y);
                        } else {
                            if (Math.abs(myPressedX - x) < Math.abs(myPressedY - y) || isMoveVertical) {
                                onMoveVertical(mStartRawY, (int) event.getRawY());
                            } else {
                                Timber.v("native横向翻页动画, onFingerMove");
                                contentProcessor.onFingerMove(x, y);
                            }
                        }
                    }
                }
                break;
            }
        }

        return true;
    }


    /**
     * 恢复Y方向的位移
     */
    private void resetTranslateY(boolean isUp) {
        if (isPreview) {
            return;
        }
        if (!isMoveVertical) {
            return;
        }
        animate().setDuration(200)
                .translationY(0)
                .setListener(new Animator.AnimatorListener() {
                    @Override
                    public void onAnimationStart(Animator animation) {

                    }

                    @Override
                    public void onAnimationEnd(Animator animation) {
                        if (markState == 2 && bookMarkCallback != null && isUp) {
                            bookMarkCallback.onChanged();
                        }
                    }

                    @Override
                    public void onAnimationCancel(Animator animation) {

                    }

                    @Override
                    public void onAnimationRepeat(Animator animation) {

                    }
                })
                .start();
        isMoveVertical = false;
    }


    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {

        if (contentProcessor.hasKeyBinding(keyCode, true) ||
                contentProcessor.hasKeyBinding(keyCode, false)) {
            if (myKeyUnderTracking != -1) {
                if (myKeyUnderTracking == keyCode) {
                    return true;
                } else {
                    myKeyUnderTracking = -1;
                }
            }
            if (contentProcessor.hasKeyBinding(keyCode, true)) {
                myKeyUnderTracking = keyCode;
                myTrackingStartTime = System.currentTimeMillis();
                return true;
            } else {
                return contentProcessor.runActionByKey(keyCode, false);
            }
        } else {
            return false;
        }
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (myKeyUnderTracking != -1) {
            if (myKeyUnderTracking == keyCode) {
                final boolean longPress = System.currentTimeMillis() >
                        myTrackingStartTime + ViewConfiguration.getLongPressTimeout();
                contentProcessor.runActionByKey(keyCode, longPress);
            }
            myKeyUnderTracking = -1;
            return true;
        } else {
            return contentProcessor.hasKeyBinding(keyCode, false)
                    || contentProcessor.hasKeyBinding(keyCode, true);
        }
    }

    @Override
    protected int computeVerticalScrollExtent() {
        if (contentProcessor == null || !contentProcessor.isScrollbarShown()) {
            return 0;
        }
        final AnimationProvider animator = getAnimationProvider("computeVerticalScrollExtent");
        if (animator.inProgress()) {
            final int from = contentProcessor.getScrollbarThumbLength(ZLView.PageIndex.CURRENT);
            final int to = contentProcessor.getScrollbarThumbLength(animator.getPageToScrollTo());
            final int percent = animator.getScrolledPercent();
            return (from * (100 - percent) + to * percent) / 100;
        } else {
            return contentProcessor.getScrollbarThumbLength(ZLView.PageIndex.CURRENT);
        }
    }

    @Override
    protected int computeVerticalScrollOffset() {
        if (contentProcessor == null || !contentProcessor.isScrollbarShown()) {
            return 0;
        }
        final AnimationProvider animator = getAnimationProvider("computeVerticalScrollOffset");
        if (animator.inProgress()) {
            final int from = contentProcessor.getScrollbarThumbPosition(ZLView.PageIndex.CURRENT);
            final int to = contentProcessor.getScrollbarThumbPosition(animator.getPageToScrollTo());
            final int percent = animator.getScrolledPercent();
            return (from * (100 - percent) + to * percent) / 100;
        } else {
            return contentProcessor.getScrollbarThumbPosition(ZLView.PageIndex.CURRENT);
        }
    }

    @Override
    protected int computeVerticalScrollRange() {
        if (contentProcessor == null || !contentProcessor.isScrollbarShown()) {
            return 0;
        }
        return contentProcessor.getScrollbarFullSize();
    }

    public void setContentProcessor(ContentProcessor processor) {
        this.contentProcessor = processor;
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (!(getContext() instanceof FBReader)) {
            throw new IllegalArgumentException("Must be FBReader");
        }

        setContentProcessor(((FBReader) getContext()).getReaderController().contentProcessorImpl);
    }

    @Override
    protected void onDetachedFromWindow() {
        setContentProcessor(null);
        super.onDetachedFromWindow();
    }
}