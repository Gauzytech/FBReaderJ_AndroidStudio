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

import org.geometerplus.zlibrary.core.image.ZLImage;
import org.geometerplus.zlibrary.core.image.ZLImageData;
import org.geometerplus.zlibrary.core.image.ZLImageManager;
import org.geometerplus.zlibrary.core.resources.ZLResource;
import org.geometerplus.zlibrary.text.model.ZLImageEntry;
import org.geometerplus.zlibrary.text.model.ZLTextMark;
import org.geometerplus.zlibrary.text.model.ZLTextModel;
import org.geometerplus.zlibrary.text.model.ZLTextOtherStyleEntry;
import org.geometerplus.zlibrary.text.model.ZLTextParagraph;
import org.geometerplus.zlibrary.text.model.ZLTextStyleEntry;
import org.vimgadgets.linebreak.LineBreaker;

import java.util.ArrayList;
import java.util.List;

import timber.log.Timber;

public final class ZLTextParagraphCursor {
	public final int index;
	final CursorManager cursorManager;
	public final ZLTextModel textModel;
	private final ArrayList<ZLTextElement> myElements = new ArrayList<ZLTextElement>();

	public ZLTextParagraphCursor(ZLTextModel textModel, int index) {
		this(new CursorManager(textModel, null), textModel, index);
	}

	public ZLTextParagraphCursor(CursorManager cManager, ZLTextModel textModel, int index) {
		this.cursorManager = cManager;
		this.textModel = textModel;
		this.index = Math.min(index, textModel.getParagraphsNumber() - 1);
		// 从textModel中获得Index对应的段落
		fill();
		Timber.v("渲染流程, index = %d myElements size = %s", index, myElements.size());
		if (index < 10) {
			Timber.v("渲染流程, ---------------------------------------------------------------------------------------");
			for (ZLTextElement item : myElements) {
				Timber.v("渲染流程, | %s ", item.toString());
			}
			Timber.v("渲染流程, ---------------------------------------------------------------------------------------");
		}
	}

	private static final char[] SPACE_ARRAY = {' '};

	/**
	 * 填充myElements
	 */
	public void fill() {
		// 获得段落的placement类
		ZLTextParagraph paragraph = textModel.getParagraph(index);
		// 根据paragraph类型对myElements进行填充
		// TEXT_PARAGRAPH
		// EMPTY_LINE_PARAGRAPH
		// ENCRYPTED_SECTION_PARAGRAPH
		switch (paragraph.getKind()) {
			case ZLTextParagraph.Kind.TEXT_PARAGRAPH:
//				Timber.v("渲染流程, TEXT_PARAGRAPH");
				// 处理文本段落
				new Processor(paragraph, cursorManager.ExtensionManager, new LineBreaker(textModel.getLanguage()), textModel.getMarks(), index, myElements).fill();
				break;
			case ZLTextParagraph.Kind.EMPTY_LINE_PARAGRAPH:
//				Timber.v("渲染流程, EMPTY_LINE_PARAGRAPH");
				// 处理占位空段落，占满一行
				myElements.add(new ZLTextWord(SPACE_ARRAY, 0, 1, 0));
				break;
			case ZLTextParagraph.Kind.ENCRYPTED_SECTION_PARAGRAPH: {
//				Timber.v("渲染流程, ENCRYPTED_SECTION_PARAGRAPH");
				// 处理加密段落
				final ZLTextStyleEntry entry = new ZLTextOtherStyleEntry();
				entry.setFontModifier(ZLTextStyleEntry.FontModifier.FONT_MODIFIER_BOLD, true);
				myElements.add(new ZLTextStyleElement(entry));
				myElements.add(new ZLTextWord(ZLResource.resource("drm").getResource("encryptedSection").getValue(), 0));
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
		return index == 0;
	}

	public boolean isLast() {
		return index + 1 >= textModel.getParagraphsNumber();
	}

	public boolean isLikeEndOfSection() {
		switch (textModel.getParagraph(index).getKind()) {
			case ZLTextParagraph.Kind.END_OF_SECTION_PARAGRAPH:
			case ZLTextParagraph.Kind.PSEUDO_END_OF_SECTION_PARAGRAPH:
				return true;
			default:
				return false;
		}
	}

	public boolean isEndOfSection() {
		return textModel.getParagraph(index).getKind() == ZLTextParagraph.Kind.END_OF_SECTION_PARAGRAPH;
	}

	int getParagraphLength() {
		return myElements.size();
	}

	public ZLTextParagraphCursor previous() {
		return isFirst() ? null : cursorManager.get(index - 1);
	}

	public ZLTextParagraphCursor next() {
		return isLast() ? null : cursorManager.get(index + 1);
	}

	ZLTextElement getElement(int index) {
		try {
			return myElements.get(index);
		} catch (IndexOutOfBoundsException e) {
			return null;
		}
	}

	ZLTextParagraph getParagraph() {
		return textModel.getParagraph(index);
	}

	@Override
	public String toString() {
		return "ZLTextParagraphCursor [" + index + " (0.." + myElements.size() + ")]";
	}

	private static final class Processor {
		private final ZLTextParagraph myParagraph;
		private final ExtensionElementManager myExtManager;
		private final LineBreaker myLineBreaker;
		private final ArrayList<ZLTextElement> myElements;
		private int myOffset;
		private int myFirstMark;
		private int myLastMark;
		private final List<ZLTextMark> myMarks;

		/**
		 * myElement填充类
		 * @param paragraph 段落placement类
		 * @param extManager cacheManager中的extManager
		 * @param lineBreaker 分行cpp工具类
		 * @param marks textModel中mark类, 这是干啥的????
		 * @param paragraphIndex 段落号
		 * @param elements 填充对象
		 */
		private Processor(ZLTextParagraph paragraph, ExtensionElementManager extManager, LineBreaker lineBreaker, List<ZLTextMark> marks, int paragraphIndex, ArrayList<ZLTextElement> elements) {
			this.myParagraph = paragraph;
			this.myExtManager = extManager;
			this.myLineBreaker = lineBreaker;
			this.myElements = elements;
			this.myMarks = marks;
			// 定位mark操作
			final ZLTextMark mark = new ZLTextMark(paragraphIndex, 0, 0);
			for (int i = 0; i < myMarks.size(); i++) {
				ZLTextMark currentMark = myMarks.get(i);
				/*
				 * == 0: mark相等
				 * > 0: currentMark > mark
				 * < 0: currentMark < mark
				 */
				if (currentMark.compareTo(mark) >= 0) {
					myFirstMark = i;
					break;
				}
			}
			myLastMark = myFirstMark;
			// 定位lastMark, 应该是paragraphIndex之后的paragraphIndex
			while (myLastMark != myMarks.size() && myMarks.get(myLastMark).ParagraphIndex == paragraphIndex) {
				myLastMark++;
			}
//			for (; myLastMark != myMarks.size() && myMarks.get(myLastMark).ParagraphIndex == paragraphIndex; myLastMark++);
			myOffset = 0;
		}

		/**
		 * 根据myParagraph entry初始化myElements
		 */
		public void fill() {
			int hyperlinkDepth = 0;
			ZLTextHyperlink hyperlink = null;

			// reference传递
			final List<ZLTextElement> elements = myElements;
			// 这里会最终调用EntryIteratorImpl类的构造函数
			for (ZLTextParagraph.EntryIterator it = myParagraph.iterator(); it.next(); ) {
				switch (it.getType()) {
					// 对于文本信息调用Processor类的processTextEntry方法
					// 将ZLTextWord类加入ZLTextParagraphCursor类myElements属性指向的ArrayList
					case ZLTextParagraph.Entry.TEXT:
						processTextEntry(it.getTextData(), it.getTextOffset(), it.getTextLength(), hyperlink);
						break;
					// 对于标签信息
					// 则直接将ZLTextControlElement类加入
					// ZLTextParagraphCursor类myElements属性指向的ArrayList
					case ZLTextParagraph.Entry.CONTROL:
						if (hyperlink != null) {
							hyperlinkDepth += it.getControlIsStart() ? 1 : -1;
							if (hyperlinkDepth == 0) {
								hyperlink = null;
							}
						}
						elements.add(ZLTextControlElement.get(
								it.getControlKind(), 		// 获取myControlKind属性, 代表标签种类
								it.getControlIsStart())		// 获取myControlStart属性, 代表是标签对的开始还是结束标签
						);
						break;
					case ZLTextParagraph.Entry.HYPERLINK_CONTROL:
					{
						final byte hyperlinkType = it.getHyperlinkType();
						if (hyperlinkType != 0) {
							final ZLTextHyperlinkControlElement control =
									new ZLTextHyperlinkControlElement(
											it.getControlKind(), hyperlinkType, it.getHyperlinkId()
									);
							elements.add(control);
							hyperlink = control.Hyperlink;
							hyperlinkDepth = 1;
						}
						break;
					}
					case ZLTextParagraph.Entry.IMAGE:
						final ZLImageEntry imageEntry = it.getImageEntry();
						final ZLImage image = imageEntry.getImage();
						if (image != null) {
							ZLImageData data = ZLImageManager.Instance().getImageData(image);
							if (data != null) {
								if (hyperlink != null) {
									hyperlink.addElementIndex(elements.size());
								}
								elements.add(new ZLTextImageElement(imageEntry.Id, data, image.getURI(), imageEntry.IsCover));
							}
						}
						break;
					case ZLTextParagraph.Entry.AUDIO:
						break;
					case ZLTextParagraph.Entry.VIDEO:
						elements.add(new ZLTextVideoElement(it.getVideoEntry().sources()));
						break;
					case ZLTextParagraph.Entry.EXTENSION:
						if (myExtManager != null) {
							elements.addAll(myExtManager.getElements(it.getExtensionEntry()));
						}
						break;
					case ZLTextParagraph.Entry.STYLE_CSS:
					case ZLTextParagraph.Entry.STYLE_OTHER:
						elements.add(new ZLTextStyleElement(it.getStyleEntry()));
						break;
					case ZLTextParagraph.Entry.STYLE_CLOSE:
						elements.add(ZLTextElement.StyleClose);
						break;
					case ZLTextParagraph.Entry.FIXED_HSPACE:
						elements.add(ZLTextFixedHSpaceElement.getElement(it.getFixedHSpaceLength()));
						break;
				}
			}
		}

		private static byte[] ourBreaks = new byte[1024];
		private static final int NO_SPACE = 0;
		private static final int SPACE = 1;
		private static final int NON_BREAKABLE_SPACE = 2;
		private void processTextEntry(final char[] data, final int offset, final int length, ZLTextHyperlink hyperlink) {
			if (length != 0) {
				if (ourBreaks.length < length) {
					ourBreaks = new byte[length];
				}
				final byte[] breaks = ourBreaks;
				myLineBreaker.setLineBreaks(data, offset, length, breaks);

				final ZLTextElement hSpace = ZLTextElement.HSpace;
				final ZLTextElement nbSpace = ZLTextElement.NBSpace;
				final ArrayList<ZLTextElement> elements = myElements;
				char ch = 0;
				char previousChar = 0;
				int spaceState = NO_SPACE;
				int wordStart = 0;
				for (int index = 0; index < length; ++index) {
					previousChar = ch;
					ch = data[offset + index];
					// 判断当前的char元素是否是空格
					if (Character.isWhitespace(ch)) {
						if (index > 0 && spaceState == NO_SPACE) {
							addWord(data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
						}
						spaceState = SPACE;
					} else if (Character.isSpaceChar(ch)) {
						if (index > 0 && spaceState == NO_SPACE) {
							addWord(data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
						}
						elements.add(nbSpace);
						if (spaceState != SPACE) {
							spaceState = NON_BREAKABLE_SPACE;
						}
					} else {
						switch (spaceState) {
							// 空格
							case SPACE:
								//if (breaks[index - 1] == LineBreak.NOBREAK || previousChar == '-') {
								//}
								elements.add(hSpace);
								wordStart = index;
								break;
							case NON_BREAKABLE_SPACE:
								wordStart = index;
								break;
							// 正常文本
							case NO_SPACE:
								if (index > 0 &&
										breaks[index - 1] != LineBreaker.NOBREAK &&
										previousChar != '-' &&
										index != wordStart) {
									addWord(data,                                      // char数组的引用
											offset + wordStart,                  // 这个字在char数组中的偏移量
											index - wordStart,                     // 此参数一直为1
											myOffset + wordStart,        // 这个字在该段落中的偏移量
											hyperlink);                                 // 代表超链接信息
									// 将index赋值给wordStart
									// 保证下次循环index - wordStart为1
									wordStart = index;
								}
								break;
						}
						spaceState = NO_SPACE;
					}
				}
				switch (spaceState) {
					case SPACE:
						elements.add(hSpace);
						break;
					case NON_BREAKABLE_SPACE:
						elements.add(nbSpace);
						break;
					case NO_SPACE:
						addWord(data, offset + wordStart, length - wordStart, myOffset + wordStart, hyperlink);
						break;
				}
				myOffset += length;
			}
		}

		private final void addWord(char[] data, int offset, int len, int paragraphOffset, ZLTextHyperlink hyperlink) {
			// 初始化一个ZLTextWord类
			ZLTextWord word = new ZLTextWord(data, offset, len, paragraphOffset);
			for (int i = myFirstMark; i < myLastMark; ++i) {
				final ZLTextMark mark = (ZLTextMark)myMarks.get(i);
				if ((mark.Offset < paragraphOffset + len) && (mark.Offset + mark.Length > paragraphOffset)) {
					word.addMark(mark.Offset - paragraphOffset, mark.Length);
				}
			}
			if (hyperlink != null) {
				hyperlink.addElementIndex(myElements.size());
			}
			// 将新建的ZLTextWord类加入ZLTextParagraphCursor类myElement属性
			myElements.add(word);
		}
	}

}
