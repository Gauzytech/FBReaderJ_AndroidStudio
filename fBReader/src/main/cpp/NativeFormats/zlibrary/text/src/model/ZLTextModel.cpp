/*
 * Copyright (C) 2004-2015 FBReader.ORG Limited <contact@fbreader.org>
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

#include <cstdint>
#include <cstring>
#include <algorithm>

#include <ZLibrary.h>
//#include <ZLSearchUtil.h>
//#include <ZLLanguageUtil.h>
#include <ZLUnicodeUtil.h>
//#include <ZLStringUtil.h>
//#include <ZLLogger.h>
#include <FontManager.h>

#include "ZLTextModel.h"
#include "ZLTextParagraph.h"
#include "ZLTextStyleEntry.h"
#include "ZLVideoEntry.h"

#include <LogUtil.h>

ZLTextModel::ZLTextModel(const std::string &id, const std::string &language, const std::size_t rowSize,
		const std::string &directoryName, const std::string &fileExtension, FontManager &fontManager) :
	myId(id),
	myLanguage(language.empty() ? ZLibrary::Language() : language),
	// 初始化缓存解析文件工具类
	myAllocator(new ZLCachedMemoryAllocator(rowSize, directoryName, fileExtension)),
	myLastEntryStart(nullptr),
	myFontManager(fontManager) {
    LogUtil::print("创建ZLTextModel constructor1, rowSize = %s", std::to_string(rowSize));

    // 新实现
    // 清空字符串, empty string, length = 0
	currentFile.clear();
}

ZLTextModel::ZLTextModel(const std::string &id, const std::string &language, shared_ptr<ZLCachedMemoryAllocator> allocator, FontManager &fontManager) :
	myId(id),
	myLanguage(language.empty() ? ZLibrary::Language() : language),
	myAllocator(allocator),
	myLastEntryStart(nullptr),
	myFontManager(fontManager) {
    LogUtil::print("创建ZLTextModel constructor2, ext = %s", allocator->fileExtension());

	// 新实现
	// 清空字符串, empty string, length = 0
    currentFile.clear();
}

ZLTextModel::~ZLTextModel() {
	for (std::vector<ZLTextParagraph*>::const_iterator it = myParagraphs.begin(); it != myParagraphs.end(); ++it) {
		delete *it;
	}
}

/*
bool ZLTextModel::isRtl() const {
	return ZLLanguageUtil::isRTLLanguage(myLanguage);
}

void ZLTextModel::search(const std::string &text, std::size_t startIndex, std::size_t endIndex, bool ignoreCase) const {
	ZLSearchPattern pattern(text, ignoreCase);
	myMarks.clear();

	std::vector<ZLTextParagraph*>::const_iterator start =
		(startIndex < myParagraphs.size()) ? myParagraphs.begin() + startIndex : myParagraphs.end();
	std::vector<ZLTextParagraph*>::const_iterator end =
		(endIndex < myParagraphs.size()) ? myParagraphs.begin() + endIndex : myParagraphs.end();
	for (std::vector<ZLTextParagraph*>::const_iterator it = start; it < end; ++it) {
		int offset = 0;
		for (ZLTextParagraph::Iterator jt = **it; !jt.isEnd(); jt.next()) {
			if (jt.entryKind() == ZLTextParagraphEntry::TEXT_ENTRY) {
				const ZLTextEntry& textEntry = (ZLTextEntry&)*jt.entry();
				const char *str = textEntry.data();
				const std::size_t len = textEntry.dataLength();
				for (int pos = ZLSearchUtil::find(str, len, pattern); pos != -1; pos = ZLSearchUtil::find(str, len, pattern, pos + 1)) {
					myMarks.push_back(ZLTextMark(it - myParagraphs.begin(), offset + pos, pattern.length()));
				}
				offset += len;
			}
		}
	}
}

void ZLTextModel::selectParagraph(std::size_t index) const {
	if (index < paragraphsNumber()) {
		myMarks.push_back(ZLTextMark(index, 0, (*this)[index]->textDataLength()));
	}
}

ZLTextMark ZLTextModel::firstMark() const {
	return marks().empty() ? ZLTextMark() : marks().front();
}

ZLTextMark ZLTextModel::lastMark() const {
	return marks().empty() ? ZLTextMark() : marks().back();
}

ZLTextMark ZLTextModel::nextMark(ZLTextMark position) const {
	std::vector<ZLTextMark>::const_iterator it = std::upper_bound(marks().begin(), marks().end(), position);
	return (it != marks().end()) ? *it : ZLTextMark();
}

ZLTextMark ZLTextModel::previousMark(ZLTextMark position) const {
	if (marks().empty()) {
		return ZLTextMark();
	}
	std::vector<ZLTextMark>::const_iterator it = std::lower_bound(marks().begin(), marks().end(), position);
	if (it == marks().end()) {
		--it;
	}
	if (*it >= position) {
		if (it == marks().begin()) {
			return ZLTextMark();
		}
		--it;
	}
	return *it;
}
*/

/**
 * 更新了ZLTextModel类中的三个属性: myStartEntryIndices, myStartEntryOffsets, myParagraphLengths，
 * 以后会依靠这三个属性在CachedCharStorage类的char数组中快速定位某一个段落
 *
 * @param paragraph 段落处理工具类, 代表一对p标签对应的paragraph. 利用工具类中的方法操作textModel中段落数据, JAVA中也有这个类
 */
void ZLTextModel::addParagraphInternal(ZLTextParagraph *paragraph) {
	// myPool size
	const std::size_t dataSize = myAllocator->blocksNumber();
	// myOffset
	const std::size_t bytesOffset = myAllocator->currentBytesOffset();

	// 记录当前段落在CachedCharStorage类中具体哪一个char[]里面
	myStartEntryIndices.push_back((dataSize == 0) ? 0 : (dataSize - 1));
	// 记录当前段落从CachedCharStorage类内部char[]的哪个位置开始
	myStartEntryOffsets.push_back(bytesOffset / 2); // offset in words for future use in Java
	// 记录每个段落在CachedCharStorage类内部char[]占据了多少长度
	myParagraphLengths.push_back(0);
	myTextSizes.push_back(myTextSizes.empty() ? 0 : myTextSizes.back());
	myParagraphKinds.push_back(paragraph->kind());

	myParagraphs.push_back(paragraph);
	myLastEntryStart = nullptr;
}

ZLTextPlainModel::ZLTextPlainModel(const std::string &id, const std::string &language, const std::size_t rowSize,
		const std::string &directoryName, const std::string &fileExtension, FontManager &fontManager) :
	ZLTextModel(id, language, rowSize, directoryName, fileExtension, fontManager) {
}

ZLTextPlainModel::ZLTextPlainModel(const std::string &id, const std::string &language, shared_ptr<ZLCachedMemoryAllocator> allocator, FontManager &fontManager) :
	ZLTextModel(id, language, allocator, fontManager) {
}

void ZLTextPlainModel::createParagraph(ZLTextParagraph::Kind kind) {
	ZLTextParagraph *paragraph = (kind == ZLTextParagraph::TEXT_PARAGRAPH) ? new ZLTextParagraph() : new ZLTextSpecialParagraph(kind);
	addParagraphInternal(paragraph);

	// 新实现
    addParagraphInternalBeta(paragraph);
}

void ZLTextModel::addText(const std::string &text) {
	LogUtil::print("解析缓存流程", "addText 单个text = %s", text);
	ZLUnicodeUtil::Ucs2String ucs2str;
	ZLUnicodeUtil::utf8ToUcs2(ucs2str, text);
	const std::size_t len = ucs2str.size();

	if (myLastEntryStart != nullptr && *myLastEntryStart == ZLTextParagraphEntry::TEXT_ENTRY) {
		const std::size_t oldLen = ZLCachedMemoryAllocator::readUInt32(myLastEntryStart + 2);
		const std::size_t newLen = oldLen + len;
        // 获得myPool末端char[]可写入ptr的地址
        myLastEntryStart = myAllocator->reallocateLast(currentFile, myLastEntryStart, 2 * newLen + 6, "addText");
        // 准备myPool末端char[]可写入ptr的地址
        ZLCachedMemoryAllocator::writeUInt32(myLastEntryStart + 2, newLen);
        // 最后将xhtml文件的text从ptr开始拷贝到char[]中
        std::memcpy(myLastEntryStart + 6 + oldLen, &ucs2str.front(), 2 * newLen);
	} else {
		// myLastEntryStart: 记录当前paragraph char[]中最后一个char的idx位置
		// paragraph char[]就是ZLCachedMemoryAllocator.myPool
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStart = myAllocator->allocate(currentFile, 2 * len + 6, "addText");
		// 准备myPool末端char[]可写入ptr的地址
		*myLastEntryStart = ZLTextParagraphEntry::TEXT_ENTRY;
		*(myLastEntryStart + 1) = 0;
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStart + 2, len);
		// 最后将xhtml文件的text从ptr开始拷贝到char[]中
		std::memcpy(myLastEntryStart + 6, &ucs2str.front(), 2 * len);
		// 将处理完的ptr存到myParagraphs中, 从这个ptr开始就能读到添加的text
		myParagraphs.back()->addEntry(myLastEntryStart);
		// 因为加了一个ptr, 所以myParagraphLengths也要增加
		++myParagraphLengths.back();
	}
	myTextSizes.back() += len;
}

/**
 * ZLXMLParser类的processEndTag方法 -> XHTMLReader类的endElementHandler方法
 * -> XHTMLTagParagraphWithControlAction类的doAtEnd方法 -> addText
 *
 * @param text
 */
void ZLTextModel::addText(const std::vector<std::string> &text) {
	if (text.empty()) {
		return;
	}
	std::size_t fullLength = 0;
	// 遍历text vector计算长度
	for (const auto & it : text) {
		fullLength += ZLUnicodeUtil::utf8Length(it);
	}
	ZLUnicodeUtil::Ucs2String ucs2str;
	// myAllocator中myPool末端char[]没有填满的情况
	if (myLastEntryStart != nullptr && *myLastEntryStart == ZLTextParagraphEntry::TEXT_ENTRY) {
		const std::size_t oldLen = ZLCachedMemoryAllocator::readUInt32(myLastEntryStart + 2);
		const std::size_t newLen = oldLen + fullLength;
		// myLastEntryStart: 记录当前paragraph char[]中最后一个char的idx位置
		// paragraph char[]就是ZLCachedMemoryAllocator.myPool
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStart = myAllocator->reallocateLast(currentFile, myLastEntryStart, 2 * newLen + 6, "addText");
		// 准备myPool末端char[]可写入ptr的地址
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStart + 2, newLen);
		std::size_t offset = 6 + oldLen;
		// 遍历文字text
		for (const auto & it : text) {
			ZLUnicodeUtil::utf8ToUcs2(ucs2str, it);
			const std::size_t len = 2 * ucs2str.size();
			// 最后将xhtml文件的text从ptr开始拷贝到char[]中
			std::memcpy(myLastEntryStart + offset, &ucs2str.front(), len);
			offset += len;
			ucs2str.clear();
		}
	} else {
		// myAllocator中myPool末端char[]满了的情况
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStart = myAllocator->allocate(currentFile, 2 * fullLength + 6, "addText");
		// 准备myPool末端char[]可写入ptr的地址
		*myLastEntryStart = ZLTextParagraphEntry::TEXT_ENTRY;
		*(myLastEntryStart + 1) = 0;
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStart + 2, fullLength);
		std::size_t offset = 6;
		// 遍历文字text
		for (const auto & it : text) {
			ZLUnicodeUtil::utf8ToUcs2(ucs2str, it);
			const std::size_t len = 2 * ucs2str.size();
			// 最后将xhtml文件的text从ptr开始拷贝到char[]中
			std::memcpy(myLastEntryStart + offset, &ucs2str.front(), len);
			offset += len;
			ucs2str.clear();
        }
		myParagraphs.back()->addEntry(myLastEntryStart);
		++myParagraphLengths.back();
	}
	myTextSizes.back() += fullLength;
}

void ZLTextModel::addFixedHSpace(unsigned char length) {
	LogUtil::print("解析缓存流程", "addFixedHSpace", "");
	myLastEntryStart = myAllocator->allocate(currentFile, 4, "addFixedHSpace");
	*myLastEntryStart = ZLTextParagraphEntry::FIXED_HSPACE_ENTRY;
	*(myLastEntryStart + 1) = 0;
	*(myLastEntryStart + 2) = length;
	*(myLastEntryStart + 3) = 0;
	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addControl(ZLTextKind textKind, bool isStart) {
	LogUtil::print("解析缓存流程", "addControl", "");
	// 初始化size = 4 的char[]
	myLastEntryStart = myAllocator->allocate(currentFile, 4, "addControl");
	*myLastEntryStart = ZLTextParagraphEntry::CONTROL_ENTRY; // idx = 0, entry kind
	*(myLastEntryStart + 1) = 0; 							 // idx = 1,
	*(myLastEntryStart + 2) = textKind;						 // idx = 2, text kind
	*(myLastEntryStart + 3) = isStart ? 1 : 0;				 // idx = 3, 是否为起始标签
	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

//static int EntryCount = 0;
//static int EntryLen = 0;

void ZLTextModel::addStyleEntry(const ZLTextStyleEntry &entry, unsigned char depth) {
	LogUtil::print("解析缓存流程", "addStyleEntry1", "");
	addStyleEntry(entry, entry.fontFamilies(), depth);
	// 新实现
	addStyleEntryBeta(entry, entry.fontFamilies(), depth);
}

void ZLTextModel::addStyleEntry(const ZLTextStyleEntry &entry, const std::vector<std::string> &fontFamilies, unsigned char depth) {
	LogUtil::print("解析缓存流程", "addStyleEntry2", "");
	// +++ calculating entry size
	std::size_t len = 4; // entry type + feature mask
	for (int i = 0; i < ZLTextStyleEntry::NUMBER_OF_LENGTHS; ++i) {
		if (entry.isFeatureSupported((ZLTextStyleEntry::Feature)i)) {
			len += 4; // each supported length
		}
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::ALIGNMENT_TYPE) ||
			entry.isFeatureSupported(ZLTextStyleEntry::NON_LENGTH_VERTICAL_ALIGN)) {
		len += 2;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_FAMILY)) {
		len += 2;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_STYLE_MODIFIER)) {
		len += 2;
	}
	// --- calculating entry size

/*
	EntryCount += 1;
	EntryLen += len;
	std::string debug = "style entry counter: ";
	ZLStringUtil::appendNumber(debug, EntryCount);
	debug += "/";
	ZLStringUtil::appendNumber(debug, EntryLen);
	ZLLogger::Instance().println(ZLLogger::DEFAULT_CLASS, debug);
*/

	// +++ writing entry
	myLastEntryStart = myAllocator->allocate(currentFile, len, "addStyleEntry");
	char *address = myLastEntryStart;

	*address++ = entry.entryKind();
	*address++ = depth;
	address = ZLCachedMemoryAllocator::writeUInt16(address, entry.myFeatureMask);

	for (int i = 0; i < ZLTextStyleEntry::NUMBER_OF_LENGTHS; ++i) {
		if (entry.isFeatureSupported((ZLTextStyleEntry::Feature)i)) {
			const ZLTextStyleEntry::LengthType &length = entry.myLengths[i];
			address = ZLCachedMemoryAllocator::writeUInt16(address, length.Size);
			*address++ = length.Unit;
			*address++ = 0;
		}
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::ALIGNMENT_TYPE) ||
			entry.isFeatureSupported(ZLTextStyleEntry::NON_LENGTH_VERTICAL_ALIGN)) {
		*address++ = entry.myAlignmentType;
		*address++ = entry.myVerticalAlignCode;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_FAMILY)) {
		address = ZLCachedMemoryAllocator::writeUInt16(address, myFontManager.familyListIndex(fontFamilies));
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_STYLE_MODIFIER)) {
		*address++ = entry.mySupportedFontModifier;
		*address++ = entry.myFontModifier;
	}
	// --- writing entry

	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addStyleCloseEntry() {
	LogUtil::print("解析缓存流程", "addStyleCloseEntry", "");
	myLastEntryStart = myAllocator->allocate(currentFile, 2, "addStyleCloseEntry");
	char *address = myLastEntryStart;

	*address++ = ZLTextParagraphEntry::STYLE_CLOSE_ENTRY;
	*address++ = 0;

	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addHyperlinkControl(ZLTextKind textKind, ZLHyperlinkType hyperlinkType, const std::string &label) {
	LogUtil::print("解析缓存流程", "addHyperlinkControl", "");
	ZLUnicodeUtil::Ucs2String ucs2label;
	ZLUnicodeUtil::utf8ToUcs2(ucs2label, label);

	const std::size_t len = ucs2label.size() * 2;

	myLastEntryStart = myAllocator->allocate(currentFile, len + 6, "addHyperlinkControl");
	*myLastEntryStart = ZLTextParagraphEntry::HYPERLINK_CONTROL_ENTRY;
	*(myLastEntryStart + 1) = 0;
	*(myLastEntryStart + 2) = textKind;
	*(myLastEntryStart + 3) = hyperlinkType;
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStart + 4, ucs2label.size());
	std::memcpy(myLastEntryStart + 6, &ucs2label.front(), len);
	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addImage(const std::string &id, short vOffset, bool isCover) {
	LogUtil::print("解析缓存流程", "addImage", "");
	ZLUnicodeUtil::Ucs2String ucs2id;
	ZLUnicodeUtil::utf8ToUcs2(ucs2id, id);

	const std::size_t len = ucs2id.size() * 2;

	myLastEntryStart = myAllocator->allocate(currentFile, len + 8, "addImage");
	*myLastEntryStart = ZLTextParagraphEntry::IMAGE_ENTRY;
	*(myLastEntryStart + 1) = 0;
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStart + 2, vOffset);
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStart + 4, ucs2id.size());
	std::memcpy(myLastEntryStart + 6, &ucs2id.front(), len);
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStart + 6 + len, isCover ? 1 : 0);
	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addBidiReset() {
	myLastEntryStart = myAllocator->allocate(currentFile, 2, "addBidiReset");
	*myLastEntryStart = ZLTextParagraphEntry::RESET_BIDI_ENTRY;
	*(myLastEntryStart + 1) = 0;
	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addVideoEntry(const ZLVideoEntry &entry) {
	LogUtil::print("解析缓存流程", "addVideoEntry", "");
	const std::map<std::string,std::string> &sources = entry.sources();

	std::size_t len = 4;
	for (std::map<std::string,std::string>::const_iterator it = sources.begin(); it != sources.end(); ++it) {
		len += 2 * (ZLUnicodeUtil::utf8Length(it->first) + ZLUnicodeUtil::utf8Length(it->second)) + 4;
	}

	myLastEntryStart = myAllocator->allocate(currentFile, len, "addVideoEntry");
	*myLastEntryStart = ZLTextParagraphEntry::VIDEO_ENTRY;
	*(myLastEntryStart + 1) = 0;
	char *p = ZLCachedMemoryAllocator::writeUInt16(myLastEntryStart + 2, sources.size());
	for (std::map<std::string,std::string>::const_iterator it = sources.begin(); it != sources.end(); ++it) {
		ZLUnicodeUtil::Ucs2String first;
		ZLUnicodeUtil::utf8ToUcs2(first, it->first);
		p = ZLCachedMemoryAllocator::writeString(p, first);
		ZLUnicodeUtil::Ucs2String second;
		ZLUnicodeUtil::utf8ToUcs2(second, it->second);
		p = ZLCachedMemoryAllocator::writeString(p, second);
	}

	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::addExtensionEntry(const std::string &action, const std::map<std::string,std::string> &data) {
	LogUtil::print("解析缓存流程", "addExtensionEntry", "");
	std::size_t fullLength = 2;                                      // entry type + map size
	fullLength += 2 + ZLUnicodeUtil::utf8Length(action) * 2;         // action name
	for (std::map<std::string,std::string>::const_iterator it = data.begin(); it != data.end(); ++it) {
		fullLength += 2 + ZLUnicodeUtil::utf8Length(it->first) * 2;    // data key
		fullLength += 2 + ZLUnicodeUtil::utf8Length(it->second) * 2;   // data value
	}

	myLastEntryStart = myAllocator->allocate(currentFile, fullLength, "addExtensionEntry");
	*myLastEntryStart = ZLTextParagraphEntry::EXTENSION_ENTRY;
	*(myLastEntryStart + 1) = data.size();

	char *p = myLastEntryStart + 2;
	ZLUnicodeUtil::Ucs2String ucs2action;
	ZLUnicodeUtil::utf8ToUcs2(ucs2action, action);
	p = ZLCachedMemoryAllocator::writeString(p, ucs2action);

	for (std::map<std::string,std::string>::const_iterator it = data.begin(); it != data.end(); ++it) {
		ZLUnicodeUtil::Ucs2String key;
		ZLUnicodeUtil::utf8ToUcs2(key, it->first);
		p = ZLCachedMemoryAllocator::writeString(p, key);
		ZLUnicodeUtil::Ucs2String value;
		ZLUnicodeUtil::utf8ToUcs2(value, it->second);
		p = ZLCachedMemoryAllocator::writeString(p, value);
	}

	myParagraphs.back()->addEntry(myLastEntryStart);
	++myParagraphLengths.back();
}

void ZLTextModel::flush() {
    LogUtil::print("解析缓存流程", "ZLTextModel.flush", "");
	myAllocator->flush();
}

/******************************** 新实现 ******************************/
void ZLTextModel::addParagraphInternalBeta(ZLTextParagraph *paragraph) {
    // myPool size
    const std::size_t dataSize = myAllocator->blocksNumberBeta();
    // myOffset
    const std::size_t bytesOffset = myAllocator->currentBytesOffsetBeta();

    // 记录当前段落在CachedCharStorage类中具体哪一个char[]里面
    myStartEntryIndicesBeta.push_back((dataSize == 0) ? 0 : (dataSize - 1));
    // 记录当前段落从CachedCharStorage类内部char[]的哪个位置开始
    myStartEntryOffsetsBeta.push_back(bytesOffset / 2); // offset in words for future use in Java
    // 记录每个段落在CachedCharStorage类内部char[]占据了多少长度
    myParagraphLengthsBeta.push_back(0);
    myTextSizesBeta.push_back(myTextSizesBeta.empty() ? 0 : myTextSizesBeta.back());
    myParagraphKindsBeta.push_back(paragraph->kind());

    myParagraphsBeta.push_back(paragraph);
    myLastEntryStartBeta = nullptr;
}

void ZLTextModel::finishCurrentFile() {
	LogUtil::print("解析缓存流程", "finishCurrentFile = %s", currentFile.fileName);
	if (currentFile.valid()) return;

    myAllocator->flushCurrentFile(currentFile);
    // 当前xhtml文件解析完毕了, 清除currentFile
    currentFile.clear();
}

void ZLTextModel::setCurrentFile(const std::string& fileName) {
	int idx = fileName.find_last_of("/");
    currentFile = CurProcessFile{fileName.substr(idx + 1, fileName.length()),
						0};
}

void ZLTextModel::addTextBeta(const std::string &text) {
	ZLUnicodeUtil::Ucs2String ucs2str;
	ZLUnicodeUtil::utf8ToUcs2(ucs2str, text);
	const std::size_t len = ucs2str.size();

	if (myLastEntryStartBeta != nullptr && *myLastEntryStartBeta == ZLTextParagraphEntry::TEXT_ENTRY) {
		const std::size_t oldLen = ZLCachedMemoryAllocator::readUInt32(myLastEntryStartBeta + 2);
		const std::size_t newLen = oldLen + len;
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStartBeta = myAllocator->reallocateLastBeta(currentFile, myLastEntryStartBeta, 2 * newLen + 6);
		// 准备myPool末端char[]可写入ptr的地址
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStartBeta + 2, newLen);
		// 最后将xhtml文件的text从ptr开始拷贝到char[]中
		std::memcpy(myLastEntryStartBeta + 6 + oldLen, &ucs2str.front(), 2 * newLen);
	} else {
		// myLastEntryStart: 记录当前paragraph char[]中最后一个char的idx位置
		// paragraph char[]就是ZLCachedMemoryAllocator.myPool
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStartBeta = myAllocator->allocate(currentFile, 2 * len + 6, "addText");
		// 准备myPool末端char[]可写入ptr的地址
		*myLastEntryStartBeta = ZLTextParagraphEntry::TEXT_ENTRY;
		*(myLastEntryStartBeta + 1) = 0;
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStartBeta + 2, len);
		// 最后将xhtml文件的text从ptr开始拷贝到char[]中
		std::memcpy(myLastEntryStartBeta + 6, &ucs2str.front(), 2 * len);
		// 将处理完的ptr存到myParagraphs中, 从这个ptr开始就能读到添加的text
		myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
		// 因为加了一个ptr, 所以myParagraphLengths也要增加
		++myParagraphLengthsBeta.back();
	}
	myTextSizesBeta.back() += len;
}

void ZLTextModel::addTextBeta(const std::vector<std::string> &text) {
	if (text.empty()) {
		return;
	}
	std::size_t fullLength = 0;
	// 遍历text vector计算长度
	for (const auto & it : text) {
		fullLength += ZLUnicodeUtil::utf8Length(it);
	}
	ZLUnicodeUtil::Ucs2String ucs2str;
	// myAllocator中myPool末端char[]没有填满的情况
	if (myLastEntryStartBeta != nullptr && *myLastEntryStartBeta == ZLTextParagraphEntry::TEXT_ENTRY) {
		const std::size_t oldLen = ZLCachedMemoryAllocator::readUInt32(myLastEntryStartBeta + 2);
		const std::size_t newLen = oldLen + fullLength;
		// myLastEntryStart: 记录当前paragraph char[]中最后一个char的idx位置
		// paragraph char[]就是ZLCachedMemoryAllocator.myPool
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStartBeta = myAllocator->reallocateLastBeta(currentFile, myLastEntryStartBeta, 2 * newLen + 6);
		// 准备myPool末端char[]可写入ptr的地址
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStartBeta + 2, newLen);
		std::size_t offset = 6 + oldLen;
		// 遍历文字text
		for (const auto & it : text) {
			ZLUnicodeUtil::utf8ToUcs2(ucs2str, it);
			const std::size_t len = 2 * ucs2str.size();
			// 最后将xhtml文件的text从ptr开始拷贝到char[]中
			std::memcpy(myLastEntryStartBeta + offset, &ucs2str.front(), len);
			offset += len;
			ucs2str.clear();
		}
	} else {
		// myAllocator中myPool末端char[]满了的情况
		// 获得myPool末端char[]可写入ptr的地址
		myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, 2 * fullLength + 6, "addTextBeta");
		// 准备myPool末端char[]可写入ptr的地址
		*myLastEntryStartBeta = ZLTextParagraphEntry::TEXT_ENTRY;
		*(myLastEntryStartBeta + 1) = 0;
		ZLCachedMemoryAllocator::writeUInt32(myLastEntryStartBeta + 2, fullLength);
		std::size_t offset = 6;
		// 遍历文字text
		for (const auto & it : text) {
			ZLUnicodeUtil::utf8ToUcs2(ucs2str, it);
			const std::size_t len = 2 * ucs2str.size();
			// 最后将xhtml文件的text从ptr开始拷贝到char[]中
			std::memcpy(myLastEntryStartBeta + offset, &ucs2str.front(), len);
			offset += len;
			ucs2str.clear();
		}
		myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
		++myParagraphLengthsBeta.back();
	}
	myTextSizesBeta.back() += fullLength;
}

void ZLTextModel::addFixedHSpaceBeta(unsigned char length) {
	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, 4, "addFixedHSpaceBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::FIXED_HSPACE_ENTRY;
	*(myLastEntryStartBeta + 1) = 0;
	*(myLastEntryStartBeta + 2) = length;
	*(myLastEntryStartBeta + 3) = 0;
	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addControlBeta(ZLTextKind textKind, bool isStart) {
    LogUtil::print("addControlBeta", "");
	// 初始化size = 4 的char[]
	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, 4, "addControlBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::CONTROL_ENTRY; // idx = 0, entry kind
	*(myLastEntryStartBeta + 1) = 0; 							 // idx = 1,
	*(myLastEntryStartBeta + 2) = textKind;						 // idx = 2, text kind
	*(myLastEntryStartBeta + 3) = isStart ? 1 : 0;				 // idx = 3, 是否为起始标签
	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addStyleEntryBeta(const ZLTextStyleEntry &entry, const std::vector<std::string> &fontFamilies, unsigned char depth) {
	// +++ calculating entry size
	std::size_t len = 4; // entry type + feature mask
	for (int i = 0; i < ZLTextStyleEntry::NUMBER_OF_LENGTHS; ++i) {
		if (entry.isFeatureSupported((ZLTextStyleEntry::Feature)i)) {
			len += 4; // each supported length
		}
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::ALIGNMENT_TYPE) ||
		entry.isFeatureSupported(ZLTextStyleEntry::NON_LENGTH_VERTICAL_ALIGN)) {
		len += 2;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_FAMILY)) {
		len += 2;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_STYLE_MODIFIER)) {
		len += 2;
	}
	// --- calculating entry size

/*
	EntryCount += 1;
	EntryLen += len;
	std::string debug = "style entry counter: ";
	ZLStringUtil::appendNumber(debug, EntryCount);
	debug += "/";
	ZLStringUtil::appendNumber(debug, EntryLen);
	ZLLogger::Instance().println(ZLLogger::DEFAULT_CLASS, debug);
*/

	// +++ writing entry
	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, len, "addStyleEntryBeta");
	char *address = myLastEntryStartBeta;

	*address++ = entry.entryKind();
	*address++ = depth;
	address = ZLCachedMemoryAllocator::writeUInt16(address, entry.myFeatureMask);

	for (int i = 0; i < ZLTextStyleEntry::NUMBER_OF_LENGTHS; ++i) {
		if (entry.isFeatureSupported((ZLTextStyleEntry::Feature)i)) {
			const ZLTextStyleEntry::LengthType &length = entry.myLengths[i];
			address = ZLCachedMemoryAllocator::writeUInt16(address, length.Size);
			*address++ = length.Unit;
			*address++ = 0;
		}
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::ALIGNMENT_TYPE) ||
		entry.isFeatureSupported(ZLTextStyleEntry::NON_LENGTH_VERTICAL_ALIGN)) {
		*address++ = entry.myAlignmentType;
		*address++ = entry.myVerticalAlignCode;
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_FAMILY)) {
		address = ZLCachedMemoryAllocator::writeUInt16(address, myFontManager.familyListIndex(fontFamilies));
	}
	if (entry.isFeatureSupported(ZLTextStyleEntry::FONT_STYLE_MODIFIER)) {
		*address++ = entry.mySupportedFontModifier;
		*address++ = entry.myFontModifier;
	}
	// --- writing entry

	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addStyleCloseEntryBeta() {
	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, 2, "addStyleCloseEntryBeta");
	char *address = myLastEntryStartBeta;

	*address++ = ZLTextParagraphEntry::STYLE_CLOSE_ENTRY;
	*address++ = 0;

	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addHyperlinkControlBeta(ZLTextKind textKind, ZLHyperlinkType hyperlinkType, const std::string &label) {
	ZLUnicodeUtil::Ucs2String ucs2label;
	ZLUnicodeUtil::utf8ToUcs2(ucs2label, label);

	const std::size_t len = ucs2label.size() * 2;

	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, len + 6, "addHyperlinkControlBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::HYPERLINK_CONTROL_ENTRY;
	*(myLastEntryStartBeta + 1) = 0;
	*(myLastEntryStartBeta + 2) = textKind;
	*(myLastEntryStartBeta + 3) = hyperlinkType;
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStartBeta + 4, ucs2label.size());
	std::memcpy(myLastEntryStartBeta + 6, &ucs2label.front(), len);
	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addImageBeta(const std::string &id, short vOffset, bool isCover) {
	ZLUnicodeUtil::Ucs2String ucs2id;
	ZLUnicodeUtil::utf8ToUcs2(ucs2id, id);

	const std::size_t len = ucs2id.size() * 2;

	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, len + 8, "addImageBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::IMAGE_ENTRY;
	*(myLastEntryStartBeta + 1) = 0;
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStartBeta + 2, vOffset);
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStartBeta + 4, ucs2id.size());
	std::memcpy(myLastEntryStartBeta + 6, &ucs2id.front(), len);
	ZLCachedMemoryAllocator::writeUInt16(myLastEntryStartBeta + 6 + len, isCover ? 1 : 0);
	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addBidiResetBeta() {
	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, 2, "addBidiResetBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::RESET_BIDI_ENTRY;
	*(myLastEntryStartBeta + 1) = 0;
	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addVideoEntryBeta(const ZLVideoEntry &entry) {
	const std::map<std::string,std::string> &sources = entry.sources();

	std::size_t len = 4;
	for (std::map<std::string,std::string>::const_iterator it = sources.begin(); it != sources.end(); ++it) {
		len += 2 * (ZLUnicodeUtil::utf8Length(it->first) + ZLUnicodeUtil::utf8Length(it->second)) + 4;
	}

	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, len, "addVideoEntryBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::VIDEO_ENTRY;
	*(myLastEntryStartBeta + 1) = 0;
	char *p = ZLCachedMemoryAllocator::writeUInt16(myLastEntryStartBeta + 2, sources.size());
	for (std::map<std::string,std::string>::const_iterator it = sources.begin(); it != sources.end(); ++it) {
		ZLUnicodeUtil::Ucs2String first;
		ZLUnicodeUtil::utf8ToUcs2(first, it->first);
		p = ZLCachedMemoryAllocator::writeString(p, first);
		ZLUnicodeUtil::Ucs2String second;
		ZLUnicodeUtil::utf8ToUcs2(second, it->second);
		p = ZLCachedMemoryAllocator::writeString(p, second);
	}

	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}

void ZLTextModel::addExtensionEntryBeta(const std::string &action, const std::map<std::string,std::string> &data) {
	std::size_t fullLength = 2;                                      // entry type + map size
	fullLength += 2 + ZLUnicodeUtil::utf8Length(action) * 2;         // action name
	for (std::map<std::string,std::string>::const_iterator it = data.begin(); it != data.end(); ++it) {
		fullLength += 2 + ZLUnicodeUtil::utf8Length(it->first) * 2;    // data key
		fullLength += 2 + ZLUnicodeUtil::utf8Length(it->second) * 2;   // data value
	}

	myLastEntryStartBeta = myAllocator->allocateBeta(currentFile, fullLength, "addExtensionEntryBeta");
	*myLastEntryStartBeta = ZLTextParagraphEntry::EXTENSION_ENTRY;
	*(myLastEntryStartBeta + 1) = data.size();

	char *p = myLastEntryStartBeta + 2;
	ZLUnicodeUtil::Ucs2String ucs2action;
	ZLUnicodeUtil::utf8ToUcs2(ucs2action, action);
	p = ZLCachedMemoryAllocator::writeString(p, ucs2action);

	for (std::map<std::string,std::string>::const_iterator it = data.begin(); it != data.end(); ++it) {
		ZLUnicodeUtil::Ucs2String key;
		ZLUnicodeUtil::utf8ToUcs2(key, it->first);
		p = ZLCachedMemoryAllocator::writeString(p, key);
		ZLUnicodeUtil::Ucs2String value;
		ZLUnicodeUtil::utf8ToUcs2(value, it->second);
		p = ZLCachedMemoryAllocator::writeString(p, value);
	}

	myParagraphsBeta.back()->addEntry(myLastEntryStartBeta);
	++myParagraphLengthsBeta.back();
}