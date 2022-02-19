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
 * 本地缓存解析文件类, 包含一个paragraph的解析信息
 * <p>
 * 通过{@link #getParagraph()}获得paragraph的解析信息, 利用Iterator将paragraph读取每个entry然后加到myElements
 *
 * @see Processor
 * @see ZLTextPlainModel.EntryIteratorImpl
 */
public final class ZLTextParagraphCursor {
	public final static String DRM = "drm";
	public final static String ENCRYPTED_SECTION = "encryptedSection";

	// index是paragraphIndex, 1个或多个paragraphIndex对应1个cpp myPool中char[] row的idx
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

		Timber.v("渲染流程, CursorManager index = %d, finalIdx = %d", paragraphIndex, this.paragraphIdx);

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
				Timber.v("渲染流程, End ---------------------------------------------------------------------------------------");
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
				Processor processor = new Processor(paragraph, cursorManager.extensionManager, lineBreaker, marks, paragraphIdx);
				processor.fillElements(myElements);
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

	ZLTextElement getElement(int index) {
		try {
			return myElements.get(index);
		} catch (IndexOutOfBoundsException e) {
			return null;
		}
	}

	ZLTextParagraph getParagraph() {
		return textModel.getParagraph(paragraphIdx);
	}

	@NonNull
	@Override
	public String toString() {
		return "ZLTextParagraphCursor [" + paragraphIdx + " (0.." + myElements.size() + ")]";
	}

	private static final class Processor {
		private final ZLTextParagraph myParagraph;
		private final ExtensionElementManager myExtManager;
		private final LineBreaker myLineBreaker;
		private int myOffset;
		private int myFirstMark;
		private int myLastMark;
		private final List<ZLTextMark> myMarks;

		/**
		 * myElement填充类
		 * <p>
		 * 将char[]中代表当前段落的部分转换成一个元素为ZLTextElement类的ArrayList的工作
		 *
		 * @param paragraph      段落处理工具类, 代表一对p标签对应的paragraph. 利用工具类中的方法操作textModel中段落数据
		 * @param extManager     FbView中的bookElementManager, 用来加载一些图书信息: OPDS
		 * @param lineBreaker    分行cpp工具类
		 * @param marks          textModel中mark类, 这是干啥的????
		 * @param paragraphIndex 段落号
		 */
		private Processor(ZLTextParagraph paragraph, ExtensionElementManager extManager, LineBreaker lineBreaker, List<ZLTextMark> marks, int paragraphIndex) {
			this.myParagraph = paragraph;
			this.myExtManager = extManager;
			this.myLineBreaker = lineBreaker;
			this.myMarks = marks;
			// 定位mark操作
			// 在addWord()中会被用到
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
		 * 一组p标签就代表一个Paragraph
		 */
		public void fillElements(List<ZLTextElement> myElements) {
			int hyperlinkDepth = 0;
			ZLTextHyperlink hyperlink = null;

			// reference传递
//			final List<ZLTextElement> elements = myElements;
			// 这里会最终调用EntryIteratorImpl类的构造函数
			// kind: 见FBTextKind
			for (ZLTextParagraph.EntryIterator it = myParagraph.iterator(); it.next(); ) {
				switch (it.getType()) {
					// 对于文本信息
					// 1. 先在iterator.next()对ZLTextParagraph.Entry.TEXT的处理:
					// 	1.1 记录文本信息的长度: textLength
					// 	1.2 将读取到的本地持久化char[]存到myTextData
					// 	1.3 存当前读取的dataOffset
					// 	1.4 更新dataOffset += textLength
					// 2. 调用Processor类的processTextEntry方法
					// 	2.1 将ZLTextWord类加入ZLTextParagraphCursor.myElements
					case ZLTextParagraph.Entry.TEXT:
						processTextEntry(myElements, it.getTextData(), it.getTextOffset(), it.getTextLength(), hyperlink);
						break;
					// 对于标签信息
					// 1. 先在iterator.next()对ZLTextParagraph.Entry.CONTROL的处理:
					//  1.1 判断标签kind
					//  1.2 通过kind判断是开始标签/结束标签
					//  1.3 初始化超链接type
					// 2. 则直接将ZLTextControlElement类加入ZLTextParagraphCursor.myElements
					case ZLTextParagraph.Entry.CONTROL:
						// 超链接嵌套
						if (hyperlink != null) {
							hyperlinkDepth += it.getControlIsStart() ? 1 : -1;
							if (hyperlinkDepth == 0) {
								hyperlink = null;
							}
						}
						//
						myElements.add(ZLTextControlElement.get(
								it.getControlKind(),           // 获取myControlKind属性, 代表标签种类
								it.getControlIsStart())        // 获取myControlStart属性, 代表是标签对的开始/结束标签
						);
						break;
					case ZLTextParagraph.Entry.HYPERLINK_CONTROL: {
						final byte hyperlinkType = it.getHyperlinkType();
						if (hyperlinkType != 0) {
							final ZLTextHyperlinkControlElement control = new ZLTextHyperlinkControlElement(
									it.getControlKind(),
									hyperlinkType,
									it.getHyperlinkId()
							);
							myElements.add(control);
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
									hyperlink.addElementIndex(myElements.size());
								}
								myElements.add(new ZLTextImageElement(imageEntry.Id, data, image.getURI(), imageEntry.IsCover));
							}
						}
						break;
					case ZLTextParagraph.Entry.AUDIO:
						break;
					case ZLTextParagraph.Entry.VIDEO:
						myElements.add(new ZLTextVideoElement(it.getVideoEntry().sources()));
						break;
					case ZLTextParagraph.Entry.EXTENSION:
						if (myExtManager != null) {
							myElements.addAll(myExtManager.getElements(it.getExtensionEntry()));
						}
						break;
					case ZLTextParagraph.Entry.STYLE_CSS:
					case ZLTextParagraph.Entry.STYLE_OTHER:
						myElements.add(new ZLTextStyleElement(it.getStyleEntry()));
						break;
					case ZLTextParagraph.Entry.STYLE_CLOSE:
						myElements.add(ZLTextElement.StyleClose);
						break;
					case ZLTextParagraph.Entry.FIXED_HSPACE:
						myElements.add(ZLTextFixedHSpaceElement.getElement(it.getFixedHSpaceLength()));
						break;
				}
			}
		}

		private static byte[] ourBreaks = new byte[1024];
		private static final int NO_SPACE = 0;
		private static final int SPACE = 1;
		private static final int NON_BREAKABLE_SPACE = 2;

		private void processTextEntry(List<ZLTextElement> myElements, final char[] data, final int offset, final int length, ZLTextHyperlink hyperlink) {
			if (length != 0) {
				if (ourBreaks.length < length) {
					ourBreaks = new byte[length];
				}
				final byte[] breaks = ourBreaks;
				myLineBreaker.setLineBreaks(data, offset, length, breaks);

//				final ArrayList<ZLTextElement> elements = myElements;
				char ch = 0;
				char previousChar;
				int spaceState = NO_SPACE;
				int wordStart = 0;
				// 使用for循环一个一个读取char数组中的元素，然后对每个元素调用Processor类的addWord方法
				for (int index = 0; index < length; ++index) {
					previousChar = ch;
					ch = data[offset + index];
					// 判断当前的char元素是否是空格
					if (Character.isWhitespace(ch)) {
						// 正常space
						if (index > 0 && spaceState == NO_SPACE) {
							ZLTextWord word = addWord(myElements.size(), data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
							myElements.add(word);
						}
						spaceState = SPACE;
					} else if (Character.isSpaceChar(ch)) {
						// NON_BREAKABLE_SPACE
						if (index > 0 && spaceState == NO_SPACE) {
							ZLTextWord word = addWord(myElements.size(), data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
							myElements.add(word);
						}
						myElements.add(ZLTextElement.NBSpace);
						// 正常space > NON_BREAKABLE_SPACE, 如果两种space连在一起, 继续当做正常space
						if (spaceState != SPACE) {
							spaceState = NON_BREAKABLE_SPACE;
						}
					} else {
						switch (spaceState) {
							// 空格, 正常space: SPACE
							case SPACE:
								//if (breaks[index - 1] == LineBreak.NOBREAK || previousChar == '-') {
								//}
								myElements.add(ZLTextElement.HSpace);
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
									ZLTextWord word = addWord(myElements.size(),
											data,                                      // char数组的引用
											offset + wordStart,                  // 这个字在char[]中的偏移量
											index - wordStart,                     // 此参数一直为1
											myOffset + wordStart,        // 这个字在该段落中的偏移量
											hyperlink);                                 // 代表超链接信息
									myElements.add(word);
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
						myElements.add(ZLTextElement.HSpace);
						break;
					case NON_BREAKABLE_SPACE:
						myElements.add(ZLTextElement.NBSpace);
						break;
					case NO_SPACE:
						ZLTextWord word = addWord(myElements.size(), data, offset + wordStart, length - wordStart, myOffset + wordStart, hyperlink);
						myElements.add(word);
						break;
				}
				myOffset += length;
			}
		}

		private ZLTextWord addWord(int elementIdx, char[] data, int offset, int len, int paragraphOffset, ZLTextHyperlink hyperlink) {
			// 初始化一个ZLTextWord类
			ZLTextWord word = new ZLTextWord(data, offset, len, paragraphOffset);
			for (int i = myFirstMark; i < myLastMark; ++i) {
				final ZLTextMark mark = (ZLTextMark) myMarks.get(i);
				if ((mark.Offset < paragraphOffset + len) && (mark.Offset + mark.Length > paragraphOffset)) {
					word.addMark(mark.Offset - paragraphOffset, mark.Length);
				}
			}
			if (hyperlink != null) {
//				hyperlink.addElementIndex(myElements.size());
				hyperlink.addElementIndex(elementIdx);
			}
			// 将新建的ZLTextWord类加入ZLTextParagraphCursor类myElement属性
//			myElements.add(word);
			return word;
		}
	}

}
