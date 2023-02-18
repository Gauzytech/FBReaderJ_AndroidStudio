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

package org.geometerplus.zlibrary.text.view;

import androidx.annotation.NonNull;

import org.geometerplus.DebugHelper;

import java.util.ArrayList;

import timber.log.Timber;


final class ZLTextPage {

    final ZLTextWordCursor startCursor = new ZLTextWordCursor();
    final ZLTextWordCursor endCursor = new ZLTextWordCursor();
    private final ArrayList<ZLTextLineInfo> lineInfos = new ArrayList<>();
    // 0: 单列
    // lineInfos.size: 双列
    int column0Height;
    int paintState = PaintStateEnum.NOTHING_TO_PAINT;

    // 用来辅助定位划选高亮区域
    final ZLTextElementAreaVector TextElementMap = new ZLTextElementAreaVector();

    private int myColumnWidth;
    private int myHeight;
    private boolean myTwoColumnView;

    protected void setSize(int columnWidth, int height, boolean twoColumnView, boolean keepEndNotStart) {
        if (myColumnWidth == columnWidth && myHeight == height) {
            return;
        }
        myColumnWidth = columnWidth;
        myHeight = height;
        myTwoColumnView = twoColumnView;

        if (!isClearPaintState()) {
            lineInfos.clear();
            if (keepEndNotStart) {
                if (!endCursor.isNull()) {
                    startCursor.reset();
                    paintState = PaintStateEnum.END_IS_KNOWN;
                } else if (!startCursor.isNull()) {
                    endCursor.reset();
                    paintState = PaintStateEnum.START_IS_KNOWN;
                }
            } else {
                if (!startCursor.isNull()) {
                    endCursor.reset();
                    paintState = PaintStateEnum.START_IS_KNOWN;
                } else if (!endCursor.isNull()) {
                    startCursor.reset();
                    paintState = PaintStateEnum.END_IS_KNOWN;
                }
            }
        }
    }

    protected void reset() {
        startCursor.reset();
        endCursor.reset();
        lineInfos.clear();
        paintState = PaintStateEnum.NOTHING_TO_PAINT;
    }

    public boolean isClearPaintState() {
        return paintState == PaintStateEnum.NOTHING_TO_PAINT;
    }

    /**
     * 移动当前page的起始cursor
     */
    protected void moveStartCursor(ZLTextParagraphCursor cursor) {
        // 对startCursor属性指向的ZLTextWordCursor类的属性进行赋值
        startCursor.setCursor(cursor);
        endCursor.reset();
        lineInfos.clear();
        paintState = PaintStateEnum.START_IS_KNOWN;
    }

    /**
     * 直接移动到之前的阅读进度
     * 阅读进度跳转使用
     */
    protected void moveStartCursor(int paragraphIndex, int wordIndex, int charIndex) {
        Timber.v("渲染流程, currentPage更新阅读进度, 当前endCursor = %s, startCursor == null[%s], lineInfo = %d", endCursor, startCursor.isNull(), lineInfos.size());
        if (startCursor.isNull()) {
            startCursor.setCursor(endCursor);
        }
        startCursor.moveToParagraph(paragraphIndex);
        startCursor.moveTo(wordIndex, charIndex);
        endCursor.reset();
        lineInfos.clear();
        paintState = PaintStateEnum.START_IS_KNOWN;
    }

    protected void moveEndCursor(int paragraphIndex, int wordIndex, int charIndex) {
        if (endCursor.isNull()) {
            endCursor.setCursor(startCursor);
        }
        endCursor.moveToParagraph(paragraphIndex);
        if ((paragraphIndex > 0) && (wordIndex == 0) && (charIndex == 0)) {
            endCursor.jumpToPrevParagraph();
            endCursor.moveToParagraphEnd();
        } else {
            endCursor.moveTo(wordIndex, charIndex);
        }
        startCursor.reset();
        lineInfos.clear();
        paintState = PaintStateEnum.END_IS_KNOWN;
    }

    protected int getTextWidth() {
        return myColumnWidth;
    }

    protected int getTextHeight() {
        return myHeight;
    }

    protected boolean twoColumnView() {
        return myTwoColumnView;
    }

    public boolean isTwoColumnView() {
        return column0Height == 0 && myTwoColumnView;
    }

    protected boolean isEmptyPage() {
        for (ZLTextLineInfo info : lineInfos) {
            if (info.isVisible) {
                return false;
            }
        }
        return true;
    }

    protected void findLineFromStart(ZLTextWordCursor cursor, int overlappingValue) {
        if (lineInfos.isEmpty() || (overlappingValue == 0)) {
            cursor.reset();
            return;
        }
        ZLTextLineInfo info = null;
        for (ZLTextLineInfo i : lineInfos) {
            info = i;
            if (info.isVisible) {
                --overlappingValue;
                if (overlappingValue == 0) {
                    break;
                }
            }
        }
        cursor.setCursor(info.paragraphCursor);
        cursor.moveTo(info.endElementIndex, info.endCharIndex);
    }

    protected void findLineFromEnd(ZLTextWordCursor cursor, int overlappingValue) {
        if (lineInfos.isEmpty() || (overlappingValue == 0)) {
            cursor.reset();
            return;
        }
        final ArrayList<ZLTextLineInfo> infos = lineInfos;
        final int size = infos.size();
        ZLTextLineInfo info = null;
        for (int i = size - 1; i >= 0; --i) {
            info = infos.get(i);
            if (info.isVisible) {
                --overlappingValue;
                if (overlappingValue == 0) {
                    break;
                }
            }
        }
        cursor.setCursor(info.paragraphCursor);
        cursor.moveTo(info.startElementIndex, info.startCharIndex);
    }

    protected void findPercentFromStart(ZLTextWordCursor cursor, int percent) {
        if (lineInfos.isEmpty()) {
            cursor.reset();
            return;
        }
        int height = myHeight * percent / 100;
        boolean visibleLineOccured = false;
        ZLTextLineInfo info = null;
        for (ZLTextLineInfo i : lineInfos) {
            info = i;
            if (info.isVisible) {
                visibleLineOccured = true;
            }
            height -= info.height + info.descent + info.VSpaceAfter;
            if (visibleLineOccured && (height <= 0)) {
                break;
            }
        }
        cursor.setCursor(info.paragraphCursor);
        cursor.moveTo(info.endElementIndex, info.endCharIndex);
    }

    public ArrayList<ZLTextLineInfo> getLineInfos() {
        return lineInfos;
    }

    @NonNull
    @Override
    public String toString() {
        return "ZLTextPage{" +
                "startCursor=" + startCursor +
                ", endCursor=" + endCursor +
                ", lineInfos=" + lineInfos +
                ", column0Height=" + column0Height +
                ", paintState=" + DebugHelper.stringifyPatinState(paintState) +
                ", TextElementMap=" + TextElementMap +
                ", myColumnWidth=" + myColumnWidth +
                ", myHeight=" + myHeight +
                ", myTwoColumnView=" + myTwoColumnView +
                '}';
    }
}