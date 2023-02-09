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

import org.geometerplus.zlibrary.text.model.ZLTextMark;
import org.geometerplus.zlibrary.text.model.ZLTextModel;

public final class ZLTextWordCursor extends ZLTextPosition {
	// 代表当前需要显示的段落的ZLTextParagraphCursor类
	// 一组p标签就代表一个段落
	// ZLTextParagraphCursor对应一个paragraph的解析信息
	private ZLTextParagraphCursor myParagraphCursor;
	// 每个element代表一个word或者一个标签元素, 所以elementIndex就是wordIndex
	private int myElementIndex;
	// 针对英文单词中的字母, 从第一个字母开始
	private int myCharIndex;

//	private int myModelIndex;

	public ZLTextWordCursor() {
	}

	public ZLTextWordCursor(ZLTextWordCursor cursor) {
		setCursor(cursor);
	}

	public ZLTextWordCursor(ZLTextParagraphCursor paragraphCursor) {
		setCursor(paragraphCursor);
	}

	public void setCursor(ZLTextWordCursor cursor) {
		myParagraphCursor = cursor.myParagraphCursor;
		myElementIndex = cursor.myElementIndex;
		myCharIndex = cursor.myCharIndex;
	}

	public void setCursor(ZLTextParagraphCursor paragraphCursor) {
		myParagraphCursor = paragraphCursor;
		// 从当前段落的第一个字开始
		myElementIndex = 0;
		myCharIndex = 0;
	}

	public boolean isNull() {
		return myParagraphCursor == null;
	}

	public boolean isStartOfParagraph() {
		return myElementIndex == 0 && myCharIndex == 0;
	}

	public boolean isStartOfText() {
		return isStartOfParagraph() && myParagraphCursor.isFirst();
	}

	public boolean isEndOfParagraph() {
		return myParagraphCursor != null
				&& myElementIndex == myParagraphCursor.getParagraphLength();
	}

	public boolean isEndOfText() {
		return isEndOfParagraph() && myParagraphCursor.isLast();
	}

	@Override
	public int getParagraphIndex() {
		return myParagraphCursor != null ? myParagraphCursor.paragraphIdx : 0;
	}

	@Override
	public int getElementIndex() {
		// 从myElementIndex属性中获取上一行最后一个字的位置
		return myElementIndex;
	}

	@Override
	public int getCharIndex() {
		return myCharIndex;
	}

	public ZLTextElement getElement() {
		return myParagraphCursor.getElement(myElementIndex);
	}

	public ZLTextParagraphCursor getParagraphCursor() {
		return myParagraphCursor;
	}

	public ZLTextMark getMark() {
		if (myParagraphCursor == null) {
			return null;
		}
		final ZLTextParagraphCursor paragraph = myParagraphCursor;
		int paragraphLength = paragraph.getParagraphLength();
		int wordIndex = myElementIndex;
		while ((wordIndex < paragraphLength) && (!(paragraph.getElement(wordIndex) instanceof ZLTextWord))) {
			wordIndex++;
		}
		if (wordIndex < paragraphLength) {
			return new ZLTextMark(paragraph.paragraphIdx, ((ZLTextWord)paragraph.getElement(wordIndex)).getParagraphOffset(), 0);
		}
		return new ZLTextMark(paragraph.paragraphIdx + 1, 0, 0);
	}

	public void nextWord() {
		myElementIndex++;
		myCharIndex = 0;
	}

	public void previousWord() {
		myElementIndex--;
		myCharIndex = 0;
	}

	public boolean nextParagraph() {
		if (!isNull()) {
			if (!myParagraphCursor.isLast()) {
				myParagraphCursor = myParagraphCursor.next();
				moveToParagraphStart();
				return true;
			}
		}
		return false;
	}

	public boolean previousParagraph() {
		if (!isNull()) {
			if (!myParagraphCursor.isFirst()) {
				myParagraphCursor = myParagraphCursor.previous();
				moveToParagraphStart();
				return true;
			}
		}
		return false;
	}

	public void moveToParagraphStart() {
		if (!isNull()) {
			myElementIndex = 0;
			myCharIndex = 0;
		}
	}

	public void moveToParagraphEnd() {
		if (!isNull()) {
			myElementIndex = myParagraphCursor.getParagraphLength();
			myCharIndex = 0;
		}
	}

	public void moveToParagraph(int paragraphIndex) {
		if (!isNull() && (paragraphIndex != myParagraphCursor.paragraphIdx)) {
			final ZLTextModel model = myParagraphCursor.textModel;
			paragraphIndex = Math.max(0, Math.min(paragraphIndex, model.getParagraphsNumber() - 1));
			// 从cursorManager中获得新的ZLTextParagraphCursor
			myParagraphCursor = myParagraphCursor.getCursor(paragraphIndex);
			moveToParagraphStart();
		}
	}

	public void moveTo(ZLTextPosition position) {
		moveToParagraph(position.getParagraphIndex());
		moveTo(position.getElementIndex(), position.getCharIndex());
	}

	public void moveTo(int wordIndex, int charIndex) {
		if (!isNull()) {
			if (wordIndex == 0 && charIndex == 0) {
				myElementIndex = 0;
				myCharIndex = 0;
			} else {
				wordIndex = Math.max(0, wordIndex);
				int elementSize = myParagraphCursor.getParagraphLength();
				if (wordIndex > elementSize) {
					myElementIndex = elementSize;
					myCharIndex = 0;
				} else {
					// 将代表上一行最后一个字位置的wordIndex赋值给myElementIndex
					myElementIndex = wordIndex;
					setCharIndex(charIndex);
				}
			}
		}
	}

	public void setCharIndex(int charIndex) {
		charIndex = Math.max(0, charIndex);
		myCharIndex = 0;
		if (charIndex > 0) {
			ZLTextElement element = myParagraphCursor.getElement(myElementIndex);
			if (element instanceof ZLTextWord) {
				if (charIndex <= ((ZLTextWord)element).Length) {
					myCharIndex = charIndex;
				}
			}
		}
	}

	public void reset() {
		myParagraphCursor = null;
		myElementIndex = 0;
		myCharIndex = 0;
	}

	public void rebuild() {
		if (!isNull()) {
			myParagraphCursor.clear();
			myParagraphCursor.fillElements();
			moveTo(myElementIndex, myCharIndex);
		}
	}

	@NonNull
	@Override
	public String toString() {
		return "ZLTextWordCursor{" +
				"myParagraphCursor=" + myParagraphCursor +
				", myElementIndex=" + myElementIndex +
				", myCharIndex=" + myCharIndex +
				'}';
	}
}
