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

#include <AndroidUtil.h>

#include <ZLFile.h>
#include <ZLDir.h>
#include <ZLOutputStream.h>
#include <ZLStringUtil.h>

#include "ZLCachedMemoryAllocator.h"
#include <LogUtil.h>

/**
 * 缓存解析文件结果工具类
 * @param rowSize
 * @param directoryName /storage/emulated/0/Android/data/org.geometerplus.zlibrary.ui.android/cache
 * @param fileExtension 比如: ncache: paragraph解析结果
 * 							 footnotes: 脚注
 * 							 nlinks: 超链接
 */
ZLCachedMemoryAllocator::ZLCachedMemoryAllocator(const std::size_t rowSize,
		const std::string &directoryName, const std::string &fileExtension) :
	myRowSize(rowSize),
	myCurrentRowSize(0),
	myOffset(0),
	myHasChanges(false),
	myFailed(false),
	myDirectoryName(directoryName),
	myFileExtension(fileExtension) {
	// 创建cache文件夹
	ZLFile(directoryName).directory(true);
}

ZLCachedMemoryAllocator::~ZLCachedMemoryAllocator() {
	flush();
	for (std::vector<char*>::const_iterator it = myPool.begin(); it != myPool.end(); ++it) {
		delete[] *it;
	}
}

void ZLCachedMemoryAllocator::flush() {
	if (!myHasChanges) {
		return;
	}
	char *ptr = myPool.back() + myOffset;
	*ptr++ = 0;
	*ptr = 0;
	writeCache(myOffset + 2, "");
	myHasChanges = false;
}

std::string ZLCachedMemoryAllocator::makeFileName(std::size_t index) {
	std::string name(myDirectoryName);
	name.append("/");
	ZLStringUtil::appendNumber(name, index);
	LogUtil::print("解析缓存流程", "缓存文件名 %s", name);
	return name.append(".").append(myFileExtension);
}

void ZLCachedMemoryAllocator::writeCache(std::size_t blockLength, const std::string& from) {
	if (myFailed || myPool.empty()) {
		return;
	}
//	LogUtil::print("writeCache %s", std::to_string(blockLength));

	const std::size_t index = myPool.size() - 1;
	const std::string fileName = makeFileName(index);
	LogUtil::print("解析缓存流程", "writeCache, " + from + " name = %s", fileName);

	ZLFile file(fileName);
	shared_ptr<ZLOutputStream> stream = file.outputStream();
	if (stream.isNull() || !stream->open()) {
		myFailed = true;
		return;
	}
	stream->write(myPool[index], blockLength);
	stream->close();
}

/**
 * allocate内存给当前读到的text, 如果超出了解析缓存长度myPool, 就直接创建一个本地缓存文件
 * @param size 当前读到的text长度
 */
char *ZLCachedMemoryAllocator::allocate(std::size_t size, const std::string& from) {
	myHasChanges = true;
	if (myPool.empty()) {
		myCurrentRowSize = std::max(myRowSize, size + 2 + sizeof(char*));
		myPool.push_back(new char[myCurrentRowSize]);
	} else if (myOffset + size + 2 + sizeof(char*) > myCurrentRowSize) {
	    // 当前读取的char[]长度已经超过了最大长度myCurrentRowSize
	    // TODO 需要改成在一个xhtml文件内容全部解析完毕时，进行一次writeCache操作, 此操作可以实现1个xhtml文件对应1个或多个本地缓存.ncahce文件
		myCurrentRowSize = std::max(myRowSize, size + 2 + sizeof(char*));
		char *row = new char[myCurrentRowSize];

		char *ptr = myPool.back() + myOffset;
		*ptr++ = 0;
		*ptr++ = 0;
		std::memcpy(ptr, &row, sizeof(char*));
		writeCache(myOffset + 2, from);
		// 缓存写入完毕了, 加一个新的char[]到myPool中
		myPool.push_back(row);
		// 重新开始计算char[]的offset
		myOffset = 0;
	}
	char *ptr = myPool.back() + myOffset;
	myOffset += size;
	return ptr;
}

char *ZLCachedMemoryAllocator::reallocateLast(char *ptr, std::size_t newSize) {
	LogUtil::print("解析缓存流程", "reallocateLast %s", std::to_string(newSize));
	myHasChanges = true;
	const std::size_t oldOffset = ptr - myPool.back();
	// sizeof(char*) 返回字符型指针所占内存的大小, 值为4
	if (oldOffset + newSize + 2 + sizeof(char*) <= myCurrentRowSize) {
		myOffset = oldOffset + newSize;
		return ptr;
	} else {
		myCurrentRowSize = std::max(myRowSize, newSize + 2 + sizeof(char*));
		char *row = new char[myCurrentRowSize];
		std::memcpy(row, ptr, myOffset - oldOffset);

		*ptr++ = 0;
		*ptr++ = 0;
		std::memcpy(ptr, &row, sizeof(char*));
		writeCache(oldOffset + 2, "");
		// 缓存写入完毕了, 加一个新的char[]到myPool中
		myPool.push_back(row);
		// char[]的offset从newSize开始
		myOffset = newSize;
		return row;
	}
}
