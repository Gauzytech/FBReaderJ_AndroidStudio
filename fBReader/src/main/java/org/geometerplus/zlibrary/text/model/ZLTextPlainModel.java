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

package org.geometerplus.zlibrary.text.model;

import org.geometerplus.zlibrary.core.fonts.FontManager;
import org.geometerplus.zlibrary.core.image.ZLImage;
import org.geometerplus.zlibrary.core.util.ZLSearchPattern;
import org.geometerplus.zlibrary.core.util.ZLSearchUtil;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import timber.log.Timber;

/**
 * 通过cpp调用进行创建
 * <p>
 * 一组p标签就代表一个段落(Paragraph)
 */
public final class ZLTextPlainModel implements ZLTextModel, ZLTextStyleEntry.Feature {
	private final String myId;
	private final String myLanguage;

	// 记录了每个段落具体在CachedCharStorage类内部的哪一个char[]里面
	private int[] myStartEntryIndices;
	// 记录了每个段落从CachedCharStorage类内部char[]的哪个位置开始
	private int[] myStartEntryOffsets;
	// 记录每个段落在CachedCharStorage类内部char[]中占据多少长度
	private int[] myParagraphLengths;
	private int[] myTextSizes;
	private byte[] myParagraphKinds;

	private int myParagraphsNumber;

	// 实际存储文本信息与标签信息的地方
	private final CachedCharStorage myStorage;
	// 存文件所有图片的map
	// key: 图片文件名, value: 图片对象
	private final Map<String, ZLImage> myImageMap;

	private ArrayList<ZLTextMark> myMarks = new ArrayList<ZLTextMark>();
	// 保存字体list
	private final FontManager myFontManager;

	/** cpp直接调用constructor */
	public ZLTextPlainModel(
			String id,
			String language,
			int paragraphsNumber,
			int[] entryIndices,
			int[] entryOffsets,
			int[] paragraphLengths,
			int[] textSizes,
			byte[] paragraphKinds,
			String directoryName,
			String fileExtension,
			int blocksNumber,
			Map<String, ZLImage> imageMap,
			FontManager fontManager
	) {
		myId = id;
		myLanguage = language;
		myParagraphsNumber = paragraphsNumber;
		myStartEntryIndices = entryIndices;
		myStartEntryOffsets = entryOffsets;
		myParagraphLengths = paragraphLengths;
		myTextSizes = textSizes;
		myParagraphKinds = paragraphKinds;
		myStorage = new CachedCharStorage(directoryName, fileExtension, blocksNumber);
		myImageMap = imageMap;
		myFontManager = fontManager;


//		for (int i = 0; i < myStartEntryIndices.length; i++) {
//			Timber.v("渲染流程, 初始化, paragraphIdx = %d, ParseFile index = %d", i, myStartEntryIndices[i]);
//		}
	}

	public final String getId() {
		return myId;
	}

	public final String getLanguage() {
		return myLanguage;
	}

	public final ZLTextMark getFirstMark() {
		return (myMarks == null || myMarks.isEmpty()) ? null : myMarks.get(0);
	}

	public final ZLTextMark getLastMark() {
		return (myMarks == null || myMarks.isEmpty()) ? null : myMarks.get(myMarks.size() - 1);
	}

	public final ZLTextMark getNextMark(ZLTextMark position) {
		if (position == null || myMarks == null) {
			return null;
		}

		ZLTextMark mark = null;
		for (ZLTextMark current : myMarks) {
			if (current.compareTo(position) >= 0) {
				if ((mark == null) || (mark.compareTo(current) > 0)) {
					mark = current;
				}
			}
		}
		return mark;
	}

	public final ZLTextMark getPreviousMark(ZLTextMark position) {
		if ((position == null) || (myMarks == null)) {
			return null;
		}

		ZLTextMark mark = null;
		for (ZLTextMark current : myMarks) {
			if (current.compareTo(position) < 0) {
				if ((mark == null) || (mark.compareTo(current) < 0)) {
					mark = current;
				}
			}
		}
		return mark;
	}

	public int search(final String text, int startIndex, int endIndex, boolean ignoreCase) {
		int count = 0;
		ZLSearchPattern pattern = new ZLSearchPattern(text, ignoreCase);
		myMarks = new ArrayList<>();
		if (startIndex > myParagraphsNumber) {
			startIndex = myParagraphsNumber;
		}
		if (endIndex > myParagraphsNumber) {
			endIndex = myParagraphsNumber;
		}
		int index = startIndex;
		final EntryIteratorImpl it = new EntryIteratorImpl(index);
		while (true) {
			int offset = 0;
			while (it.next()) {
				if (it.getType() == ZLTextParagraph.Entry.TEXT) {
					char[] textData = it.getTextData();
					int textOffset = it.getTextOffset();
					int textLength = it.getTextLength();
					for (ZLSearchUtil.Result res = ZLSearchUtil.find(textData, textOffset, textLength, pattern); res != null;
						 res = ZLSearchUtil.find(textData, textOffset, textLength, pattern, res.Start + 1)) {
						myMarks.add(new ZLTextMark(index, offset + res.Start, res.Length));
						++count;
					}
					offset += textLength;
				}
			}
			if (++index >= endIndex) {
				break;
			}
			it.reset(index);
		}
		return count;
	}

	@Override
	public String getImageCacheRootPath() {
		return myStorage.getImageCacheDirectory();
	}

	public final List<ZLTextMark> getMarks() {
		return myMarks != null ? myMarks : Collections.<ZLTextMark>emptyList();
	}

	public final void removeAllMarks() {
		myMarks = null;
	}

	public final int getParagraphsNumber() {
		return myParagraphsNumber;
	}

	/**
	 * 根据index获得对应段落的类型
	 * @param index paragraph index
	 * @return Paragraph placement class
	 */
	public final ZLTextParagraph getParagraph(int index) {
		final byte kind = myParagraphKinds[index];
		return (kind == ZLTextParagraph.Kind.TEXT_PARAGRAPH) ?
				new ZLTextParagraphImpl(this, index) :
				new ZLTextSpecialParagraphImpl(kind, this, index);
	}

	public final int getTextLength(int index) {
		if (myTextSizes.length == 0) {
			return 0;
		}
		return myTextSizes[Math.max(Math.min(index, myParagraphsNumber - 1), 0)];
	}

	private static int binarySearch(int[] array, int length, int value) {
		int lowIndex = 0;
		int highIndex = length - 1;

		while (lowIndex <= highIndex) {
			int midIndex = (lowIndex + highIndex) >>> 1;
			int midValue = array[midIndex];
			if (midValue > value) {
				highIndex = midIndex - 1;
			} else if (midValue < value) {
				lowIndex = midIndex + 1;
			} else {
				return midIndex;
			}
		}
		return -lowIndex - 1;
	}

	public final int findParagraphByTextLength(int length) {
		int index = binarySearch(myTextSizes, myParagraphsNumber, length);
		if (index >= 0) {
			return index;
		}
		return Math.min(-index - 1, myParagraphsNumber - 1);
	}


	/**
	 * 通过paragraphIndex根据myStartEntryIndices取到myPool中char[] 缓存解析文件的idx,
	 * 再通过paragraphIndex根据myStartEntryOffsets获得char[]中数据的idx
	 * 最后获得paragraph对应的数据
	 *
	 * @see #reset(int)
	 */
	final class EntryIteratorImpl implements ZLTextParagraph.EntryIterator {
		private int myCounter;
		private int myLength;
		private byte myType;

		int myDataIndex;
		int myDataOffset;

		// TextEntry data
		private char[] myTextData;
		private int myTextOffset;
		private int myTextLength;

		// ControlEntry data
		private byte myControlKind;
		private boolean myControlIsStart;

		// HyperlinkControlEntry data
		private byte myHyperlinkType;
		private String myHyperlinkId;

		// ImageEntry
		private ZLImageEntry myImageEntry;

		// VideoEntry
		private ZLVideoEntry myVideoEntry;

		// ExtensionEntry
		private ExtensionEntry myExtensionEntry;

		// StyleEntry
		private ZLTextStyleEntry myStyleEntry;

		// FixedHSpaceEntry data
		private short myFixedHSpaceLength;

		EntryIteratorImpl(int paragraphIndex) {
			reset(paragraphIndex);
		}

		void reset(int paragraphIndex) {
			myCounter = 0;
			myLength = myParagraphLengths[paragraphIndex];
			myDataIndex = myStartEntryIndices[paragraphIndex];
			myDataOffset = myStartEntryOffsets[paragraphIndex];
		}

		public byte getType() {
			return myType;
		}

		public char[] getTextData() {
			return myTextData;
		}

		public int getTextOffset() {
			return myTextOffset;
		}

		public int getTextLength() {
			return myTextLength;
		}

		public byte getControlKind() {
			return myControlKind;
		}

		public boolean getControlIsStart() {
			return myControlIsStart;
		}

		public byte getHyperlinkType() {
			return myHyperlinkType;
		}

		public String getHyperlinkId() {
			return myHyperlinkId;
		}

		public ZLImageEntry getImageEntry() {
			return myImageEntry;
		}

		public ZLVideoEntry getVideoEntry() {
			return myVideoEntry;
		}

		public ExtensionEntry getExtensionEntry() {
			return myExtensionEntry;
		}

		public ZLTextStyleEntry getStyleEntry() {
			return myStyleEntry;
		}

		public short getFixedHSpaceLength() {
			return myFixedHSpaceLength;
		}

		public boolean next() {
			if (myCounter >= myLength) {
				return false;
			}

			int dataOffset = myDataOffset;
			// 获取对应需要显示段落的char[]
			char[] parseFileData = myStorage.block(myDataIndex);
			if (parseFileData == null) {
				return false;
			}
			// 如果char[] data 内容读完了，自动获取下一个char数组内容
			// 这个char[] 就是cpp allocate()中myPool[]中的row[], myLastEntryStart作为pointer永远指向row[]的末端可写入的idx
			if (dataOffset >= parseFileData.length) {
				// ++myDataIndex返回+1后的值
				parseFileData = myStorage.block(++myDataIndex);
				if (parseFileData == null) {
					return false;
				}
				dataOffset = 0;
			}
			// 依靠dataOffset递增，不断读取char数组内容
			short first = (short) parseFileData[dataOffset];
			byte type = (byte) first;
			// type == 0 是空行？？？所以直接读取下一个char[]
			if (type == 0) {
				parseFileData = myStorage.block(++myDataIndex);
				if (parseFileData == null) {
					return false;
				}
				dataOffset = 0;
				first = (short) parseFileData[0];
				type = (byte) first;
			}
			myType = type;
			++dataOffset;
			switch (type) {
				// 遇到常量(ZLTextParagraph.Entry.TEXT)时, 就按照文本信息处理
				case ZLTextParagraph.Entry.TEXT: {
					// 记录文本信息的长度
					int textLength = (int) parseFileData[dataOffset++];
					textLength += (((int) parseFileData[dataOffset++]) << 16);
					textLength = Math.min(textLength, parseFileData.length - dataOffset);
					myTextLength = textLength;
					// 存数当前char[]的引用
					myTextData = parseFileData;
					myTextOffset = dataOffset;
					// 向前跳过char[]中涉及这段文本信息的部分
					dataOffset += textLength;
					break;
				}
				// 遇到常量(ZLTextParagraph.Entry.CONTROL)时, 就按照标签信息处理
				case ZLTextParagraph.Entry.CONTROL: {
					short kind = (short) parseFileData[dataOffset++];
					myControlKind = (byte) kind;
					// 标记: 开始标签还是结束标签
					myControlIsStart = (kind & 0x0100) == 0x0100;
					myHyperlinkType = 0;
					break;
				}
				case ZLTextParagraph.Entry.HYPERLINK_CONTROL: {
					final short kind = (short) parseFileData[dataOffset++];
					myControlKind = (byte) kind;
					myControlIsStart = true;
					myHyperlinkType = (byte) (kind >> 8);
					final short labelLength = (short) parseFileData[dataOffset++];
					myHyperlinkId = new String(parseFileData, dataOffset, labelLength);
					dataOffset += labelLength;
					break;
				}
				case ZLTextParagraph.Entry.IMAGE: {
					final short vOffset = (short) parseFileData[dataOffset++];
					final short len = (short) parseFileData[dataOffset++];
					final String id = new String(parseFileData, dataOffset, len);
					dataOffset += len;
					final boolean isCover = parseFileData[dataOffset++] != 0;
					myImageEntry = new ZLImageEntry(myImageMap, id, vOffset, isCover);
					break;
				}
				case ZLTextParagraph.Entry.FIXED_HSPACE:
					myFixedHSpaceLength = (short) parseFileData[dataOffset++];
					break;
				case ZLTextParagraph.Entry.STYLE_CSS:
				case ZLTextParagraph.Entry.STYLE_OTHER: {
					final short depth = (short) ((first >> 8) & 0xFF);
					final ZLTextStyleEntry entry =
							type == ZLTextParagraph.Entry.STYLE_CSS
									? new ZLTextCSSStyleEntry(depth)
									: new ZLTextOtherStyleEntry();

					final short mask = (short) parseFileData[dataOffset++];
					for (int i = 0; i < NUMBER_OF_LENGTHS; ++i) {
						if (ZLTextStyleEntry.isFeatureSupported(mask, i)) {
							final short size = (short) parseFileData[dataOffset++];
							final byte unit = (byte) parseFileData[dataOffset++];
							entry.setLength(i, size, unit);
						}
					}
					if (ZLTextStyleEntry.isFeatureSupported(mask, ALIGNMENT_TYPE) ||
							ZLTextStyleEntry.isFeatureSupported(mask, NON_LENGTH_VERTICAL_ALIGN)) {
						final short value = (short) parseFileData[dataOffset++];
						if (ZLTextStyleEntry.isFeatureSupported(mask, ALIGNMENT_TYPE)) {
							entry.setAlignmentType((byte)(value & 0xFF));
						}
						if (ZLTextStyleEntry.isFeatureSupported(mask, NON_LENGTH_VERTICAL_ALIGN)) {
							entry.setVerticalAlignCode((byte)((value >> 8) & 0xFF));
						}
					}
					if (ZLTextStyleEntry.isFeatureSupported(mask, FONT_FAMILY)) {
						entry.setFontFamilies(myFontManager, (short)parseFileData[dataOffset++]);
					}
					if (ZLTextStyleEntry.isFeatureSupported(mask, FONT_STYLE_MODIFIER)) {
						final short value = (short)parseFileData[dataOffset++];
						entry.setFontModifiers((byte)(value & 0xFF), (byte)((value >> 8) & 0xFF));
					}

					myStyleEntry = entry;
				}
				case ZLTextParagraph.Entry.STYLE_CLOSE:
					// No data
					break;
				case ZLTextParagraph.Entry.RESET_BIDI:
					// No data
					break;
				case ZLTextParagraph.Entry.AUDIO:
					// No data
					break;
				case ZLTextParagraph.Entry.VIDEO: {
					myVideoEntry = new ZLVideoEntry();
					final short mapSize = (short) parseFileData[dataOffset++];
					for (short i = 0; i < mapSize; ++i) {
						short len = (short) parseFileData[dataOffset++];
						final String mime = new String(parseFileData, dataOffset, len);
						dataOffset += len;
						len = (short) parseFileData[dataOffset++];
						final String src = new String(parseFileData, dataOffset, len);
						dataOffset += len;
						myVideoEntry.addSource(mime, src);
					}
					break;
				}
				case ZLTextParagraph.Entry.EXTENSION: {
					final short kindLength = (short) parseFileData[dataOffset++];
					final String kind = new String(parseFileData, dataOffset, kindLength);
					dataOffset += kindLength;

					final Map<String, String> map = new HashMap<String, String>();
					final short dataSize = (short) ((first >> 8) & 0xFF);
					for (short i = 0; i < dataSize; ++i) {
						final short keyLength = (short) parseFileData[dataOffset++];
						final String key = new String(parseFileData, dataOffset, keyLength);
						dataOffset += keyLength;
						final short valueLength = (short) parseFileData[dataOffset++];
						map.put(key, new String(parseFileData, dataOffset, valueLength));
						dataOffset += valueLength;
					}
					myExtensionEntry = new ExtensionEntry(kind, map);
					break;
				}
			}
			++myCounter;
			myDataOffset = dataOffset;
			return true;
		}
	}

}
