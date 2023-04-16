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
package org.geometerplus.zlibrary.text.view

abstract class ZLTextElement constructor(val type: String) {

    companion object {
        fun hSpace() = HSpaceElement()
        fun nbSpace() = NBSpaceElement()
        fun afterParagraph() = AfterParagraphElement()

        @JvmStatic
        fun indent() = IndentElement()
        fun styleClose() = StyleCloseElement()
    }
}

// 空格, 正常space
class HSpaceElement : ZLTextElement("HSpaceElement")
// NON_BREAKABLE_SPACE
class NBSpaceElement : ZLTextElement("NBSpaceElement")
class AfterParagraphElement : ZLTextElement("AfterParagraphElement")
class IndentElement : ZLTextElement("IndentElement")
class StyleCloseElement : ZLTextElement("StyleCloseElement")