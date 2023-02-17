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

import timber.log.Timber;

final class ZLTextLineInfo {
	final ZLTextParagraphCursor paragraphCursor;
	final int paragraphCursorLength;

	final int startElementIndex;
	final int startCharIndex;
	// 代表每一行第一个字在myElements List中的位置
	int realStartElementIndex;
	int realStartCharIndex;
	// 代表每一行最后一个字在myElements List中的位置
	int endElementIndex;
	int endCharIndex;

	boolean isVisible;
	int leftIndent;
	int width;
	int height;
	// 字符baseline到bottom到距离
	// https://www.jianshu.com/p/71cf11c120f0
	int descent;
	int VSpaceBefore;
	int VSpaceAfter;
	boolean previousInfoUsed;
	int spaceCounter;
	ZLTextStyle startStyle;

	ZLTextLineInfo(ZLTextParagraphCursor paragraphCursor, int elementIndex, int charIndex, ZLTextStyle style) {
		this.paragraphCursor = paragraphCursor;
		this.paragraphCursorLength = paragraphCursor.getParagraphLength();

		this.startElementIndex = elementIndex;
		this.startCharIndex = charIndex;
		this.realStartElementIndex = elementIndex;
		this.realStartCharIndex = charIndex;
		this.endElementIndex = elementIndex;
		this.endCharIndex = charIndex;

		this.startStyle = style;
	}

	boolean isEndOfParagraph() {
		return endElementIndex == paragraphCursorLength;
	}

	void adjust(ZLTextLineInfo previous) {
		if (!previousInfoUsed && previous != null) {
			height -= Math.min(previous.VSpaceAfter, VSpaceBefore);
			Timber.v("渲染流程:分页, adjust %s, %s", previous.VSpaceAfter, VSpaceBefore);
			previousInfoUsed = true;
		}
	}

	@Override
	public boolean equals(Object o) {
		ZLTextLineInfo info = (ZLTextLineInfo)o;
		return
			(paragraphCursor == info.paragraphCursor) &&
			(startElementIndex == info.startElementIndex) &&
			(startCharIndex == info.startCharIndex);
	}

	@Override
	public int hashCode() {
		return paragraphCursor.hashCode() + startElementIndex + 239 * startCharIndex;
	}

	@Override
	public String toString() {
		return "ZLTextLineInfo{" +
				"paragraphCursor=" + paragraphCursor +
				", paragraphCursorLength=" + paragraphCursorLength +
				", startElementIndex=" + startElementIndex +
				", startCharIndex=" + startCharIndex +
				", realStartElementIndex=" + realStartElementIndex +
				", realStartCharIndex=" + realStartCharIndex +
				", endElementIndex=" + endElementIndex +
				", endCharIndex=" + endCharIndex +
				", isVisible=" + isVisible +
				", leftIndent=" + leftIndent +
				", width=" + width +
				", height=" + height +
				", descent=" + descent +
				", VSpaceBefore=" + VSpaceBefore +
				", VSpaceAfter=" + VSpaceAfter +
				", previousInfoUsed=" + previousInfoUsed +
				", spaceCounter=" + spaceCounter +
				", startStyle=" + startStyle +
				'}';
	}
}
