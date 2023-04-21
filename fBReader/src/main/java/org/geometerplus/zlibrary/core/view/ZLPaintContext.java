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

package org.geometerplus.zlibrary.core.view;

import org.geometerplus.zlibrary.core.filesystem.ZLFile;
import org.geometerplus.zlibrary.core.fonts.FontEntry;
import org.geometerplus.zlibrary.core.image.ZLImageData;
import org.geometerplus.zlibrary.core.util.SystemInfo;
import org.geometerplus.zlibrary.core.util.ZLColor;
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * 画笔上下文（绘制相关）
 */
abstract public class ZLPaintContext {

    private final SystemInfo mySystemInfo;

    protected ZLPaintContext(SystemInfo systemInfo) {
        mySystemInfo = systemInfo;
    }

    public enum FillMode {
        tile,
        tileMirror,
        fullscreen,
        stretch,
        tileVertically,
        tileHorizontally
    }

    public final SystemInfo getSystemInfo() {
        return mySystemInfo;
    }

    abstract public void clear(ZLFile wallpaperFile, FillMode mode);

    abstract public void clear(ZLColor color);

    /**
     * 获取背景色
     *
     * @return 背景色
     */
    abstract public ZLColor getBackgroundColor();

    /**
     * 是否重置字体
     */
    private boolean myResetFont = true;
    /**
     * 字体集合
     */
    private List<FontEntry> myFontEntries;
    /**
     * 字体大小
     */
    private int myFontSize;
    /**
     * 字体-粗体
     */
    private boolean myFontIsBold;
    /**
     * 字体-斜体
     */
    private boolean myFontIsItalic;
    /**
     * 字体-下划线
     */
    private boolean myFontIsUnderlined;
    /**
     * 字体-中划线
     */
    private boolean myFontIsStrikeThrough;

    /**
     * 设置字体相关属性（内部实现）
     * 有一个属性变化就RestFont
     *
     * @param entries       字体集合
     * @param size          字体大小
     * @param bold          粗体
     * @param italic        斜体
     * @param underline     下划线
     * @param strikeThrough 中划线
     */
    public final void setFont(List<FontEntry> entries, int size, boolean bold, boolean italic, boolean underline, boolean strikeThrough) {
        if (entries != null && !entries.equals(myFontEntries)) {
            myFontEntries = entries;
            myResetFont = true;
        }
        if (myFontSize != size) {
            myFontSize = size;
            myResetFont = true;
        }
        if (myFontIsBold != bold) {
            myFontIsBold = bold;
            myResetFont = true;
        }
        if (myFontIsItalic != italic) {
            myFontIsItalic = italic;
            myResetFont = true;
        }
        if (myFontIsUnderlined != underline) {
            myFontIsUnderlined = underline;
            myResetFont = true;
        }
        if (myFontIsStrikeThrough != strikeThrough) {
            myFontIsStrikeThrough = strikeThrough;
            myResetFont = true;
        }
        if (myResetFont) {
            myResetFont = false;
            setFontInternal(myFontEntries, size, bold, italic, underline, strikeThrough);
            mySpaceWidth = -1;
            myStringHeight = -1;
            myDescent = -1;
            myCharHeights.clear();
        }
    }

    /**
     * 设置字体相关属性（内部实现）
     *
     * @param entries       字体集合
     * @param size          字体大小
     * @param bold          粗体
     * @param italic        斜体
     * @param underline     下划线
     * @param strikeThrough 中划线
     */
    abstract protected void setFontInternal(List<FontEntry> entries, int size, boolean bold, boolean italic, boolean underline, boolean strikeThrough);

    /**
     * 设置文字颜色
     *
     * @param color 颜色
     */
    abstract public void setTextColor(ZLColor color);

    abstract public void setExtraFoot(int textSize, ZLColor color);

    /**
     * 设置线颜色
     *
     * @param color 线颜色
     */
    abstract public void setLineColor(ZLColor color);

    /**
     * 设置线的宽度
     *
     * @param width 线的宽度
     */
    abstract public void setLineWidth(int width);

    /**
     * 设置填充颜色
     *
     * @param color 颜色
     */
    public final void setFillColor(ZLColor color) {
        setFillColor(color, 0xFF);
    }

    /**
     * 设置填充颜色
     *
     * @param color 颜色
     * @param alpha 透明度
     */
    abstract public void setFillColor(ZLColor color, int alpha);

    abstract public ZLAndroidPaintContext.Geometry getGeometry();

    /**
     * 获取宽度
     *
     * @return 宽度
     */
    abstract public int getWidth();

    /**
     * 获取高度
     *
     * @return 高度
     */
    abstract public int getHeight();

    /**
     * 获取字符串宽度
     *
     * @param string 字符串
     * @return 字符串宽度
     */
    public final int getStringWidth(String string) {
        return getStringWidth(string.toCharArray(), 0, string.length());
    }

    /**
     * 使用{@link org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext.myTextPaint}获取字符串宽度
     *
     * @param string 字符串数组
     * @param offset 偏移量
     * @param length 字符长度
     * @return 字符串宽度
     */
    abstract public int getStringWidth(char[] string, int offset, int length);

    public final int getExtraStringWidth(String string) {
        return getExtraStringWidth(string.toCharArray(), 0, string.length());
    }

    abstract public int getExtraStringWidth(char[] string, int offset, int length);

    private int mySpaceWidth = -1;

    /**
     * 获取空格宽度
     *
     * @return 空格宽度
     */
    public final int getSpaceWidth() {
        int spaceWidth = mySpaceWidth;
        if (spaceWidth == -1) {
            spaceWidth = getSpaceWidthInternal();
            mySpaceWidth = spaceWidth;
        }
        return spaceWidth;
    }

    /**
     * 获取空格宽度（内部实现）
     *
     * @return 空格宽度
     */
    protected abstract int getSpaceWidthInternal();

    private int myStringHeight = -1;

    /**
     * 获取字符串高度
     *
     * @return 字符串高度
     */
    public final int getStringHeight() {
        int stringHeight = myStringHeight;
        if (stringHeight == -1) {
            stringHeight = getStringHeightInternal();
            myStringHeight = stringHeight;
        }
        return stringHeight;
    }

    /**
     * 获取字符串高度
     *
     * @return 字符串高度
     */
    protected abstract int getStringHeightInternal();

    private Map<Character, Integer> myCharHeights = new TreeMap<Character, Integer>();

    public final int getCharHeight(char chr) {
        final Integer h = myCharHeights.get(chr);
        if (h != null) {
            return h;
        }
        final int he = getCharHeightInternal(chr);
        myCharHeights.put(chr, he);
        return he;
    }

    protected abstract int getCharHeightInternal(char chr);

    private int myDescent = -1;

    public final int getDescent(String from) {
        int descent = myDescent;
        if (descent == -1) {
            descent = getDescentInternal();
            myDescent = descent;
        }
        return descent;
    }

    /**
     * 字符baseline到bottom到距离.
     * 见https://www.jianshu.com/p/71cf11c120f0
     */
    abstract protected int getDescentInternal();

    /**
     * 绘制整个字符串
     *
     * @param x      起始X
     * @param y      起始Y
     * @param string 字符串
     */
    public final void drawString(int x, int y, String string) {
        drawString(x, y, string.toCharArray(), 0, string.length());
    }

    /**
     * 绘制字符串（抽象）
     *
     * @param x      起始X
     * @param y      起始Y
     * @param string 字符串数组
     * @param offset 偏移（字符串数组的偏移）
     * @param length 绘制的字符长度
     */
    abstract public void drawString(int x, int y, char[] string, int offset, int length);

    abstract public StringBuilder getDrawString(int x, int y, char[] string, int offset, int length);

    public static final class Size {
        public final int Width;
        public final int Height;

        public Size(int w, int h) {
            Width = w;
            Height = h;
        }

        @Override
        public boolean equals(Object other) {
            if (other == this) {
                return true;
            }
            if (!(other instanceof Size)) {
                return false;
            }
            final Size s = (Size) other;
            return Width == s.Width && Height == s.Height;
        }

        @Override
        public String toString() {
            return "ZLPaintContext.Size[" + Width + "x" + Height + "]";
        }
    }

    public enum ScalingType {
        OriginalSize,
        IntegerCoefficient,
        FitMaximum
    }

    public enum ColorAdjustingMode {
        NONE,
        DARKEN_TO_BACKGROUND,
        LIGHTEN_TO_BACKGROUND
    }

    /** 获得书页中的插图, 耗时操作 */
    abstract public Size imageSize(ZLImageData image, Size maxSize, ScalingType scaling);

    abstract public void drawImage(int x, int y, ZLImageData image, Size maxSize, ScalingType scaling, ColorAdjustingMode adjustingMode);

    /**
     * 绘制线（抽象）
     *
     * @param x0 起始X
     * @param y0 起始Y
     * @param x1 结束X
     * @param y1 结束Y
     */
    abstract public void drawLine(int x0, int y0, int x1, int y1);

    /**
     * 绘制实心矩形（抽象）
     *
     * @param x0 起始X
     * @param y0 起始Y
     * @param x1 结束X
     * @param y1 结束Y
     */
    abstract public void fillRectangle(int x0, int y0, int x1, int y1);

    abstract public void drawHeader(int x, int y, String title);

    abstract public void drawFooter(int x, int y, String progress);

    /**
     * 绘制多边形线
     *
     * @param xs X坐标集合
     * @param ys Y坐标集合
     */
    abstract public void drawPolygonalLine(int[] xs, int[] ys);

    /**
     * 绘制实心多边形（抽象）
     *
     * @param xs X坐标集合
     * @param ys Y坐标集合
     */
    abstract public void fillPolygon(int[] xs, int[] ys);

    /**
     * 绘制轮廓线
     *
     * @param xs X坐标集合
     * @param ys Y坐标集合
     */
    abstract public void drawOutline(int[] xs, int[] ys);

    /**
     * 绘制实心圆（抽象）
     *
     * @param x      圆心X
     * @param y      圆心Y
     * @param radius 圆半径
     */
    abstract public void fillCircle(int x, int y, int radius);

    /**
     * 绘制书签（抽象）
     *
     * @param x0 起始X
     * @param y0 起始Y
     * @param x1 结束X
     * @param y1 结束Y
     */
    abstract public void drawBookMark(int x0, int y0, int x1, int y1);
}