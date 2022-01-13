/*
 * Copyright (C) 2011-2015 FBReader.ORG Limited <contact@fbreader.org>
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

#include <AndroidUtil.h>
#include <JniEnvelope.h>
#include <ZLFileImage.h>
#include <FileEncryptionInfo.h>

#include "fbreader/src/bookmodel/BookModel.h"
#include "fbreader/src/formats/FormatPlugin.h"
#include "fbreader/src/library/Author.h"
#include "fbreader/src/library/Book.h"
#include "fbreader/src/library/Tag.h"
#include "fbreader/src/library/UID.h"

#include <LogUtil.h>

static shared_ptr<FormatPlugin> findCppPlugin(jobject base) {
	const std::string fileType = AndroidUtil::Method_NativeFormatPlugin_supportedFileType->callForCppString(base);
	return PluginCollection::Instance().pluginByType(fileType);
}

static void fillUids(JNIEnv* env, jobject javaBook, Book &book) {
	const UIDList &uids = book.uids();
	for (UIDList::const_iterator it = uids.begin(); it != uids.end(); ++it) {
		JString type(env, (*it)->Type);
		JString id(env, (*it)->Id);
		AndroidUtil::Method_Book_addUid->call(javaBook, type.j(), id.j());
	}
}

static void fillMetaInfo(JNIEnv* env, jobject javaBook, Book &book) {
	JString title(env, book.title());
	AndroidUtil::Method_Book_setTitle->call(javaBook, title.j());

	JString language(env, book.language());
	if (language.j() != 0) {
		AndroidUtil::Method_Book_setLanguage->call(javaBook, language.j());
	}

	JString encoding(env, book.encoding());
	if (encoding.j() != 0) {
		AndroidUtil::Method_Book_setEncoding->call(javaBook, encoding.j());
	}

	JString seriesTitle(env, book.seriesTitle());
	if (seriesTitle.j() != 0) {
		JString indexString(env, book.indexInSeries());
		AndroidUtil::Method_Book_setSeriesInfo->call(javaBook, seriesTitle.j(), indexString.j());
	}

	const AuthorList &authors = book.authors();
	for (std::size_t i = 0; i < authors.size(); ++i) {
		const Author &author = *authors[i];
		JString name(env, author.name(), false);
		JString key(env, author.sortKey(), false);
		AndroidUtil::Method_Book_addAuthor->call(javaBook, name.j(), key.j());
	}

	const TagList &tags = book.tags();
	for (std::size_t i = 0; i < tags.size(); ++i) {
		const Tag &tag = *tags[i];
		AndroidUtil::Method_Book_addTag->call(javaBook, tag.javaTag(env));
	}

	fillUids(env, javaBook, book);
}

static void fillLanguageAndEncoding(JNIEnv* env, jobject javaBook, Book &book) {
	JString language(env, book.language());
	if (language.j() != 0) {
		AndroidUtil::Method_Book_setLanguage->call(javaBook, language.j());
	}

	JString encoding(env, book.encoding());
	if (encoding.j() != 0) {
		AndroidUtil::Method_Book_setEncoding->call(javaBook, encoding.j());
	}
}

extern "C"
JNIEXPORT jint JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readMetainfoNative(JNIEnv* env, jobject thiz, jobject javaBook) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return 1;
	}

	shared_ptr<Book> book = Book::loadFromJavaBook(env, javaBook);

	if (!plugin->readMetainfo(*book)) {
		return 2;
	}

	fillMetaInfo(env, javaBook, *book);
	return 0;
}

extern "C"
JNIEXPORT jobject JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readEncryptionInfosNative(JNIEnv* env, jobject thiz, jobject javaBook) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return 0;
	}

	shared_ptr<Book> book = Book::loadFromJavaBook(env, javaBook);
	std::vector<shared_ptr<FileEncryptionInfo> > infos = plugin->readEncryptionInfos(*book);
	if (infos.empty()) {
		return 0;
	}

	jobjectArray jList = env->NewObjectArray(
		infos.size(), AndroidUtil::Class_FileEncryptionInfo.j(), 0
	);
	for (std::size_t i = 0; i < infos.size(); ++i) {
		jobject jInfo = AndroidUtil::createJavaEncryptionInfo(env, infos[i]);
		env->SetObjectArrayElement(jList, i, jInfo);
		env->DeleteLocalRef(jInfo);
	}
	return jList;
}

extern "C"
JNIEXPORT void JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readUidsNative(JNIEnv* env, jobject thiz, jobject javaBook) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return;
	}

	shared_ptr<Book> book = Book::loadFromJavaBook(env, javaBook);

	plugin->readUids(*book);
	fillUids(env, javaBook, *book);
}

extern "C"
JNIEXPORT void JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_detectLanguageAndEncodingNative(JNIEnv* env, jobject thiz, jobject javaBook) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return;
	}

	shared_ptr<Book> book = Book::loadFromJavaBook(env, javaBook);
	if (!plugin->readLanguageAndEncoding(*book)) {
		return;
	}

	fillLanguageAndEncoding(env, javaBook, *book);
}

static bool initInternalHyperlinks(JNIEnv *env, jobject javaModel, BookModel &model, const std::string &cacheDir) {
	ZLCachedMemoryAllocator allocator(131072, cacheDir, "nlinks");

	ZLUnicodeUtil::Ucs2String ucs2id;
	ZLUnicodeUtil::Ucs2String ucs2modelId;

	const std::map<std::string,BookModel::Label> &links = model.internalHyperlinks();
	std::map<std::string,BookModel::Label>::const_iterator it = links.begin();
	for (; it != links.end(); ++it) {
		const std::string &id = it->first; // key
		const BookModel::Label &label = it->second; // value
		if (label.Model.isNull()) {
			continue;
		}
		ZLUnicodeUtil::utf8ToUcs2(ucs2id, id);
		ZLUnicodeUtil::utf8ToUcs2(ucs2modelId, label.Model->id());
		const std::size_t idLen = ucs2id.size() * 2;
		const std::size_t modelIdLen = ucs2modelId.size() * 2;

		char *ptr = allocator.allocate(idLen + modelIdLen + 8);
		ZLCachedMemoryAllocator::writeUInt16(ptr, ucs2id.size());
		ptr += 2;
		std::memcpy(ptr, &ucs2id.front(), idLen);
		ptr += idLen;
		ZLCachedMemoryAllocator::writeUInt16(ptr, ucs2modelId.size());
		ptr += 2;
		std::memcpy(ptr, &ucs2modelId.front(), modelIdLen);
		ptr += modelIdLen;
		ZLCachedMemoryAllocator::writeUInt32(ptr, label.ParagraphNumber);
	}
	allocator.flush();

	JString linksDirectoryName(env, allocator.directoryName(), false);
	JString linksFileExtension(env, allocator.fileExtension(), false);
	jint linksBlocksNumber = allocator.blocksNumber();
	AndroidUtil::Method_BookModel_initInternalHyperlinks->call(javaModel, linksDirectoryName.j(), linksFileExtension.j(), linksBlocksNumber);
	return !env->ExceptionCheck();
}

/**
 * 调用了java方法, 使用cpp textModel的数据创建了java textModel
 */
static jobject createTextModel(JNIEnv *env, jobject javaModel, ZLTextModel &model) {
	env->PushLocalFrame(16);

	jstring id = AndroidUtil::createJavaString(env, model.id());
	jstring language = AndroidUtil::createJavaString(env, model.language());
	jint paragraphsNumber = model.paragraphsNumber();

	const std::size_t arraysSize = model.startEntryIndices().size();
	jintArray entryIndices = env->NewIntArray(arraysSize);
	jintArray entryOffsets = env->NewIntArray(arraysSize);
	jintArray paragraphLenghts = env->NewIntArray(arraysSize);
	jintArray textSizes = env->NewIntArray(arraysSize);
	jbyteArray paragraphKinds = env->NewByteArray(arraysSize);
	env->SetIntArrayRegion(entryIndices, 0, arraysSize, &model.startEntryIndices().front());
	env->SetIntArrayRegion(entryOffsets, 0, arraysSize, &model.startEntryOffsets().front());
	env->SetIntArrayRegion(paragraphLenghts, 0, arraysSize, &model.paragraphLengths().front());
	env->SetIntArrayRegion(textSizes, 0, arraysSize, &model.textSizes().front());
	env->SetByteArrayRegion(paragraphKinds, 0, arraysSize, &model.paragraphKinds().front());

	jstring directoryName = env->NewStringUTF(model.allocator().directoryName().c_str());
	jstring fileExtension = env->NewStringUTF(model.allocator().fileExtension().c_str());
	jint blocksNumber = (jint) model.allocator().blocksNumber();

	// 调用java方法创建ZLTextPlainModel对象
	jobject textModel = AndroidUtil::Method_BookModel_createTextModel->call(
		javaModel,
		id, language,
		paragraphsNumber, entryIndices, entryOffsets,
		paragraphLenghts, textSizes, paragraphKinds,
		directoryName, fileExtension, blocksNumber
	);

	if (env->ExceptionCheck()) {
		textModel = 0;
	}
	return env->PopLocalFrame(textModel);
}

static bool ct_compare(const shared_ptr<ContentsTree> &first, const shared_ptr<ContentsTree> &second) {
	return first->reference() < second->reference();
}

static void initTOC(JNIEnv *env, jobject javaModel, const ContentsTree &tree) {
	std::vector<shared_ptr<ContentsTree> > children = tree.children();
	std::sort(children.begin(), children.end(), ct_compare);
	for (std::vector<shared_ptr<ContentsTree> >::const_iterator it = children.begin(); it != children.end(); ++it) {
		const ContentsTree &child = **it;
		JString text(env, child.text());
		AndroidUtil::Method_BookModel_addTOCItem->call(javaModel, text.j(), child.reference());

		initTOC(env, javaModel, child);

		AndroidUtil::Method_BookModel_leaveTOCItem->call(javaModel);
	}
}

static jobject createJavaFileInfo(JNIEnv *env, shared_ptr<FileInfo> info) {
	if (info.isNull()) {
		return 0;
	}

	JString path(env, info->Path, false);
	jobject encryptionInfo = AndroidUtil::createJavaEncryptionInfo(env, info->EncryptionInfo);

	jobject fileInfo = AndroidUtil::Constructor_FileInfo->call(path.j(), encryptionInfo);

	if (encryptionInfo != 0) {
		env->DeleteLocalRef(encryptionInfo);
	}

	return fileInfo;
}

// 核心方法, 图书解析操作
extern "C"
JNIEXPORT jint JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readModelNative(JNIEnv* env, jobject thiz, jobject javaBookModel, jstring javaCacheDir) {
	// 1. 获得解析plugin
    shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return 1;
	}

	// 2. 获得缓存文件夹目录
	const std::string cacheDir = AndroidUtil::fromJavaString(env, javaCacheDir);

	// 3.
	// 因为jobject不能当做在java中一样直接调用其中method, 此时要先将其转化成cpp对象
	// 传过来的javaModel(bookModel) -> 转换成cpp bookModel的步骤
	// 3.1 从传过来的javaModel中获得javaBook
	jobject javaBook = AndroidUtil::Field_BookModel_Book->value(javaBookModel);
	// 3.2 通过javaBook创建cpp book
	shared_ptr<Book> book = Book::loadFromJavaBook(env, javaBook);
	// 3.3 通过javaModel, cpp book, 和cacheDir 创建cpp bookModel
	shared_ptr<BookModel> model = new BookModel(book, javaBookModel, cacheDir);

	LogUtil::print("readModelNative, 开始使用%s进行readModel操作 ", typeid(*plugin).name());

    // 4. 使用plugin对cpp bookModel进行解析
    // 读取了opf, container, 所有xhtml文件, 和toc.ncx文件
    if (!plugin->readModel(*model)) {
    	// 解析失败
		return 2;
	}
	if (!model->flush()) {
		// 内存不足
		return 3;
	}

	if (!initInternalHyperlinks(env, javaBookModel, *model, cacheDir)) {
		// 初始化超链接失败
		return 4;
	}
	// 5. 调用java方法, 将toc数据保存到java
	initTOC(env, javaBookModel, *model->contentsTree());

	// 6. 获得渲染模型
	shared_ptr<ZLTextModel> textModel = model->bookTextModel();
	// 7. 通过cpp textModel: ZLTextModel创建java textModel: ZLTextPlainModel
	jobject javaTextModel = createTextModel(env, javaBookModel, *textModel);
	if (javaTextModel == 0) {
		return 5;
	}
	// 7.1 调用java方法, 将javaTextModel保存到java bookModel中
	AndroidUtil::Method_BookModel_setBookTextModel->call(javaBookModel, javaTextModel);
	if (env->ExceptionCheck()) {
		return 6;
	}
	env->DeleteLocalRef(javaTextModel);

	// 8. 脚注, 是个底部弹窗， 见https://fbreader.org/tags/footnotes
	const std::map<std::string,shared_ptr<ZLTextModel> > &footnotes = model->footnotes();
	std::map<std::string,shared_ptr<ZLTextModel> >::const_iterator it = footnotes.begin();
	for (; it != footnotes.end(); ++it) {
		jobject javaFootnoteModel = createTextModel(env, javaBookModel, *it->second);
		if (javaFootnoteModel == 0) {
			return 7;
		}
		// 调用java方法, 保存footnotes数据
		AndroidUtil::Method_BookModel_setFootnoteModel->call(javaBookModel, javaFootnoteModel);
		if (env->ExceptionCheck()) {
			return 8;
		}
		env->DeleteLocalRef(javaFootnoteModel);
	}

	// 9. familyLists数据，再创建paragraph时设置: beginParagraph.addTextStyleEntry
	const std::vector<std::vector<std::string> > familyLists = model->fontManager().familyLists();
	for (std::vector<std::vector<std::string> >::const_iterator it = familyLists.begin(); it != familyLists.end(); ++it) {
		const std::vector<std::string> &lst = *it;
		jobjectArray jList = env->NewObjectArray(lst.size(), AndroidUtil::Class_java_lang_String.j(), 0);
		for (std::size_t i = 0; i < lst.size(); ++i) {
			JString jString(env, lst[i]);
			env->SetObjectArrayElement(jList, i, jString.j());
		}
        // 调用java方法, 保存familyLists数据
		AndroidUtil::Method_BookModel_registerFontFamilyList->call(javaBookModel, jList);
		env->DeleteLocalRef(jList);
	}

	// entries数据, 和familyLists数据一起在xhtmlReader中被设置XHTMLReader::addTextStyleEntry
	const std::map<std::string,shared_ptr<FontEntry> > entries = model->fontManager().entries();
	for (std::map<std::string,shared_ptr<FontEntry> >::const_iterator it = entries.begin(); it != entries.end(); ++it) {
		if (it->second.isNull()) {
			continue;
		}
		JString family(env, it->first);
		jobject normal = createJavaFileInfo(env, it->second->Normal);
		jobject bold = createJavaFileInfo(env, it->second->Bold);
		jobject italic = createJavaFileInfo(env, it->second->Italic);
		jobject boldItalic = createJavaFileInfo(env, it->second->BoldItalic);
        // 调用java方法, 保存entries数据
		AndroidUtil::Method_BookModel_registerFontEntry->call(
				javaBookModel, family.j(), normal, bold, italic, boldItalic
		);

		if (boldItalic != 0) env->DeleteLocalRef(boldItalic);
		if (italic != 0) env->DeleteLocalRef(italic);
		if (bold != 0) env->DeleteLocalRef(bold);
		if (normal != 0) env->DeleteLocalRef(normal);
	}

	return 0;
}

extern "C"
JNIEXPORT jstring JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readAnnotationNative(JNIEnv* env, jobject thiz, jobject file) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return 0;
	}

	const std::string path = AndroidUtil::Method_ZLFile_getPath->callForCppString(file);
	return AndroidUtil::createJavaString(env, plugin->readAnnotation(ZLFile(path)));
}

extern "C"
JNIEXPORT void JNICALL Java_org_geometerplus_fbreader_formats_NativeFormatPlugin_readCoverNative(JNIEnv* env, jobject thiz, jobject file, jobjectArray box) {
	shared_ptr<FormatPlugin> plugin = findCppPlugin(thiz);
	if (plugin.isNull()) {
		return;
	}

	const std::string path = AndroidUtil::Method_ZLFile_getPath->callForCppString(file);

	shared_ptr<const ZLImage> image = plugin->coverImage(ZLFile(path));
	if (!image.isNull()) {
		jobject javaImage = AndroidUtil::createJavaImage(env, (const ZLFileImage&)*image);
		env->SetObjectArrayElement(box, 0, javaImage);
		env->DeleteLocalRef(javaImage);
	}
}
