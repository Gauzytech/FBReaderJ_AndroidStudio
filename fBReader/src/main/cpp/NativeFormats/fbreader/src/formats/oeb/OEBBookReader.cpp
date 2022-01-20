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

#include <algorithm>

#include <ZLDir.h>
#include <ZLInputStream.h>
#include <ZLLogger.h>
#include <ZLStringUtil.h>
#include <ZLUnicodeUtil.h>
#include <FileEncryptionInfo.h>
#include <ZLFile.h>
#include <ZLFileImage.h>
#include <ZLXMLNamespace.h>
#include <LogUtil.h>

#include "OEBBookReader.h"
#include "OEBEncryptionReader.h"
#include "XHTMLImageFinder.h"
#include "NCXReader.h"
#include "../xhtml/XHTMLReader.h"
#include "../util/MiscUtil.h"
#include "../../bookmodel/BookModel.h"

OEBBookReader::OEBBookReader(BookModel &model) : myModelReader(model) {
	LogUtil::print("OEBBookReader constructor", "");
}

static const std::string MANIFEST = "manifest";
static const std::string SPINE = "spine";
static const std::string GUIDE = "guide";
static const std::string TOUR = "tour";
static const std::string SITE = "site";

static const std::string ITEM = "item";
static const std::string ITEMREF = "itemref";
static const std::string REFERENCE = "reference";

static const std::string COVER = "cover";
static const std::string COVER_IMAGE = "other.ms-coverimage-standard";

void OEBBookReader::startElementHandler(const char *tag, const char **xmlattributes) {
	std::string tagString = ZLUnicodeUtil::toLower(tag);

	LogUtil::print("OEBBookReader.startElementHandler %s", tagString + ", " + getReadStateStr(myState));
	switch (myState) {
		case READ_NONE:
			if (testOPFTag(MANIFEST, tagString)) {
				myState = READ_MANIFEST;
			} else if (testOPFTag(SPINE, tagString)) {
				const char *toc = attributeValue(xmlattributes, "toc");
				if (toc != 0) {
					myNCXTOCFileName = myIdToHref[toc];
				}
				myState = READ_SPINE;
			} else if (testOPFTag(GUIDE, tagString)) {
				myState = READ_GUIDE;
			} else if (testOPFTag(TOUR, tagString)) {
				myState = READ_TOUR;
			}
			break;
		case READ_MANIFEST:
			if (testOPFTag(ITEM, tagString)) {
				const char *href = attributeValue(xmlattributes, "href");
				if (href != 0) {
					const std::string sHref = MiscUtil::decodeHtmlURL(href);
					const char *id = attributeValue(xmlattributes, "id");
					const char *mediaType = attributeValue(xmlattributes, "media-type");
					if (id != 0) {
						myIdToHref[id] = sHref;
					}
					if (mediaType != 0) {
						myHrefToMediatype[sHref] = mediaType;
					}
				}
			}
			break;
		case READ_SPINE:
			if (testOPFTag(ITEMREF, tagString)) {
				const char *id = attributeValue(xmlattributes, "idref");
				if (id != 0) {
					const std::string &fileName = myIdToHref[id];
					if (!fileName.empty()) {
						myHtmlFileNames.push_back(fileName);
					}
				}
			}
			break;
		case READ_GUIDE:
			if (testOPFTag(REFERENCE, tagString)) {
				const char *type = attributeValue(xmlattributes, "type");
				const char *title = attributeValue(xmlattributes, "title");
				const char *href = attributeValue(xmlattributes, "href");
				if (href != 0) {
					const std::string reference = MiscUtil::decodeHtmlURL(href);
					if (title != 0) {
						myGuideTOC.push_back(std::make_pair(std::string(title), reference));
					}
					if (type != 0 && (COVER == type || COVER_IMAGE == type)) {
						ZLFile imageFile(myFilePrefix + reference);
						myCoverFileName = imageFile.path();
						myCoverFileType = type;
						const std::map<std::string,std::string>::const_iterator it =
							myHrefToMediatype.find(reference);
						myCoverMimeType =
							it != myHrefToMediatype.end() ? it->second : std::string();
					}
				}
			}
			break;
		case READ_TOUR:
			if (testOPFTag(SITE, tagString)) {
				const char *title = attributeValue(xmlattributes, "title");
				const char *href = attributeValue(xmlattributes, "href");
				if ((title != 0) && (href != 0)) {
					myTourTOC.push_back(std::make_pair(title, MiscUtil::decodeHtmlURL(href)));
				}
			}
			break;
	}
}

bool OEBBookReader::coverIsSingleImage() const {
	return
		COVER_IMAGE == myCoverFileType ||
		(COVER == myCoverFileType &&
			ZLStringUtil::stringStartsWith(myCoverMimeType, "image/"));
}

void OEBBookReader::addCoverImage() {
	ZLFile imageFile(myCoverFileName);
	shared_ptr<const ZLImage> image = coverIsSingleImage()
		? new ZLFileImage(imageFile, "", 0) : XHTMLImageFinder().readImage(imageFile);

	if (!image.isNull()) {
		const std::string imageName = imageFile.name(false);
		myModelReader.setMainTextModel();
		myModelReader.addImageReference(imageName, (short)0, true);
		myModelReader.addImage(imageName, image);
		myModelReader.insertEndOfSectionParagraph();
	}
}

void OEBBookReader::endElementHandler(const char *tag) {
	std::string tagString = ZLUnicodeUtil::toLower(tag);

	switch (myState) {
		case READ_MANIFEST:
			if (testOPFTag(MANIFEST, tagString)) {
				myState = READ_NONE;
			}
			break;
		case READ_SPINE:
			if (testOPFTag(SPINE, tagString)) {
				myState = READ_NONE;
			}
			break;
		case READ_GUIDE:
			if (testOPFTag(GUIDE, tagString)) {
				myState = READ_NONE;
			}
			break;
		case READ_TOUR:
			if (testOPFTag(TOUR, tagString)) {
				myState = READ_NONE;
			}
			break;
		case READ_NONE:
			break;
	}
}

bool OEBBookReader::readBook(const ZLFile &opfFile) {
	LogUtil::print("OEBBookReader.readBook(opfFile) opf文件路径 = %s", opfFile.path());
	const ZLFile epubFile = opfFile.getContainerArchive();
	epubFile.forceArchiveType(ZLFile::ZIP);
	// 解压缩epub文件，获得整个epub文件夹
	shared_ptr<ZLDir> epubDir = epubFile.directory();
	// 判断是否有DRM加密存在,
	if (!epubDir.isNull()) {
		myEncryptionMap = new EncryptionMap();
		// 保存所有加密/解密的信息
		const std::vector<shared_ptr<FileEncryptionInfo> > encodingInfos =
			OEBEncryptionReader().readEncryptionInfos(epubFile, opfFile);

		for (std::vector<shared_ptr<FileEncryptionInfo> >::const_iterator it = encodingInfos.begin(); it != encodingInfos.end(); ++it) {
			myEncryptionMap->addInfo(*epubDir, *it);
		}
	}
	// htmlDirectoryPrefix: epub里面文件的根路径
	// eg: /data/data/org.geometerplus.zlibrary.ui.android/files/JavaScript高级程序设计（第3版） - [美] Nicholas C. Zakas.epub:
	myFilePrefix = MiscUtil::htmlDirectoryPrefix(opfFile.path());
	LogUtil::print("OEBBookReader.readBook(opfFile), 根路径myFilePrefix = %s", myFilePrefix);

	// 把所有之前的缓存清空
	myIdToHref.clear();
	myHtmlFileNames.clear();
	myNCXTOCFileName.erase();
	myCoverFileName.erase();
	myCoverFileType.erase();
	myCoverMimeType.erase();
	myTourTOC.clear();
	myGuideTOC.clear();
	myState = READ_NONE;


	// 将opf文件内容读到一个char[]中
	// 并opf中的spine数据保存在myHtmlFileNames中
	if (!readDocument(opfFile)) {
		return false;
	}

	// 将bookModel中的TextModel保存
	// TextModel在bookModel constructor中创建
	myModelReader.setMainTextModel();
	LogUtil::print("OEBBookReader.readBook -> setMainTextModel paragraphsNumber: %s",
				std::to_string(myModelReader.model().bookTextModel()->paragraphsNumber()) + " language: " + myModelReader.model().bookTextModel()->language());

	// 向myKindStack属性加入FBTextKind.REGULAR (0)
	myModelReader.pushKind(REGULAR);
	// 初始化xhtmlReader
	XHTMLReader xhtmlReader(myModelReader, myEncryptionMap);
	// 根据myHtmlFileNames, 遍历所有文件, 并使用xhtmlReader解析所有文件内容
	for (std::vector<std::string>::const_iterator it = myHtmlFileNames.begin(); it != myHtmlFileNames.end(); ++it) {
		// 生成代表xhtml文件的ZLZipEntryFile类
		const ZLFile xhtmlFile(myFilePrefix + *it);
		if (it == myHtmlFileNames.begin()) {
			// 处理保存封面文件
			if (myCoverFileName == xhtmlFile.path()) {
				if (coverIsSingleImage()) {
					addCoverImage();
					continue;
				}
				// 如果有好几张cover image只用第一张
				xhtmlReader.setMarkFirstImageAsCover();
			} else {
				addCoverImage();
			}
		} else {
			myModelReader.insertEndOfSectionParagraph();
		}
		// xhtmlReader类的readFile方法会开始对xhtml文件的解析
		// readFile会注册xhtmlReader的elementHandler
		LogUtil::print("xhtmlReader.readFile, START----------->>> %s", xhtmlFile.path());
		if (!xhtmlReader.readFile(xhtmlFile, *it)) {
			if (opfFile.exists() && !myEncryptionMap.isNull()) {
				myModelReader.insertEncryptedSectionParagraph();
			}
		}
		LogUtil::print("readBook, para count = %s", std::to_string(myModelReader.model().bookTextModel()->paragraphsNumber()));
		const std::string& fileName = xhtmlFile.name(false);
//		if (fileName == "titlepage.xhtml" || fileName == "text/part0000_split_000.html") {
//			myModelReader.model().bookTextModel()->printParagraph();
//		}
		LogUtil::print("xhtmlReader.readFile, <<<------------END %s", fileName);
	}

	// 生成目录信息
	generateTOC(xhtmlReader);

	return true;
}

void OEBBookReader::generateTOC(const XHTMLReader &xhtmlReader) {
	if (!myNCXTOCFileName.empty()) {
		NCXReader ncxReader(myModelReader);
		const ZLFile ncxFile(myFilePrefix + myNCXTOCFileName);
		// toc信息在toc.ncx里
		// 将toc.ncx文件读取到myNavigationMap, myPointStack中
		if (ncxReader.readDocument(ncxFile.inputStream(myEncryptionMap))) {
			// navMap代表整个toc结构
			const std::map<int,NCXReader::NavPoint> navigationMap = ncxReader.navigationMap();
			if (!navigationMap.empty()) {
				std::size_t level = 0;
				for (std::map<int,NCXReader::NavPoint>::const_iterator it = navigationMap.begin(); it != navigationMap.end(); ++it) {
					// 获得navPoint
					const NCXReader::NavPoint &point = it->second;
					int index = myModelReader.model().label(xhtmlReader.normalizedReference(point.ContentHRef)).ParagraphNumber;
					// 创建toc
					while (level > point.Level) {
						myModelReader.endContentsParagraph();
						--level;
					}
					while (++level <= point.Level) {
						myModelReader.beginContentsParagraph(-2);
						myModelReader.addContentsData("...");
					}
					myModelReader.beginContentsParagraph(index);
					myModelReader.addContentsData(point.Text);
				}
				while (level > 0) {
					myModelReader.endContentsParagraph();
					--level;
				}
				return;
			}
		}
	}

	// 根据opf中的<guide>, <tour>标签添加toc数据
	std::vector<std::pair<std::string,std::string> > &toc = myTourTOC.empty() ? myGuideTOC : myTourTOC;
	for (std::vector<std::pair<std::string,std::string> >::const_iterator it = toc.begin(); it != toc.end(); ++it) {
		int index = myModelReader.model().label(it->second).ParagraphNumber;
		if (index != -1) {
			myModelReader.beginContentsParagraph(index);
			myModelReader.addContentsData(it->first);
			myModelReader.endContentsParagraph();
		}
	}
}
