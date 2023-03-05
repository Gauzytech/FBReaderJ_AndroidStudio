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

import org.geometerplus.zlibrary.core.image.ZLImage;
import org.geometerplus.zlibrary.core.image.ZLImageData;
import org.geometerplus.zlibrary.core.image.ZLImageManager;
import org.geometerplus.zlibrary.core.resources.ZLResource;
import org.geometerplus.zlibrary.text.model.ZLImageEntry;
import org.geometerplus.zlibrary.text.model.ZLTextMark;
import org.geometerplus.zlibrary.text.model.ZLTextModel;
import org.geometerplus.zlibrary.text.model.ZLTextOtherStyleEntry;
import org.geometerplus.zlibrary.text.model.ZLTextParagraph;
import org.geometerplus.zlibrary.text.model.ZLTextPlainModel;
import org.geometerplus.zlibrary.text.model.ZLTextStyleEntry;
import org.vimgadgets.linebreak.LineBreaker;

import java.util.ArrayList;
import java.util.List;

import timber.log.Timber;

/**
 *
 * 本地缓存解析文件类, 包含一个paragraph的解析信息
 *
 * 通过{@link #getParagraph()}获得paragraph的解析信息, 利用Iterator将paragraph读取每个entry然后加到myElements
 *
 * 一组p标签就代表一个段落(Paragraph),
 *
 * @see ZLParagraphElementProcessor
 * @see ZLTextPlainModel.EntryIteratorImpl
 */
public final class ZLTextParagraphCursor {
	public final static String DRM = "drm";
	public final static String ENCRYPTED_SECTION = "encryptedSection";

	// index是paragraphIndex, 1个或多个paragraphIndex对应1个cpp myPool中char[] row的idx
	// 因为一个char[]的内容会写到一个.ncache的文件中, 这个文件会包含一个或者多个paragraph
	public final int paragraphIdx;
	private final CursorManager cursorManager;
	public final ZLTextModel textModel;
	private final ArrayList<ZLTextElement> myElements;

	public ZLTextParagraphCursor(ZLTextModel textModel, int paragraphIndex) {
		this(new CursorManager(textModel, null), textModel, paragraphIndex);
	}

	public ZLTextParagraphCursor(CursorManager cursorManager, ZLTextModel textModel, int paragraphIndex) {
		this.cursorManager = cursorManager;
		this.textModel = textModel;
		this.paragraphIdx = Math.min(paragraphIndex, textModel.getParagraphsNumber() - 1);
		this.myElements = new ArrayList<>();

		Timber.v("渲染流程, 初始化ParagraphCursor index = %d, finalIdx = %d", paragraphIndex, this.paragraphIdx);

		// 从textModel中获得Index对应的段落
		fillElements();
		if (myElements.isEmpty()) {
			Timber.v("渲染流程, index = %d, no elements", paragraphIdx);
		} else {
			if (paragraphIdx < 10) {
				Timber.v("渲染流程, Start ------------------------------------------- %d --- myElements.size = %s ---------------------------------", paragraphIdx, myElements.size());
				for (ZLTextElement item : myElements) {
					Timber.v("渲染流程, | %s ", item.toString());
				}
				Timber.v("渲染流程, End ------------------------------------------------------------------------------------------------------------------------------------");
			}
		}
	}

	private static final char[] SPACE_ARRAY = {' '};

	/**
	 * 填充paragraph每个元素的信息到myElements,
	 * eg: 样式标签, 每个text word
	 */
	public void fillElements() {
		// 这个paragraph其实包含了一个缓存解析文件的所有数据, 通过调用其中的iterator将所有数据填充到myElements中
		ZLTextParagraph paragraph = getParagraph();
		// 根据kind类型对myElements进行填充
		// TEXT_PARAGRAPH
		// EMPTY_LINE_PARAGRAPH
		// ENCRYPTED_SECTION_PARAGRAPH
		switch (paragraph.getKind()) {
			case ZLTextParagraph.Kind.TEXT_PARAGRAPH:
				Timber.v("填充段落kind: TEXT_PARAGRAPH ");
				// 处理文本段落
				LineBreaker lineBreaker = new LineBreaker(textModel.getLanguage());
				List<ZLTextMark> marks = textModel.getMarks();
				ZLParagraphElementProcessor processor = new ZLParagraphElementProcessor(
						paragraph,
						cursorManager.extensionManager,
						lineBreaker,
						marks,
						0,
						paragraphIdx);
				myElements.addAll(processor.fillElements());
				break;
			case ZLTextParagraph.Kind.EMPTY_LINE_PARAGRAPH:
				Timber.v("填充段落kind: EMPTY_LINE_PARAGRAPH ");
				// 处理占位空段落，占满一行
				myElements.add(new ZLTextWord(SPACE_ARRAY, 0, 1, 0));
				break;
			case ZLTextParagraph.Kind.ENCRYPTED_SECTION_PARAGRAPH: {
				Timber.v("填充段落kind: ENCRYPTED_SECTION_PARAGRAPH ");
				// 处理加密段落
				final ZLTextStyleEntry entry = new ZLTextOtherStyleEntry();
				entry.setFontModifier(ZLTextStyleEntry.FontModifier.FONT_MODIFIER_BOLD, true);
				myElements.add(new ZLTextStyleElement(entry));
				myElements.add(new ZLTextWord(ZLResource.resource(DRM).getResource(ENCRYPTED_SECTION).getValue(), 0));
				break;
			}
			default:
				break;
		}
	}

	public void clear() {
		myElements.clear();
	}

	public boolean isFirst() {
		return paragraphIdx == 0;
	}

	public boolean isLast() {
		return paragraphIdx + 1 >= textModel.getParagraphsNumber();
	}

	public boolean isLikeEndOfSection() {
		switch (textModel.getParagraph(paragraphIdx).getKind()) {
			case ZLTextParagraph.Kind.END_OF_SECTION_PARAGRAPH:
			case ZLTextParagraph.Kind.PSEUDO_END_OF_SECTION_PARAGRAPH:
				return true;
			default:
				return false;
		}
	}

	public boolean isEndOfSection() {
		return textModel.getParagraph(paragraphIdx).getKind() == ZLTextParagraph.Kind.END_OF_SECTION_PARAGRAPH;
	}

	int getParagraphLength() {
		return myElements.size();
	}

	public ZLTextParagraphCursor previous() {
		return isFirst() ? null : getCursor(paragraphIdx - 1);
	}

	public ZLTextParagraphCursor next() {
		return isLast() ? null : getCursor(paragraphIdx + 1);
	}

	public ZLTextParagraphCursor getCursor(int idx) {
		return cursorManager.get(idx);
	}

	/**
	 * 一个paragraph可以有多个elements.
	 * ZLTextElement可以是ZLTextImageElement, ZLTextWord等
	 *
	 * @param index element的坐标
	 */
	ZLTextElement getElement(int index) {
		if (index >= 0 && index < myElements.size()) {
			return myElements.get(index);
		}
		return null;
	}

	ZLTextParagraph getParagraph() {
		return textModel.getParagraph(paragraphIdx);
	}

	public String stringifyElements() {
		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < myElements.size(); i++) {
			sb.append(i).append(", ").append(myElements.get(i)).append("\n");
		}
		sb.deleteCharAt(sb.length() - 1);
		return sb.toString();
	}

	@NonNull
	@Override
	public String toString() {
		return "ZLTextParagraphCursor{paragraphIdx= " + paragraphIdx + " (0.." + myElements.size() + ")}";
	}
}
