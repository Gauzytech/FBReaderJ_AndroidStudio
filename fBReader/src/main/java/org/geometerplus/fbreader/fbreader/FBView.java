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

package org.geometerplus.fbreader.fbreader;

import org.geometerplus.DebugHelper;
import org.geometerplus.fbreader.bookmodel.BookModel;
import org.geometerplus.fbreader.bookmodel.FBHyperlinkType;
import org.geometerplus.fbreader.bookmodel.TOCTree;
import org.geometerplus.fbreader.fbreader.options.ColorProfile;
import org.geometerplus.fbreader.fbreader.options.FooterOptions;
import org.geometerplus.fbreader.fbreader.options.ImageOptions;
import org.geometerplus.fbreader.fbreader.options.MiscOptions;
import org.geometerplus.fbreader.fbreader.options.PageTurningOptions;
import org.geometerplus.fbreader.fbreader.options.ViewOptions;
import org.geometerplus.fbreader.util.FixedTextSnippet;
import org.geometerplus.fbreader.util.TextSnippet;
import org.geometerplus.zlibrary.core.filesystem.ZLFile;
import org.geometerplus.zlibrary.core.filesystem.ZLResourceFile;
import org.geometerplus.zlibrary.core.fonts.FontEntry;
import org.geometerplus.zlibrary.core.library.ZLibrary;
import org.geometerplus.zlibrary.core.util.ZLColor;
import org.geometerplus.zlibrary.core.view.Hull;
import org.geometerplus.zlibrary.core.view.SelectionCursor;
import org.geometerplus.zlibrary.core.view.ZLPaintContext;
import org.geometerplus.zlibrary.text.model.ZLTextModel;
import org.geometerplus.zlibrary.text.view.ExtensionElementManager;
import org.geometerplus.zlibrary.text.view.ZLTextHighlighting;
import org.geometerplus.zlibrary.text.view.ZLTextHyperlink;
import org.geometerplus.zlibrary.text.view.ZLTextHyperlinkRegionSoul;
import org.geometerplus.zlibrary.text.view.ZLTextImageRegionSoul;
import org.geometerplus.zlibrary.text.view.ZLTextPosition;
import org.geometerplus.zlibrary.text.view.ZLTextRegion;
import org.geometerplus.zlibrary.text.view.ZLTextVideoRegionSoul;
import org.geometerplus.zlibrary.text.view.ZLTextView;
import org.geometerplus.zlibrary.text.view.ZLTextWordCursor;
import org.geometerplus.zlibrary.text.view.ZLTextWordRegionSoul;
import org.geometerplus.zlibrary.text.view.style.ZLTextStyleCollection;
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.PaintBlock;
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.SelectionResult;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeSet;

import timber.log.Timber;

/**
 * 继承关系
 * FBView -> ZLTextView -> ZLTextViewBase -> ZLView -> ZLViewEnums
 */
public final class FBView extends ZLTextView {

    public static final int SCROLLBAR_SHOW_AS_FOOTER = 3;
    public static final int SCROLLBAR_SHOW_AS_FOOTER_OLD_STYLE = 4;
    private final FBReaderApp myReader;
    private final ViewOptions myViewOptions;
    private final BookElementManager myBookElementManager;
    private int myStartY;
    private boolean myIsBrightnessAdjustmentInProgress;
    private int myStartBrightness;

    private TapZoneMap myZoneMap;
    private Footer myFooter;
    // 是否显示放大镜
    private boolean mCanMagnifier = false;

    FBView(FBReaderApp reader) {
        super(reader);
        myReader = reader;
        myViewOptions = reader.ViewOptions;
        myBookElementManager = new BookElementManager(this);
    }

    /*** 渲染入口, 通过textModel加载渲染信息 **/
    public void setTextModel(ZLTextModel textModel) {
        super.setTextModel(textModel);
        // 初始化脚注
        // todo 理解脚注逻辑
        if (myFooter != null) {
            myFooter.resetTocMarks();
        }
    }

    @Override
    protected ExtensionElementManager getExtensionManager() {
        return myBookElementManager;
    }

    @Override
    protected void releaseSelectionCursor() {
        super.releaseSelectionCursor();
        if (getCountOfSelectedWords() > 0) {
            myReader.runAction(ActionCode.SELECTION_SHOW_PANEL);
        }
    }

    private SelectionResult releaseSelectionCursorFlutter() {
        super.releaseSelectionCursor();
        if (getCountOfSelectedWords() > 0) {
            return new SelectionResult.ShowMenu(getSelectionStartY() , getSelectionEndY());
        }
        return SelectionResult.NoMenu.INSTANCE;
    }

    private SelectionResult checkExistSelection() {
        // 最后再次检查是否有已经选中的文字, 因为可能之前有选中文字，然后再次在空白的地方拖动
        if (getCountOfSelectedWords() > 0) {
            return new SelectionResult.ShowMenu(getSelectionStartY(), getSelectionEndY());
        }
        return SelectionResult.NoOp.INSTANCE;
    }

    @Override
    public synchronized void onScrollingFinished(PageIndex pageIndex) {
        super.onScrollingFinished(pageIndex);
        if (myReader.PageTurningOptions.Animation.getValue() == Animation.previewNone) {
            // 恢复原来的动画
            myReader.PageTurningOptions.Animation.setValue(Animation.previewShift);
        }
        myReader.storePosition();
    }

    @Override
    public int scrollbarType() {
        return myViewOptions.ScrollbarType.getValue();
    }

    @Override
    protected String getPageProgress() {
        StringBuilder info = new StringBuilder();
        PagePosition pagePosition = pagePosition();
        info.append(pagePosition.Current);
        info.append(" / ");
        info.append(pagePosition.Total);
        return info.toString();
    }

    @Override
    protected ZLPaintContext.ColorAdjustingMode getAdjustingModeForImages() {
        if (myReader.ImageOptions.MatchBackground.getValue()) {
            if (ColorProfile.THEME_WHITE.equals(myViewOptions.getColorProfile().Name)) {
                return ZLPaintContext.ColorAdjustingMode.DARKEN_TO_BACKGROUND;
            } else {
                return ZLPaintContext.ColorAdjustingMode.LIGHTEN_TO_BACKGROUND;
            }
        } else {
            return ZLPaintContext.ColorAdjustingMode.NONE;
        }
    }

    @Override
    public String getTocText(ZLTextWordCursor cursor) {
        int index = cursor.getParagraphIndex();
        if (cursor.isEndOfParagraph()) {
            ++index;
        }
        TOCTree treeToSelect = null;
        for (TOCTree tree : myReader.bookModel.TOCTree) {
            final TOCTree.Reference reference = tree.getReference();
            if (reference == null) {
                continue;
            }
            if (reference.ParagraphIndex > index) {
                break;
            }
            treeToSelect = tree;
        }
        return treeToSelect == null ? "" : treeToSelect.getText();
    }

    @Override
    protected ZLColor getExtraColor() {
        ColorProfile profile = myViewOptions.getColorProfile();
        return profile.HeaderAndFooterColorOption.getValue();
    }

    @Override
    public ImageFitting getImageFitting() {
        return myReader.ImageOptions.FitToScreen.getValue();
    }

    @Override
    public int getTopMargin() {
        return myViewOptions.TopMargin.getValue();
    }

    @Override
    public int getBottomMargin() {
        return myViewOptions.BottomMargin.getValue();
    }

    @Override
    public int getSpaceBetweenColumns() {
        return myViewOptions.SpaceBetweenColumns.getValue();
    }

    @Override
    public ZLFile getWallpaperFile() {
        final String filePath = myViewOptions.getColorProfile().WallpaperOption.getValue();
        if ("".equals(filePath)) {
            return null;
        }

        final ZLFile file = ZLFile.createFileByPath(filePath);
        if (file == null || !file.exists()) {
            return null;
        }
        return file;
    }

    @Override
    public ZLPaintContext.FillMode getFillMode() {
        return getWallpaperFile() instanceof ZLResourceFile
                ? ZLPaintContext.FillMode.tileMirror
                : myViewOptions.getColorProfile().FillModeOption.getValue();
    }

    @Override
    public ZLColor getBackgroundColor() {
        return myViewOptions.getColorProfile().BackgroundOption.getValue();
    }

    @Override
    public ZLColor getBookMarkColor() {
        return myViewOptions.getColorProfile().BookMarkColorOption.getValue();
    }

    @Override
    public ZLColor getSelectionBackgroundColor() {
        return myViewOptions.getColorProfile().SelectionBackgroundOption.getValue();
    }

    @Override
    public ZLColor getSelectionCursorColor() {
        return myViewOptions.getColorProfile().SelectionCursorOption.getValue();
    }

    @Override
    public ZLColor getSelectionForegroundColor() {
        return myViewOptions.getColorProfile().SelectionForegroundOption.getValue();
    }

    /**
     * 获取文件颜色
     *
     * @param hyperlink 超链接
     * @return 文字颜色
     */
    @Override
    public ZLColor getTextColor(ZLTextHyperlink hyperlink) {
        final ColorProfile profile = myViewOptions.getColorProfile();
        switch (hyperlink.Type) {
            default:
            case FBHyperlinkType.NONE:
                return profile.RegularTextOption.getValue();
            case FBHyperlinkType.INTERNAL:
            case FBHyperlinkType.FOOTNOTE:
                return myReader.Collection.isHyperlinkVisited(myReader.getCurrentBook(), hyperlink.Id)
                        ? profile.VisitedHyperlinkTextOption.getValue()
                        : profile.HyperlinkTextOption.getValue();
            case FBHyperlinkType.EXTERNAL:
                return profile.HyperlinkTextOption.getValue();
        }
    }

    @Override
    public boolean isTwoColumnView() {
        return getContextHeight() <= getContextWidth() && myViewOptions.TwoColumnView.getValue();
    }

    @Override
    public int getLeftMargin() {
        return myViewOptions.LeftMargin.getValue();
    }

    @Override
    public int getRightMargin() {
        return myViewOptions.RightMargin.getValue();
    }

    @Override
    public ZLTextStyleCollection getTextStyleCollection() {
        return myViewOptions.getTextStyleCollection();
    }

    @Override
    public ZLColor getHighlightingBackgroundColor() {
        return myViewOptions.getColorProfile().HighlightingBackgroundOption.getValue();
    }

    @Override
    public ZLColor getHighlightingForegroundColor() {
        return myViewOptions.getColorProfile().HighlightingForegroundOption.getValue();
    }

    @Override
    public Footer getFooterArea() {
        switch (myViewOptions.ScrollbarType.getValue()) {
            case SCROLLBAR_SHOW_AS_FOOTER:
                if (!(myFooter instanceof FooterNewStyle)) {
                    if (myFooter != null) {
                        myReader.removeTimerTask(myFooter.UpdateTask);
                    }
                    myFooter = new FooterNewStyle();
                    myReader.addTimerTask(myFooter.UpdateTask, 15000);
                }
                break;
            case SCROLLBAR_SHOW_AS_FOOTER_OLD_STYLE:
                if (!(myFooter instanceof FooterOldStyle)) {
                    if (myFooter != null) {
                        myReader.removeTimerTask(myFooter.UpdateTask);
                    }
                    myFooter = new FooterOldStyle();
                    myReader.addTimerTask(myFooter.UpdateTask, 15000);
                }
                break;
            default:
                if (myFooter != null) {
                    myReader.removeTimerTask(myFooter.UpdateTask);
                    myFooter = null;
                }
                break;
        }
        return myFooter;
    }

    @Override
    public Animation getAnimationType() {
        return myReader.PageTurningOptions.Animation.getValue();
    }

    /**
     * 手指按下状态
     *
     * @param x x坐标
     * @param y y坐标
     */
    @Override
    public void onFingerPress(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        // 隐藏Toast
        myReader.runAction(ActionCode.HIDE_TOAST);

        final float maxDist = ZLibrary.Instance().getDisplayDPI() / 4f;
        final SelectionCursor.Which cursor = findSelectionCursor(x, y, maxDist * maxDist);
        if (cursor != null) {
            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
            Timber.v("长按流程, 移动cursor, %s", cursor);
            moveSelectionCursorTo(cursor, x, y, "onFingerPress");
            return;
        }

        // 如果允许屏幕亮度调节（手势），并且按下位置在内容宽度的 1 / 10，
        // --> (1). 标识屏幕亮度调节，(2). 记录起始Y，(3). 记录当前屏幕亮度
        if (myReader.MiscOptions.AllowScreenBrightnessAdjustment.getValue() && x < getContextWidth() / 10) {
            myIsBrightnessAdjustmentInProgress = true;
            myStartY = y;
            myStartBrightness = myReader.getViewWidget().getScreenBrightness();
            return;
        }

        // 开启手动滑动模式
        // 长按之后，向下拖动，页面滚动的效果
        startManualScrolling(x, y);
    }

    /**
     * 开启手动滑动模式
     * 长按之后，向下拖动，页面滚动的效果
     *
     * @param x x坐标
     * @param y y坐标
     */
    private void startManualScrolling(int x, int y) {
        // 如果滑动翻页不可用，直接返回
        if (!isFlickScrollingEnabled()) {
            return;
        }

        // 获取翻页的方向
        final boolean horizontal = myReader.PageTurningOptions.Horizontal.getValue();
        final Direction direction = horizontal ? Direction.rightToLeft : Direction.up;
        myReader.getViewWidget().startManualScrolling(x, y, direction);
    }

    /**
     * 滑动翻页是否可用
     * {@link org.geometerplus.fbreader.fbreader.options.PageTurningOptions.FingerScrollingType#byFlick}
     * {@link org.geometerplus.fbreader.fbreader.options.PageTurningOptions.FingerScrollingType#byTapAndFlick}
     *
     * @return 滑动翻页是否可用
     */
    private boolean isFlickScrollingEnabled() {
        final PageTurningOptions.FingerScrollingType fingerScrolling = myReader.PageTurningOptions.FingerScrolling.getValue();
        return fingerScrolling == PageTurningOptions.FingerScrollingType.byFlick ||
                fingerScrolling == PageTurningOptions.FingerScrollingType.byTapAndFlick;
    }

    @Override
    public void onFingerRelease(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);

        mCanMagnifier = false;
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            releaseSelectionCursor();
        }
        // 如果有选中，恢复选中动作弹框
        if (hasSelection()) {
            myReader.runAction(ActionCode.SELECTION_SHOW_PANEL);
            return;
        }
        if (cursor != null) {
            releaseSelectionCursor();
        } else if (myIsBrightnessAdjustmentInProgress) {
            myIsBrightnessAdjustmentInProgress = false;
        } else if (isFlickScrollingEnabled()) {
            myReader.getViewWidget().startAnimatedScrolling(
                    x, y, myReader.PageTurningOptions.AnimationSpeed.getValue()
            );
        }
    }

    @Override
    public void onFingerMove(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);

        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            mCanMagnifier = true;
            Timber.v("长按流程, 移动cursor, %s", cursor);
            moveSelectionCursorTo(cursor, x, y, "onFingerMove");
            return;
        }

        // 如果有选中， 隐藏选中动作弹框
        if (hasSelection()) {
            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
            return;
        }

        synchronized (this) {
            if (myIsBrightnessAdjustmentInProgress) {
                if (x >= getContextWidth() / 5) {
                    myIsBrightnessAdjustmentInProgress = false;
                    startManualScrolling(x, y);
                } else {
                    final int delta = (myStartBrightness + 30) * (myStartY - y) / getContextHeight();
                    myReader.getViewWidget().setScreenBrightness(myStartBrightness + delta);
                    return;
                }
            }

            if (isFlickScrollingEnabled()) {
                myReader.getViewWidget().scrollManuallyTo(x, y);
            }
        }
    }

    @Override
    public boolean onFingerLongPress(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        Timber.v("长按选中流程, [%s, %s]", x, y);
        myReader.runAction(ActionCode.HIDE_TOAST);
        // 预览模式不处理
        if (isPreview()) {
            return true;
        }

        // 如果有选中， 隐藏选中动作弹框
        if (hasSelection()) {
            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
            return true;
        }

//        mCanMagnifier = true;

        // 获取字体大小, 然后计算y，定位到触摸位置的上一行
        int countY = y - getTextStyleCollection().getBaseStyle().getFontSize() / 2;
        // 搜索查看上一行内容区域是否存在
        final ZLTextRegion region = findRegion(x, countY, maxSelectionDistance(), ZLTextRegion.AnyRegionFilter);
        Timber.v("长按选中流程[onFingerLongPress], 找到了选中区域: %s", region);
        if (region != null) {
            final ZLTextRegion.Soul soul = region.getSoul();
            boolean doSelectRegion = false;
            if (soul instanceof ZLTextWordRegionSoul) {
                // 一般的文字选中
                switch (myReader.MiscOptions.WordTappingAction.getValue()) {
                    case startSelecting:
                        myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
                        // 将触摸x, y坐标与当前字体大小一起重新计算, 并设定选择区域
                        // 这个是原来的方法，会多一次findRegion的运算, 效率低
//                        boolean regionSet = setSelectionRegionWithTextSize(x, y);
//                        if (regionSet) {
//                            // 找到了触摸坐标的对应内容，触发重绘
//                            repaint("drawSelection");
//                        }

                        // 改进的方法，因为将字体大小, 触摸区域的计算搬到了471行，减少了一次findRegion的计算
                        setSelectedRegion(region);

                        final SelectionCursor.Which cursor = findSelectionCursor(x, y);
                        if (cursor != null) {
//                            Timber.v("长按选中流程, 刷新selectionCursor: %s", cursor);
                            moveSelectionCursorTo(cursor, x, y, "onFingerLongPress");
                        } else {
                            repaint("setSelectedRegion");
                        }
                        return true;
                    case selectSingleWord:
                    case openDictionary:
                        doSelectRegion = true;
                        break;
                }
            } else if (soul instanceof ZLTextImageRegionSoul) {
                // 图片
                doSelectRegion =
                        myReader.ImageOptions.TapAction.getValue() !=
                                ImageOptions.TapActionEnum.doNothing;
            } else if (soul instanceof ZLTextHyperlinkRegionSoul) {
                // 超链接
                doSelectRegion = true;
            }

            if (doSelectRegion) {
                outlineRegion(region);
                Timber.v("长按选中流程, draw outline");
                repaint("doSelectRegion");
                return true;
            }
        }
        return false;
    }

    @Override
    public void onFingerReleaseAfterLongPress(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        Timber.v("长按选中流程, [%s, %s]", x, y);

        mCanMagnifier = false;
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            releaseSelectionCursor();
//            Timber.v("长按选中流程, releaseSelectionCursor");
            return;
        }

        // 如果有选中， 显示选中动作弹框
        if (hasSelection()) {
            myReader.runAction(ActionCode.SELECTION_SHOW_PANEL);
            Timber.v("长按选中流程, show panel");
            return;
        }

        final ZLTextRegion region = getOutlinedRegion();
        if (region != null) {
            final ZLTextRegion.Soul soul = region.getSoul();

            boolean doRunAction = false;
            if (soul instanceof ZLTextWordRegionSoul) {
                doRunAction =
                        myReader.MiscOptions.WordTappingAction.getValue() ==
                                MiscOptions.WordTappingActionEnum.openDictionary;
            } else if (soul instanceof ZLTextImageRegionSoul) {
                doRunAction =
                        myReader.ImageOptions.TapAction.getValue() ==
                                ImageOptions.TapActionEnum.openImageView;
            }

            if (doRunAction) {
                myReader.runAction(ActionCode.PROCESS_HYPERLINK);
            }
        }
    }

    @Override
    public void onFingerMoveAfterLongPress(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        Timber.v("长按选中流程, [%s, %s]", x, y);

        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            moveSelectionCursorTo(cursor, x, y, "onFingerMoveAfterLongPress");
            return;
        }

        ZLTextRegion region = getOutlinedRegion();
        if (region != null) {
            ZLTextRegion.Soul soul = region.getSoul();
            if (soul instanceof ZLTextHyperlinkRegionSoul ||
                    soul instanceof ZLTextWordRegionSoul) {
                if (myReader.MiscOptions.WordTappingAction.getValue() !=
                        MiscOptions.WordTappingActionEnum.doNothing) {
                    region = findRegion(x, y, maxSelectionDistance(), ZLTextRegion.AnyRegionFilter);
                    if (region != null) {
                        soul = region.getSoul();
                        if (soul instanceof ZLTextHyperlinkRegionSoul
                                || soul instanceof ZLTextWordRegionSoul) {
                            outlineRegion(region);
                            repaint("onFingerMoveAfterLongPress");
                        }
                    }
                }
            }
        }
    }

    @Override
    public void onFingerSingleTap(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        // 预览模式的情况下，点击为打开菜单
        if (isPreview()) {
            myReader.runAction(ActionCode.SHOW_MENU, x, y);
            return;
        }

        // 如果有选中，则(1). 清除选中，(2). 隐藏选中动作弹框
        if (hasSelection()) {
            Timber.v("长按流程, 选中");
            myReader.runAction(ActionCode.SELECTION_CLEAR);
            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
            return;
        }

        final ZLTextRegion hyperlinkRegion = findRegion(x, y, maxSelectionDistance(), ZLTextRegion.HyperlinkFilter);
        if (hyperlinkRegion != null) {
            Timber.v("长按流程, 超链接");
            outlineRegion(hyperlinkRegion);
            repaint("onFingerSingleTap");
            myReader.runAction(ActionCode.PROCESS_HYPERLINK);
            return;
        }

        final ZLTextRegion bookRegion = findRegion(x, y, 0, ZLTextRegion.ExtensionFilter);
        if (bookRegion != null) {
            Timber.v("长按流程, DISPLAY_BOOK_POPUP");
            myReader.runAction(ActionCode.DISPLAY_BOOK_POPUP, bookRegion);
            return;
        }

        final ZLTextRegion videoRegion = findRegion(x, y, 0, ZLTextRegion.VideoFilter);
        if (videoRegion != null) {
            Timber.v("长按流程, video");
            outlineRegion(videoRegion);
            repaint("onFingerSingleTap");
            myReader.runAction(ActionCode.OPEN_VIDEO, (ZLTextVideoRegionSoul) videoRegion.getSoul());
            return;
        }

        final ZLTextHighlighting highlighting = findHighlighting(x, y, maxSelectionDistance());
        if (highlighting instanceof BookmarkHighlighting) {
            Timber.v("长按流程, SELECTION_BOOKMARK");
            myReader.runAction(
                    ActionCode.SELECTION_BOOKMARK,
                    ((BookmarkHighlighting) highlighting).Bookmark
            );
            return;
        }

        if (myReader.isActionEnabled(ActionCode.HIDE_TOAST)) {
            myReader.runAction(ActionCode.HIDE_TOAST);
            return;
        }

        onFingerSingleTapLastResort(x, y);
    }

    private void onFingerSingleTapLastResort(int x, int y) {
        String actionId = getZoneMap().getActionByCoordinates(
                x, y, getContextWidth(), getContextHeight(),
                isDoubleTapSupported() ? TapZoneMap.Tap.singleNotDoubleTap : TapZoneMap.Tap.singleTap
        );
        myReader.runAction(actionId, x, y);
        Timber.v("长按流程, [%s, %s], action = %s", x, y, actionId);
    }

    private TapZoneMap getZoneMap() {
        final PageTurningOptions prefs = myReader.PageTurningOptions;
        String id = prefs.TapZoneMap.getValue();
        if ("".equals(id)) {
            id = prefs.Horizontal.getValue() ? "right_to_left" : "up";
        }
        if (myZoneMap == null || !id.equals(myZoneMap.Name)) {
            myZoneMap = TapZoneMap.zoneMap(id);
        }
        return myZoneMap;
    }

    @Override
    public void onFingerDoubleTap(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);
        myReader.runAction(ActionCode.HIDE_TOAST);

        myReader.runAction(getZoneMap().getActionByCoordinates(
                x, y, getContextWidth(), getContextHeight(), TapZoneMap.Tap.doubleTap
        ), x, y);
    }

    @Override
    public void onFingerEventCancelled() {
        Timber.v("触摸事件");
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            releaseSelectionCursor();
        }
    }

    @Override
    public boolean isDoubleTapSupported() {
        return myReader.MiscOptions.EnableDoubleTap.getValue();
    }

    public boolean onTrackballRotated(int diffX, int diffY) {
        if (diffX == 0 && diffY == 0) {
            return true;
        }

        final Direction direction = (diffY != 0) ?
                (diffY > 0 ? Direction.down : Direction.up) :
                (diffX > 0 ? Direction.leftToRight : Direction.rightToLeft);

        new MoveCursorAction(myReader, direction).run();
        return true;
    }

    @Override
    public boolean canMagnifier() {
        return mCanMagnifier;
    }

    @Override
    public boolean hasSelection() {
        return myReader.isActionEnabled(ActionCode.SELECTION_CLEAR);
    }

    @Override
    public boolean isHorizontal() {
        return myReader.PageTurningOptions.Horizontal.getValue();
    }

    /**
     * 获得所有选中文字的个数
     */
    public int getCountOfSelectedWords() {
        final WordCountTraverser traverser = new WordCountTraverser(this);
        if (!isSelectionEmpty()) {
            traverser.traverse(getSelectionStartPosition(), getSelectionEndPosition());
        }
        return traverser.getCount();
    }

    /**
     * 获得所有选中文字
     */
    public TextSnippet getSelectedSnippet() {
        final ZLTextPosition start = getSelectionStartPosition();
        final ZLTextPosition end = getSelectionEndPosition();
        if (start == null || end == null) {
            return null;
        }
        final TextBuildTraverser traverser = new TextBuildTraverser(this);
        traverser.traverse(start, end);
        return new FixedTextSnippet(start, end, traverser.getText());
    }

    public abstract class Footer implements FooterArea {
        protected ArrayList<TOCTree> myTOCMarks;
        private Runnable UpdateTask = new Runnable() {
            public void run() {
                myReader.getViewWidget().repaint("Footer.run");
            }
        };
        private int myMaxTOCMarksNumber = -1;
        private List<FontEntry> myFontEntry;
        private Map<String, Integer> myHeightMap = new HashMap<String, Integer>();
        private Map<String, Integer> myCharHeightMap = new HashMap<String, Integer>();

        public int getHeight() {
            return myViewOptions.FooterHeight.getValue();
        }

        public synchronized void resetTocMarks() {
            myTOCMarks = null;
        }

        protected synchronized void updateTOCMarks(BookModel model, int maxNumber) {
            if (myTOCMarks != null && myMaxTOCMarksNumber == maxNumber) {
                return;
            }

            myTOCMarks = new ArrayList<>();
            myMaxTOCMarksNumber = maxNumber;

            TOCTree toc = model.TOCTree;
            if (toc == null) {
                return;
            }
            int maxLevel = Integer.MAX_VALUE;
            if (toc.getSize() >= maxNumber) {
                final int[] sizes = new int[10];
                for (TOCTree tocItem : toc) {
                    if (tocItem.Level < 10) {
                        ++sizes[tocItem.Level];
                    }
                }
                for (int i = 1; i < sizes.length; ++i) {
                    sizes[i] += sizes[i - 1];
                }
                for (maxLevel = sizes.length - 1; maxLevel >= 0; --maxLevel) {
                    if (sizes[maxLevel] < maxNumber) {
                        break;
                    }
                }
            }
            for (TOCTree tocItem : toc.allSubtrees(maxLevel)) {
                myTOCMarks.add(tocItem);
            }
        }

        protected String buildInfoString(PagePosition pagePosition, String separator) {
            final StringBuilder info = new StringBuilder();
            final FooterOptions footerOptions = myViewOptions.getFooterOptions();

            if (footerOptions.showProgressAsPages()) {
                maybeAddSeparator(info, separator);
                info.append(pagePosition.Current);
                info.append("/");
                info.append(pagePosition.Total);
            }
            if (footerOptions.showProgressAsPercentage() && pagePosition.Total != 0) {
                maybeAddSeparator(info, separator);
                info.append(100 * pagePosition.Current / pagePosition.Total);
                info.append("%");
            }

            if (footerOptions.ShowClock.getValue()) {
                maybeAddSeparator(info, separator);
                info.append(ZLibrary.Instance().getCurrentTimeString());
            }
            if (footerOptions.ShowBattery.getValue()) {
                maybeAddSeparator(info, separator);
                info.append(myReader.getBatteryLevel());
                info.append("%");
            }
            return info.toString();
        }

        private void maybeAddSeparator(StringBuilder info, String separator) {
            if (info.length() > 0) {
                info.append(separator);
            }
        }

        protected synchronized int setFont(ZLPaintContext context, int height, boolean bold) {
            final String family = myViewOptions.getFooterOptions().Font.getValue();
            if (myFontEntry == null || !family.equals(myFontEntry.get(0).Family)) {
                myFontEntry = Collections.singletonList(FontEntry.systemEntry(family));
            }
            final String key = family + (bold ? "N" : "B") + height;
            final Integer cached = myHeightMap.get(key);
            if (cached != null) {
                context.setFont(myFontEntry, cached, bold, false, false, false);
                final Integer charHeight = myCharHeightMap.get(key);
                return charHeight != null ? charHeight : height;
            } else {
                int h = height + 2;
                int charHeight = height;
                final int max = height < 9 ? height - 1 : height - 2;
                for (; h > 5; --h) {
                    context.setFont(myFontEntry, h, bold, false, false, false);
                    charHeight = context.getCharHeight('H');
                    if (charHeight <= max) {
                        break;
                    }
                }
                myHeightMap.put(key, h);
                myCharHeightMap.put(key, charHeight);
                return charHeight;
            }
        }
    }

    private class FooterOldStyle extends Footer {
        public synchronized void paint(ZLPaintContext context) {
            final ZLFile wallpaper = getWallpaperFile();
            if (wallpaper != null) {
                context.clear(wallpaper, getFillMode());
            } else {
                context.clear(getBackgroundColor());
            }

            final BookModel model = myReader.bookModel;
            if (model == null) {
                return;
            }

            //final ZLColor bgColor = getBackgroundColor();
            // TODO: separate color option for footer color
            final ZLColor fgColor = getTextColor(ZLTextHyperlink.NO_LINK);
            final ZLColor fillColor = myViewOptions.getColorProfile().FooterFillOption.getValue();

            final int left = getLeftMargin();
            final int right = context.getWidth() - getRightMargin();
            final int height = getHeight();
            final int lineWidth = height <= 10 ? 1 : 2;
            final int delta = height <= 10 ? 0 : 1;
            setFont(context, height, height > 10);

            final PagePosition pagePosition = FBView.this.pagePosition();

            // draw info text
            final String infoString = buildInfoString(pagePosition, " ");
            final int infoWidth = context.getStringWidth(infoString);
            context.setTextColor(fgColor);
            context.drawString(right - infoWidth, height - delta, infoString);

            // draw gauge
            final int gaugeRight = right - (infoWidth == 0 ? 0 : infoWidth + 10);
            final int gaugeWidth = gaugeRight - left - 2 * lineWidth;

            context.setLineColor(fgColor);
            context.setLineWidth(lineWidth);
            context.drawLine(left, lineWidth, left, height - lineWidth);
            context.drawLine(left, height - lineWidth, gaugeRight, height - lineWidth);
            context.drawLine(gaugeRight, height - lineWidth, gaugeRight, lineWidth);
            context.drawLine(gaugeRight, lineWidth, left, lineWidth);

            final int gaugeInternalRight =
                    left + lineWidth + (int) (1.0 * gaugeWidth * pagePosition.Current / pagePosition.Total);

            context.setFillColor(fillColor);
            context.fillRectangle(left + 1, height - 2 * lineWidth, gaugeInternalRight, lineWidth + 1);

            final FooterOptions footerOptions = myViewOptions.getFooterOptions();
            if (footerOptions.ShowTOCMarks.getValue()) {
                updateTOCMarks(model, footerOptions.MaxTOCMarks.getValue());
                final int fullLength = sizeOfFullText();
                for (TOCTree tocItem : myTOCMarks) {
                    TOCTree.Reference reference = tocItem.getReference();
                    if (reference != null) {
                        final int refCoord = sizeOfTextBeforeParagraph(reference.ParagraphIndex);
                        final int xCoord =
                                left + 2 * lineWidth + (int) (1.0 * gaugeWidth * refCoord / fullLength);
                        context.drawLine(xCoord, height - lineWidth, xCoord, lineWidth);
                    }
                }
            }
        }
    }

    private class FooterNewStyle extends Footer {
        public synchronized void paint(ZLPaintContext context) {
            final ColorProfile cProfile = myViewOptions.getColorProfile();
            context.clear(cProfile.FooterNGBackgroundOption.getValue());

            final BookModel model = myReader.bookModel;
            if (model == null) {
                return;
            }

            final ZLColor textColor = cProfile.FooterNGForegroundOption.getValue();
            final ZLColor readColor = cProfile.FooterNGForegroundOption.getValue();
            final ZLColor unreadColor = cProfile.FooterNGForegroundUnreadOption.getValue();

            final int left = getLeftMargin();
            final int right = context.getWidth() - getRightMargin();
            final int height = getHeight();
            final int lineWidth = height <= 12 ? 1 : 2;
            final int charHeight = setFont(context, height * 3 / 5, height > 12);

            final PagePosition pagePosition = FBView.this.pagePosition();

            // draw info text
            final String infoString = buildInfoString(pagePosition, "  ");
            final int infoWidth = context.getStringWidth(infoString);
            context.setTextColor(textColor);
            context.drawString(right - infoWidth, (height + charHeight + 1) / 2, infoString);

            // draw gauge
            final int gaugeRight = right - (infoWidth == 0 ? 0 : infoWidth + 10);
            final int gaugeInternalRight =
                    left + (int) (1.0 * (gaugeRight - left) * pagePosition.Current / pagePosition.Total + 0.5);
            final int v = height / 2;

            context.setLineWidth(lineWidth);
            context.setLineColor(readColor);
            // context.drawLine(left, v, gaugeInternalRight, v);
            if (gaugeInternalRight < gaugeRight) {
                context.setLineColor(unreadColor);
                context.drawLine(gaugeInternalRight + 1, v, gaugeRight, v);
            }

            // draw labels
            final FooterOptions footerOptions = myViewOptions.getFooterOptions();
            if (footerOptions.ShowTOCMarks.getValue()) {
                final TreeSet<Integer> labels = new TreeSet<Integer>();
                labels.add(left);
                labels.add(gaugeRight);
                updateTOCMarks(model, footerOptions.MaxTOCMarks.getValue());
                final int fullLength = sizeOfFullText();
                for (TOCTree tocItem : myTOCMarks) {
                    TOCTree.Reference reference = tocItem.getReference();
                    if (reference != null) {
                        final int refCoord = sizeOfTextBeforeParagraph(reference.ParagraphIndex);
                        labels.add(left + (int) (1.0 * (gaugeRight - left) * refCoord / fullLength + 0.5));
                    }
                }
                for (int l : labels) {
                    context.setLineColor(l <= gaugeInternalRight ? readColor : unreadColor);
                    context.drawLine(l, v + 3, l, v - lineWidth - 2);
                }
            }
        }
    }

    /**
     * 长按选中了文字会回调这个方法
     */
    @Override
    public SelectionResult onFingerLongPressFlutter(int x, int y) {
        Timber.v("长按流程, 长按坐标: [%s, %s]", x, y);
//        myReader.runAction(ActionCode.HIDE_TOAST);
        // 预览模式不处理
//        if (isPreview()) {
//            return true;
//        }

        // 如果有选中， 隐藏选中动作弹框
//        if (myReader.isActionEnabled(ActionCode.SELECTION_CLEAR)) {
//            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
//            return true;
//        }

//        mCanMagnifier = true;

        // 获取字体大小, 然后计算y，定位到触摸位置的上一行
        int countY = y - getTextStyleCollection().getBaseStyle().getFontSize() / 2;
        // 搜索查看上一行内容区域是否存在
        final ZLTextRegion region = findRegion(x, countY, maxSelectionDistance(), ZLTextRegion.AnyRegionFilter);
        Timber.v("长按选中流程[onFingerLongPressFlutter], 找到了选中区域: %s", region);
        if (region != null) {
            final ZLTextRegion.Soul soul = region.getSoul();
            boolean doSelectRegion = false;
            if (soul instanceof ZLTextWordRegionSoul) {
                switch (myReader.MiscOptions.WordTappingAction.getValue()) {
                    case startSelecting:
//                        myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);

                        // 改进的方法，因为将字体大小, 触摸区域的计算搬到了471行，减少了一次findRegion的计算
                        setSelectedRegion(region);

                        final SelectionCursor.Which cursor = findSelectionCursor(x, y);
                        if (cursor != null) {
                            moveSelectionCursorToFlutter(cursor, x, y, "onFingerLongPress");
                        }

                        return SelectionResult.createHighlight(
                                findCurrentPageHighlight(),
                                getSelectionCursorColor(),
                                getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Left),
                                getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Right));
                    case selectSingleWord:
                    case openDictionary:
                        doSelectRegion = true;
                        break;
                }
            } else if (soul instanceof ZLTextImageRegionSoul) {
                doSelectRegion =
                        myReader.ImageOptions.TapAction.getValue() !=
                                ImageOptions.TapActionEnum.doNothing;
            } else if (soul instanceof ZLTextHyperlinkRegionSoul) {
                doSelectRegion = true;
            }

            if (doSelectRegion) {
                super.outlineRegion(region);
                return SelectionResult.createHighlight(
                        new PaintBlock.HighlightBlock(DebugHelper.outlineColor(),
                                region.getDrawCoordinates(Hull.DrawMode.Outline))
                );
            }
        }
        return SelectionResult.NoOp.INSTANCE;
    }

    /**
     * 长按选中了文字并拖动会回调这个方法
     */
    @Override
    public SelectionResult onFingerMoveAfterLongPressFlutter(int x, int y) {
        Timber.v("长按流程, 长按坐标: [%s, %s]", x, y);
        // 判断当前触摸坐标是否有选中文字
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            if (moveSelectionCursorToFlutter(cursor, x, y, "onFingerMoveAfterLongPress")) {
                return SelectionResult.createHighlight(
                        findCurrentPageHighlight(),
                        getSelectionCursorColor(),
                        getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Left),
                        getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Right));
            }
        }

        // 判断当前触摸坐标是否有选中outline
        ZLTextRegion region = getOutlinedRegion();
        if (region != null) {
            ZLTextRegion.Soul soul = region.getSoul();
            if (soul instanceof ZLTextHyperlinkRegionSoul || soul instanceof ZLTextWordRegionSoul) {
                if (myReader.MiscOptions.WordTappingAction.getValue() !=
                        MiscOptions.WordTappingActionEnum.doNothing) {
                    region = findRegion(x, y, maxSelectionDistance(), ZLTextRegion.AnyRegionFilter);
                    if (region != null) {
                        soul = region.getSoul();
                        if (soul instanceof ZLTextHyperlinkRegionSoul
                                || soul instanceof ZLTextWordRegionSoul) {
                            outlineRegion(region);
                            return SelectionResult.createHighlight(
                                    new PaintBlock.HighlightBlock(DebugHelper.outlineColor(),
                                            region.getDrawCoordinates(Hull.DrawMode.Outline)));
                        }
                    }
                }
            }
        }

        return SelectionResult.NoOp.INSTANCE;
    }

    /**
     * 长按选中了文字直接松开, 或者长按并拖动再松开都会回调这个方法
     *
     * @return SelectionResult
     */
    @Override
    public SelectionResult onFingerReleaseAfterLongPressFlutter(int x, int y) {
        Timber.v("长按流程, onFingerReleaseAfterLongPressFlutter");
//        mCanMagnifier = false;
        // 判断手指触摸区域有没有选中text
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            return releaseSelectionCursorFlutter();
        }

        // 如果有选中 显示选中动作弹框
//        if (myReader.isActionEnabled(ActionCode.SELECTION_CLEAR)) {
//            myReader.runAction(ActionCode.SELECTION_SHOW_PANEL
//            return;
//        }

        //  判断手指触摸区域有没有选中outline
        final ZLTextRegion region = getOutlinedRegion();
        if (region != null) {
            final ZLTextRegion.Soul soul = region.getSoul();
            SelectionResult outlineResult = null;
            boolean doRunAction = false;
            if (soul instanceof ZLTextWordRegionSoul) {
                doRunAction =
                        myReader.MiscOptions.WordTappingAction.getValue() ==
                                MiscOptions.WordTappingActionEnum.openDictionary;
                outlineResult = SelectionResult.OpenDirectory.INSTANCE;
            } else if (soul instanceof ZLTextImageRegionSoul) {
                doRunAction =
                        myReader.ImageOptions.TapAction.getValue() ==
                                ImageOptions.TapActionEnum.openImageView;
                outlineResult = SelectionResult.OpenImage.INSTANCE;
            }

            // todo flutter实现打开图片, 超链接点击效果
            if (doRunAction) {
//                myReader.runAction(ActionCode.PROCESS_HYPERLINK);
                return Objects.requireNonNull(outlineResult);
            }
        }

        // 最后判断本page有没其他选中的文字, 因为可能之前有选中文字，然后拖动到了空白区域的情况
        return checkExistSelection();
    }

    /**
     * 手指点击回调的方法
     */
    @Override
    public void onFingerSingleTapFlutter(int x, int y) {
        Timber.v("长按流程, 长按坐标: [%s, %s]", x, y);
        // 预览模式的情况下，点击为打开菜单
//        if (isPreview()) {
//            myReader.runAction(ActionCode.SHOW_MENU, x, y);
//            return;
//        }

        // 如果有选中，
        // 1. 清除选中，
        // 2. 隐藏选中动作弹框(在flutter执行)
        if (cleaAllSelectedSections()) {
            return;
        }

        // 只有在超链接上面点击了，才会触发这个逻辑
        // 1. 隐藏outline
        // 2. 超链接跳转
        // TODO 是否应该改成点击空白地方应该隐藏outline????
        final ZLTextRegion hyperlinkRegion = findRegion(x, y, maxSelectionDistance(), ZLTextRegion.HyperlinkFilter);
        if (hyperlinkRegion != null) {
            Timber.v("长按流程, 超链接");
            outlineRegion(hyperlinkRegion);
//            repaint("onFingerSingleTap");
            // todo 超链接跳转方法待实现
//            myReader.runAction(ActionCode.PROCESS_HYPERLINK);
            return;
        }

        // todo 这个是啥?? 图书简介界面?
//        final ZLTextRegion bookRegion = findRegion(x, y, 0, ZLTextRegion.ExtensionFilter);
//        if (bookRegion != null) {
//              Timber.v("长按流程, 图书popup");
//            myReader.runAction(ActionCode.DISPLAY_BOOK_POPUP, bookRegion);
//            return;
//        }

        // todo video视频支持
        final ZLTextRegion videoRegion = findRegion(x, y, 0, ZLTextRegion.VideoFilter);
        if (videoRegion != null) {
            Timber.v("长按流程, video");
            outlineRegion(videoRegion);
//            repaint("onFingerSingleTap");
            // todo
//            myReader.runAction(ActionCode.OPEN_VIDEO, (ZLTextVideoRegionSoul) videoRegion.getSoul());
            return;
        }

        // todo 书签高亮
//        final ZLTextHighlighting highlighting = findHighlighting(x, y, maxSelectionDistance());
//        if (highlighting instanceof BookmarkHighlighting) {
//              Timber.v("长按流程, 书签高亮");
//            myReader.runAction(
//                    ActionCode.SELECTION_BOOKMARK,
//                    ((BookmarkHighlighting) highlighting).Bookmark
//            );
//            return;
//        }

        // todo
//        if (myReader.isActionEnabled(ActionCode.HIDE_TOAST)) {
//            myReader.runAction(ActionCode.HIDE_TOAST);
//            return;
//        }

        // todo 显示顶部和底部menu的
//        onFingerSingleTapLastResort(x, y);

    }

    /**
     * 已经长按选中了一些文字，点击选中小耳朵回调的方法
     *
     * @return 'true' need repaint, 'false' no need repaint
     */
    @Override
    public SelectionResult onFingerPressFlutter(int x, int y) {
        // 隐藏Toast
        // myReader.runAction(ActionCode.HIDE_TOAST);

        final float maxDist = ZLibrary.Instance().getDisplayDPI() / 4f;
        // 寻找触摸范围内的选择光标
        final SelectionCursor.Which cursor = findSelectionCursor(x, y, maxDist * maxDist);
        if (cursor != null) {
            // myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
            moveSelectionCursorToFlutter(cursor, x, y, "onFingerPress");
            return SelectionResult.Companion.createHighlight(
                    findCurrentPageHighlight(),
                    getSelectionCursorColor(),
                    getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Left),
                    getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Right));
        } else {
            // todo 如果允许屏幕亮度调节（手势），并且按下位置在内容宽度的 1 / 10，
            // --> (1). 标识屏幕亮度调节，(2). 记录起始Y，(3). 记录当前屏幕亮度
//        if (myReader.MiscOptions.AllowScreenBrightnessAdjustment.getValue() && x < getContextWidth() / 10) {
//            myIsBrightnessAdjustmentInProgress = true;
//            myStartY = y;
//            myStartBrightness = myReader.getViewWidget().getScreenBrightness();
//            return;
//        }

            // todo 开启手动滑动模式
            // 长按之后，向下拖动，页面滚动的效果
//        startManualScrolling(x, y);

            return SelectionResult.NoOp.INSTANCE;
        }
    }

    /**
     * 已经长按选中了一些文字，拖动选中小耳朵回调的方法
     */
    @Override
    public SelectionResult onFingerMoveFlutter(int x, int y) {

        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
//            mCanMagnifier = true;
            if (moveSelectionCursorToFlutter(cursor, x, y, "onFingerMove")) {
                return SelectionResult.Companion.createHighlight(
                        findCurrentPageHighlight(),
                        getSelectionCursorColor(),
                        getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Left),
                        getCurrentPageSelectionCursorPoint(SelectionCursor.Which.Right));
            }
        } else {
            // todo 如果有选中， 隐藏选中动作弹框
//        if (myReader.isActionEnabled(ActionCode.SELECTION_CLEAR)) {
//            myReader.runAction(ActionCode.SELECTION_HIDE_PANEL);
//            return;
//        }

//        synchronized (this) {
//            if (myIsBrightnessAdjustmentInProgress) {
//                if (x >= getContextWidth() / 5) {
//                    myIsBrightnessAdjustmentInProgress = false;
//                    startManualScrolling(x, y);
//                } else {
//                    final int delta = (myStartBrightness + 30) * (myStartY - y) / getContextHeight();
//                    myReader.getViewWidget().setScreenBrightness(myStartBrightness + delta);
//                    return;
//                }
//            }
//            // 长按之后，向下拖动，页面滚动的效果
//            if (isFlickScrollingEnabled()) {
//                myReader.getViewWidget().scrollManuallyTo(x, y);
//            }
//        }

        }

        return SelectionResult.NoOp.INSTANCE;
    }

    /**
     * 已经长按选中了一些文字，拖动选中小耳朵完毕, 手指松开的回调的方法
     */
    @Override
    public SelectionResult onFingerReleaseFlutter(int x, int y) {
        Timber.v("触摸事件, [%s, %s]", x, y);

//        mCanMagnifier = false;
        final SelectionCursor.Which cursor = getSelectionCursorInMovement();
        if (cursor != null) {
            Timber.v("flutter动画流程[onFingerReleaseFlutter], 释放%s cursor", cursor);
            return releaseSelectionCursorFlutter();
        } else {
            // 如果有选中，恢复选中动作弹框
//        if (myReader.isActionEnabled(ActionCode.SELECTION_CLEAR)) {
//            myReader.runAction(ActionCode.SELECTION_SHOW_PANEL);
//            return;
//        }
//        if (cursor != null) {
//            releaseSelectionCursor();
//        }
            // todo
//        else if (myIsBrightnessAdjustmentInProgress) {
//            myIsBrightnessAdjustmentInProgress = false;
//        } else if (isFlickScrollingEnabled()) {
//            myReader.getViewWidget().startAnimatedScrolling(
//                    x, y, myReader.PageTurningOptions.AnimationSpeed.getValue()
//            );
//        }

            // 最后再次检查是否有已经选中的文字, 因为可能之前有选中文字，然后再次在空白的地方拖动
            return checkExistSelection();
        }
    }

    /** 清除所有选中内容: 包括划选文字，选中的图片或者超链接等 */
    @Override
    public boolean cleaAllSelectedSections() {
        // 1. 清除划选内容
        if (hasSelection()) {
            clearSelection();
            return true;
        }

        // 2. 清除图片, 超链接的outline选中效果
        if(getOutlinedRegion() != null) {
            hideOutline();
            return true;
        }

        return false;
    }
}
