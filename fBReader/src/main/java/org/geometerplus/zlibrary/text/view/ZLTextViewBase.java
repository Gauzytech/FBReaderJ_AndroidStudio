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

import org.geometerplus.DebugHelper;
import org.geometerplus.zlibrary.core.application.ZLApplication;
import org.geometerplus.zlibrary.core.filesystem.ZLFile;
import org.geometerplus.zlibrary.core.library.ZLibrary;
import org.geometerplus.zlibrary.core.util.ZLColor;
import org.geometerplus.zlibrary.core.view.ZLPaintContext;
import org.geometerplus.zlibrary.core.view.ZLView;
import org.geometerplus.zlibrary.text.model.ZLTextMetrics;
import org.geometerplus.zlibrary.text.view.style.ZLTextExplicitlyDecoratedStyle;
import org.geometerplus.zlibrary.text.view.style.ZLTextNGStyle;
import org.geometerplus.zlibrary.text.view.style.ZLTextNGStyleDescription;
import org.geometerplus.zlibrary.text.view.style.ZLTextStyleCollection;
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ElementPaintData;
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.TextBlock;

import timber.log.Timber;

abstract class ZLTextViewBase extends ZLView {

    private ZLTextStyle myTextStyle;
    private int myWordHeight = -1;
    private ZLTextMetrics myMetrics;
    private int myMaxSelectionDistance = 0;
    private char[] myWordPartArray = new char[20];

    ZLTextViewBase(ZLApplication application) {
        super(application);
    }

    protected final int maxSelectionDistance() {
        if (myMaxSelectionDistance == 0) {
            myMaxSelectionDistance = ZLibrary.Instance().getDisplayDPI() / 20;
        }
        return myMaxSelectionDistance;
    }

    protected void resetMetrics() {
        myMetrics = null;
    }

    final int getWordHeight() {
        if (myWordHeight == -1) {
            final ZLTextStyle textStyle = myTextStyle;
            myWordHeight = getContext().getStringHeight() * textStyle.getLineSpacePercent() / 100 + textStyle.getVerticalAlign(metrics());
        }
        return myWordHeight;
    }

    public abstract ImageFitting getImageFitting();

    public abstract int getTopMargin();

    public abstract int getBottomMargin();

    public abstract int getSpaceBetweenColumns();

    public abstract ZLFile getWallpaperFile();

    public abstract ZLPaintContext.FillMode getFillMode();

    public abstract ZLColor getBackgroundColor();

    public abstract ZLColor getBookMarkColor();

    public abstract ZLColor getSelectionBackgroundColor();

    public abstract ZLColor getSelectionCursorColor();

    public abstract ZLColor getSelectionForegroundColor();

    public abstract ZLColor getTextColor(ZLTextHyperlink hyperlink);

    ZLPaintContext.Size getTextAreaSize() {
        return new ZLPaintContext.Size(getTextColumnWidth(), getTextAreaHeight());
    }

    /**
     * 一屏可绘制区域的高度
     * 高度 = 顶部标题栏高度 + 图书内容高度 + 底部电量和页码栏高度
     */
    int getTextAreaHeight() {
        // 顶部留出margin: 绘制标题的空间
        int topMargin = getTopMargin();
        // 底部留出margin: 绘制电量图标, 页码的空间
        int bottomMargin = getBottomMargin();
        Timber.v("可绘制区域, mainHeight = %s, bottom = %s", getContextHeight(), bottomMargin);
        return getContextHeight() - topMargin - bottomMargin;
    }

    protected int getColumnIndex(int x) {
        if (!isTwoColumnView()) {
            return -1;
        }
        return 2 * x <= getContextWidth() + getLeftMargin() - getRightMargin() ? 0 : 1;
    }

    public abstract boolean isTwoColumnView();

    public abstract int getLeftMargin();

    public abstract int getRightMargin();

    public int getTextColumnWidth() {
        return isTwoColumnView()
                ? (getContextWidth() - getLeftMargin() - getSpaceBetweenColumns() - getRightMargin()) / 2
                : getContextWidth() - getLeftMargin() - getRightMargin();
    }

    final ZLTextStyle getTextStyle() {
        if (myTextStyle == null) {
            resetTextStyle();
        }
        return myTextStyle;
    }

    final void setTextStyle(ZLTextStyle style) {
        Timber.v("渲染流程:分页, 设置TextStyle, %s", style);
        if (myTextStyle != style) {
            // ZLTextViewBase类的myTextStyle属性将指向代表基本样式的ZLTextBaseStyle类
            myTextStyle = style;
            myWordHeight = -1;
        }
        // 字体相关的样式被存储到ZLTextViewBase类的context属性中
        getContext().setFont(style.getFontEntries(), style.getFontSize(metrics()), style.isBold(), style.isItalic(), style.isUnderline(), style.isStrikeThrough());
    }

    final void resetTextStyle() {
        // getBaseStyle方法将获取代表基本样式的ZLTextBaseStyle类
        setTextStyle(getTextStyleCollection().getBaseStyle());
    }

    public abstract ZLTextStyleCollection getTextStyleCollection();

    /**
     * @return 书页内容渲染的metrics:
     * 1. 屏幕dpi
     * 2. 屏幕宽度
     * 3. 屏幕高度
     * 4. 字体大小
     */
    protected ZLTextMetrics metrics() {
        // this local variable is used to guarantee null will not
        // be returned from this method even in multi-thread environment
        ZLTextMetrics m = myMetrics;
        if (m == null) {
            m = new ZLTextMetrics(
                    ZLibrary.Instance().getDisplayDPI(),
                    // TODO: screen area width
                    100,
                    // TODO: screen area height
                    100,
                    getTextStyleCollection().getBaseStyle().getFontSize()
            );
            myMetrics = m;
        }
        return m;
    }

    boolean isStyleChangeElement(ZLTextElement element) {
        return element instanceof StyleCloseElement ||
                element instanceof ZLTextStyleElement ||
                element instanceof ZLTextControlElement;
    }

    void applyStyleChangeElement(ZLTextElement element) {
        if (element instanceof StyleCloseElement) {
            applyStyleClose();
        } else if (element instanceof ZLTextStyleElement) {
            applyStyle((ZLTextStyleElement) element);
        } else if (element instanceof ZLTextControlElement) {
            // 如果读到代表标签信息的ZLTextControlElement类，就获取标签对应的样式
            applyControl((ZLTextControlElement) element);
        }
    }

    void applyStyleChanges(ZLTextParagraphCursor cursor, int index, int end, String from) {
        if (DebugHelper.filterTag(from, "paint", "gotoPosition")) {
            Timber.v("渲染流程:分页[%s], 1 配置style: cursor = %s, [%d, %d]", from, cursor, index, end);
        }
        for (; index != end; ++index) {
            applyStyleChangeElement(cursor.getElement(index));
        }
    }

    private void applyControl(ZLTextControlElement control) {
        // 判断是否是标签对的起始部分
        if (control.IsStart) {
            // 如果是超链接的style
            final ZLTextHyperlink hyperlink = control instanceof ZLTextHyperlinkControlElement
                    ? ((ZLTextHyperlinkControlElement) control).Hyperlink : null;
            // 非base style, 取出标签样式
            // kind属性在FBTextKind接口中定义
            final ZLTextNGStyleDescription description =
                    getTextStyleCollection().getDescription(control.Kind);
            // 设置标签样式，覆盖base样式
            if (description != null) {
                // 应用标签style
                setTextStyle(new ZLTextNGStyle(myTextStyle, description, hyperlink));
            }
        } else {
            // 标签对结束部分, 就将样式还原
            // 还原的样式就是层级结构的上一层: parent
            setTextStyle(myTextStyle.Parent);
        }
    }

    private void applyStyle(ZLTextStyleElement element) {
        setTextStyle(new ZLTextExplicitlyDecoratedStyle(myTextStyle, element.Entry));
    }

    private void applyStyleClose() {
        // 标签对结束部分, 就将样式还原
        setTextStyle(myTextStyle.Parent);
    }

    protected final ZLPaintContext.ScalingType getScalingType(ZLTextImageElement imageElement) {
        switch (getImageFitting()) {
            default:
            case none:
                return ZLPaintContext.ScalingType.IntegerCoefficient;
            case covers:
                return imageElement.IsCover
                        ? ZLPaintContext.ScalingType.FitMaximum
                        : ZLPaintContext.ScalingType.IntegerCoefficient;
            case all:
                return ZLPaintContext.ScalingType.FitMaximum;
        }
    }

    /** 获得element渲染所需要的宽度. UI操作 */
    final int getElementWidth(ZLTextElement element, int charIndex) {
        if (element instanceof ZLTextWord) {
            return getWordWidth((ZLTextWord) element, charIndex);
        } else if (element instanceof ZLTextImageElement) {
            final ZLTextImageElement imageElement = (ZLTextImageElement) element;
            final ZLPaintContext.Size size = getContext().imageSize(
                    imageElement.ImageData,
                    getTextAreaSize(),
                    getScalingType(imageElement)
            );
            return size != null ? size.Width : 0;
        } else if (element instanceof ZLTextVideoElement) {
            return Math.min(300, getTextColumnWidth());
        } else if (element instanceof ExtensionElement) {
            return ((ExtensionElement) element).getWidth();
        } else if (element instanceof NBSpaceElement) {
            return getContext().getSpaceWidth();
        } else if (element instanceof IndentElement) {
            return myTextStyle.getFirstLineIndent(metrics());
        } else if (element instanceof ZLTextFixedHSpaceElement) {
            return getContext().getSpaceWidth() * ((ZLTextFixedHSpaceElement) element).Length;
        }
        return 0;
    }

    /** 获得element渲染所需要的高度 */
    final int getElementHeight(ZLTextElement element) {
        if (element instanceof NBSpaceElement ||
                element instanceof ZLTextWord ||
                element instanceof ZLTextFixedHSpaceElement) {
            return getWordHeight();
        } else if (element instanceof ZLTextImageElement) {
            final ZLTextImageElement imageElement = (ZLTextImageElement) element;
            final ZLPaintContext.Size size = getContext().imageSize(
                    imageElement.ImageData,
                    getTextAreaSize(),
                    getScalingType(imageElement)
            );
            return (size != null ? size.Height : 0) +
                    Math.max(getContext().getStringHeight() * (myTextStyle.getLineSpacePercent() - 100) / 100, 3);
        } else if (element instanceof ZLTextVideoElement) {
            return Math.min(Math.min(200, getTextAreaHeight()), getTextColumnWidth() * 2 / 3);
        } else if (element instanceof ExtensionElement) {
            return ((ExtensionElement) element).getHeight();
        }
        return 0;
    }

    final int getElementDescent(ZLTextElement element) {
        return element instanceof ZLTextWord ? getContext().getDescent() : 0;
    }

    /**
     * 获得ZLTextWord所包含字符串渲染的宽度
     */
    final int getWordWidth(ZLTextWord word, int start) {
        return start == 0 ?
                        word.getWidth(getContext()) :
                        getContext().getStringWidth(word.Data, word.Offset + start, word.Length - start);
    }

    final int getWordWidth(ZLTextWord word, int start, int length) {
        return getContext().getStringWidth(word.Data, word.Offset + start, length);
    }

    int getAreaLength(ZLTextParagraphCursor paragraph, ZLTextElementArea area, int toCharIndex) {
        setTextStyle(area.Style);
        final ZLTextWord word = (ZLTextWord) paragraph.getElement(area.elementIndex);
        int length = toCharIndex - area.charIndex;
        boolean selectHyphenationSign = false;
        if (length >= area.Length) {
            selectHyphenationSign = area.AddHyphenationSign;
            length = area.Length;
        }
        if (length > 0) {
            return getWordWidth(word, area.charIndex, length, selectHyphenationSign);
        }
        return 0;
    }

    final int getWordWidth(ZLTextWord word, int start, int length, boolean addHyphenationSign) {
        if (length == -1) {
            if (start == 0) {
                return word.getWidth(getContext());
            }
            length = word.Length - start;
        }
        if (!addHyphenationSign) {
            return getContext().getStringWidth(word.Data, word.Offset + start, length);
        }
        char[] part = myWordPartArray;
        if (length + 1 > part.length) {
            part = new char[length + 1];
            myWordPartArray = part;
        }
        System.arraycopy(word.Data, word.Offset + start, part, 0, length);
        part[length] = '-';
        return getContext().getStringWidth(part, 0, length + 1);
    }

    /**
     * 绘制文字
     *
     * @param x                  X坐标
     * @param y                  Y坐标
     * @param word               文字
     * @param start              字符起始索引
     * @param length             长度
     * @param addHyphenationSign 是否断字连接
     * @param color              高亮颜色
     */
    final void drawWord(int x, int y, ZLTextWord word, int start, int length, boolean addHyphenationSign, ZLColor color) {
        final ZLPaintContext context = getContext();
        if (start == 0 && length == -1) { // 绘制整个
            drawString(context, x, y, word.Data, word.Offset, word.Length, word.getMark(), color, 0);
        } else {
            if (length == -1) {
                length = word.Length - start;
            }
            if (!addHyphenationSign) { // 无断字连接
                drawString(context, x, y, word.Data, word.Offset + start, length, word.getMark(), color, start);
            } else { // 有断字连接
                char[] part = myWordPartArray;
                if (length + 1 > part.length) {
                    part = new char[length + 1];
                    myWordPartArray = part;
                }
                // 添加断字连接符
                System.arraycopy(word.Data, word.Offset + start, part, 0, length);
                part[length] = '-';
                drawString(context, x, y, part, 0, length + 1, word.getMark(), color, start);
            }
        }
    }

    final ElementPaintData.Word getDrawWordPaintData(int x, int y, ZLTextWord word, int start, int length, boolean addHyphenationSign, ZLColor color) {
        ElementPaintData.Word.Builder wordDataBuilder = new ElementPaintData.Word.Builder();
        wordDataBuilder.textStyle(getTextStyle());

//        final ZLPaintContext context = getContext();
        if (start == 0 && length == -1) { // 绘制整个
//            drawString(context, x, y, word.Data, word.Offset, word.Length, word.getMark(), color, 0);

            return wordDataBuilder
                    .textBlock(new TextBlock(word.Data, word.Offset, word.Length, x, y))
                    .mark(word.getMark())
                    .color(color)
                    .shift(0)
                    .build();
        } else {
            if (length == -1) {
                length = word.Length - start;
            }
            if (!addHyphenationSign) { // 无断字连接
//                drawString(context, x, y, word.Data, word.Offset + start, length, word.getMark(), color, start);
                wordDataBuilder
                        .textBlock(new TextBlock(word.Data, word.Offset + start, length, x, y))
                        .mark(word.getMark())
                        .color(color)
                        .shift(start);
            } else { // 有断字连接
                char[] part = myWordPartArray;
                if (length + 1 > part.length) {
                    part = new char[length + 1];
                    myWordPartArray = part;
                }
                // 添加断字连接符
                System.arraycopy(word.Data, word.Offset + start, part, 0, length);
                part[length] = '-';
//                drawString(context, x, y, part, 0, length + 1, word.getMark(), color, start);
                wordDataBuilder
                        .textBlock(new TextBlock(part, 0, length + 1, x, y))
                        .mark(word.getMark())
                        .color(color)
                        .shift(start);
            }

            return wordDataBuilder.build();
        }
    }


    /**
     * 绘制字符串
     *
     * @param context 画笔上下文
     * @param x       X坐标
     * @param y       Y坐标
     * @param str     字符串
     * @param offset  位移
     * @param length  长度
     * @param mark    标记信息
     * @param color   高亮前景色
     * @param shift   变换
     */
    protected void drawString(ZLPaintContext context, int x, int y, char[] str, int offset, int length, ZLTextWord.Mark mark, ZLColor color, int shift) {
        if (mark == null) { // 无标记
            context.setTextColor(color);
            context.drawString(x, y, str, offset, length);
        } else { // 有标记
            int pos = 0;
            for (; (mark != null) && (pos < length); mark = mark.getNext()) {
                // 标记的起始
                int markStart = mark.Start - shift;
                // 标记的长度
                int markLen = mark.Length;

                if (markStart < pos) {
                    markLen += markStart - pos;
                    markStart = pos;
                }

                if (markLen <= 0) {
                    continue;
                }

                if (markStart > pos) {
                    int endPos = Math.min(markStart, length);
                    context.setTextColor(color);
                    context.drawString(x, y, str, offset + pos, endPos - pos);
                    x += context.getStringWidth(str, offset + pos, endPos - pos);
                }

                if (markStart < length) {
                    context.setFillColor(getHighlightingBackgroundColor());
                    int endPos = Math.min(markStart + markLen, length);
                    final int endX = x + context.getStringWidth(str, offset + markStart, endPos - markStart);
                    context.fillRectangle(x, y - context.getStringHeight(), endX - 1, y + context.getDescent());
                    context.setTextColor(getHighlightingForegroundColor());
                    context.drawString(x, y, str, offset + markStart, endPos - markStart);
                    x = endX;
                }
                pos = markStart + markLen;
            }

            if (pos < length) {
                context.setTextColor(color);
                context.drawString(x, y, str, offset + pos, length - pos);
            }
        }
    }

    public abstract ZLColor getHighlightingBackgroundColor();

    public abstract ZLColor getHighlightingForegroundColor();

    public enum ImageFitting {
        none, covers, all
    }
}