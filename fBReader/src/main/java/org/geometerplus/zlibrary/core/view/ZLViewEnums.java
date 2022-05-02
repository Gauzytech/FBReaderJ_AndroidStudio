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

/**
 * ZLView枚举
 */
public interface ZLViewEnums {

    /**
     * 页面索引（前两页，前一页，当前页，下一页，下两页）
     */
    enum PageIndex {

        PREV_2, PREV, CURRENT, NEXT, NEXT_2;

        /**
         * 获取下一页对应索引
         *
         * @return 下一页对应索引
         */
        public PageIndex getNext() {
            switch (this) {
                case PREV_2:
                    return PREV_2;
                case PREV:
                    return CURRENT;
                case CURRENT:
                    return NEXT;
                case NEXT:
                    return NEXT_2;
                default:
                    return null;
            }
        }

        /**
         * 获取上一页对应索引
         *
         * @return 上一页对应索引
         */
        public PageIndex getPrevious() {
            switch (this) {
                case NEXT_2:
                    return NEXT;
                case NEXT:
                    return CURRENT;
                case CURRENT:
                    return PREV;
                case PREV:
                    return PREV_2;
                default:
                    return null;
            }
        }

        public static PageIndex getPageIndex(int index) {
            switch (index) {
                case 0:
                    return PREV_2;
                case 1:
                    return PREV;
                case 2:
                    return CURRENT;
                case 3:
                    return NEXT;
                case 4:
                    return NEXT_2;
                default:
                    return null;
            }
        }
    }

    /**
     * 翻页方向
     */
    enum Direction {
        leftToRight(true), rightToLeft(true), up(false), down(false);

        public final boolean IsHorizontal;

        Direction(boolean isHorizontal) {
            IsHorizontal = isHorizontal;
        }
    }

    /**
     * 动画
     */
    enum Animation {
        none, curl, slide, slideOldStyle, shift, previewNone, previewShift
    }
}