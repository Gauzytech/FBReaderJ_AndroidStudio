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


/**
 * 文本固定位置
 */
public class ZLTextFixedPosition extends ZLTextPosition {

    /**
     * 段落索引
     */
    public final int paragraphIndex;
    /**
     * 元素索引
     */
    public final int elementIndex;
    /**
     * 字符索引
     */
    public final int charIndex;

    public ZLTextFixedPosition(int paragraphIndex, int elementIndex, int charIndex) {
        this.paragraphIndex = paragraphIndex;
        this.elementIndex = elementIndex;
        this.charIndex = charIndex;
    }

    public ZLTextFixedPosition(ZLTextPosition position) {
        this.paragraphIndex = position.getParagraphIndex();
        this.elementIndex = position.getElementIndex();
        this.charIndex = position.getCharIndex();
    }

    public final int getParagraphIndex() {
        return paragraphIndex;
    }

    public final int getElementIndex() {
        return elementIndex;
    }

    public final int getCharIndex() {
        return charIndex;
    }

    /**
     * 带有时间戳的 文本固定位置
     */
    public static class WithTimestamp extends ZLTextFixedPosition {

        public final long Timestamp;

        public WithTimestamp(int paragraphIndex, int elementIndex, int charIndex, Long stamp) {
            super(paragraphIndex, elementIndex, charIndex);
            Timestamp = stamp != null ? stamp : -1;
        }

        @NonNull
        @Override
        public String toString() {
            return "WithTimestamp{" +
                    "ParagraphIndex=" + paragraphIndex +
                    ", ElementIndex=" + elementIndex +
                    ", CharIndex=" + charIndex +
                    ", Timestamp=" + Timestamp +
                    '}';
        }
    }
}