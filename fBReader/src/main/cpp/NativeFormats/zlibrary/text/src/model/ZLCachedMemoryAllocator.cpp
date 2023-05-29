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
 * 缓存解析文件结果工具类: 将解析的数据保存到本地
 *
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
	// 新实现
	myCurrentRowSizeBeta(0),
	myOffsetBeta(0),
	myFileExtension(fileExtension) {
	// 创建cache文件夹
	ZLFile(directoryName).directory(true);

}

ZLCachedMemoryAllocator::~ZLCachedMemoryAllocator() {
	flush();
	for (std::vector<char*>::const_iterator it = myPool.begin(); it != myPool.end(); ++it) {
		delete[] *it;
	}

	// 新实现
	for (std::vector<char*>::const_iterator it = myPoolBeta.begin(); it != myPoolBeta.end(); ++it) {
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
	writeCache(myOffset + 2, "flush");
	myHasChanges = false;
}

std::string ZLCachedMemoryAllocator::makeFileName(std::size_t index, const std::string& from) {
	std::string name(myDirectoryName);
	name.append("/");
	ZLStringUtil::appendNumber(name, index);
	return name.append(".").append(myFileExtension);
}

void ZLCachedMemoryAllocator::writeCache(std::size_t blockLength, const std::string& from) {
	if (myFailed || myPool.empty()) {
		return;
	}

	LogUtil::print("解析缓存流程", "writeCache %s", std::to_string(blockLength) + " " + from);

	const std::size_t index = myPool.size() - 1;
	const std::string fileName = makeFileName(index, from);
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
 *
 * 对应新实现allocateBeta()
 */
char *ZLCachedMemoryAllocator::allocate(CurProcessFile& currentFile, std::size_t size, const std::string& from) {
//	LogUtil::print("解析缓存流程", from + " -- allocate %s " + myFileExtension, std::to_string(size));
	myHasChanges = true;
	if (myPool.empty()) {
		myCurrentRowSize = std::max(myRowSize, size + 2 + sizeof(char*));
		myPool.push_back(new char[myCurrentRowSize]);
	} else if (myOffset + size + 2 + sizeof(char*) > myCurrentRowSize) {
		LogUtil::print("解析缓存流程",
					   "%s 超过maxSize = " + std::to_string(myCurrentRowSize) + ", 写入cache",
					   std::to_string(myOffset + size + 2 + sizeof(char *)));
		// 当前读取的char[]长度已经超过了最大长度myCurrentRowSize
		myCurrentRowSize = std::max(myRowSize, size + 2 + sizeof(char *));
		char *row = new char[myCurrentRowSize];

		// ptr就是myLastEntryStart, 指向myPool末端的char[] row
		char *ptr = myPool.back() + myOffset;
		*ptr++ = 0;
		*ptr++ = 0;
		// 把char[]的地址复制到myPool末端
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

/**
 *
 * 对应新实现reallocateLastBeta()
 */
char *ZLCachedMemoryAllocator::reallocateLast(CurProcessFile& currentFile, char *ptr, std::size_t newSize, const std::string& from) {
	LogUtil::LOGI("解析缓存流程", "reallocateLast %s", std::to_string(newSize));
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
		writeCache(oldOffset + 2, "reallocateLast");
		// 缓存写入完毕了, 加一个新的char[]到myPool中
		myPool.push_back(row);
		// char[]的offset从newSize开始
		myOffset = newSize;
		return row;
	}
}

/******************************************************* 新实现 *******************************************************/
/**
 * 在一个文件解析完毕之后调用, 缓存myPool解析数据, 然后准备下一个文件的char[]数组
 * 一个文件对应多个解析缓存文件
 * @return *表示返回一个指针
 */
void ZLCachedMemoryAllocator::flushCurrentFile(CurProcessFile& currentFile) {
    myHasChanges = true;

	myCurrentRowSizeBeta = myRowSize;
	char *row = new char[myCurrentRowSizeBeta];
	// ptr就是myLastEntryStart, 指向myPool末端的char[] row
	char *ptr = myPoolBeta.back() + myOffsetBeta;
	*ptr++ = 0;
	*ptr++ = 0;
	// 把char[]的地址复制到myPool末端
	std::memcpy(ptr, &row, sizeof(char*));
	writeCacheBeta(myOffsetBeta + 2, currentFile);
	// 缓存写入完毕了, 加一个新的char[]到myPool中
	myPoolBeta.push_back(row);
	// 重新开始计算char[]的offset
	myOffsetBeta = 0;
}

// TODO 需要改成在一个xhtml文件内容全部解析完毕时，进行一次writeCache操作, 此操作可以实现1个xhtml文件对应1个或多个本地缓存.ncahce文件
char *ZLCachedMemoryAllocator::allocateBeta(CurProcessFile& currentFile, std::size_t size, const std::string& from) {
//	LogUtil::print("解析缓存流程", from + " -- allocateBeta %s " + myFileExtension, std::to_string(size));
	myHasChanges = true;
	if (myPoolBeta.empty()) {
		myCurrentRowSizeBeta = std::max(myRowSize, size + 2 + sizeof(char *));
		myPoolBeta.push_back(new char[myCurrentRowSizeBeta]);
	} else if (myOffsetBeta + size + 2 + sizeof(char*) > myCurrentRowSizeBeta) {
		LogUtil::print("解析缓存流程beta",
					   "%s 超过maxSize = " + std::to_string(myCurrentRowSizeBeta) + ", 写入cache",
					   std::to_string(myOffsetBeta + size + 2 + sizeof(char *)));
		// 当前读取的char[]长度已经超过了最大长度myCurrentRowSize
		myCurrentRowSizeBeta = std::max(myRowSize, size + 2 + sizeof(char *));
		char *row = new char[myCurrentRowSizeBeta];

        // ptr就是myLastEntryStart, 指向myPool末端的char[] row
        char *ptr = myPoolBeta.back() + myOffsetBeta;
        *ptr++ = 0;
        *ptr++ = 0;
        std::memcpy(ptr, &row, sizeof(char*));
        writeCacheBeta(myOffsetBeta + 2, currentFile);
        myPoolBeta.push_back(row);
        myOffsetBeta = 0;
    }
    char *endPtr = myPoolBeta.back() + myOffsetBeta;
    myOffsetBeta += size;
    return endPtr;
}

char *ZLCachedMemoryAllocator::reallocateLastBeta(CurProcessFile& currentFile, char *ptr, std::size_t newSize) {
//    LogUtil::print("解析缓存流程beta", "reallocateLastBeta %s", std::to_string(newSize));
    myHasChanges = true;
    const std::size_t oldOffset = ptr - myPoolBeta.back();
    // sizeof(char*) 返回字符型指针所占内存的大小, 值为4
    if (oldOffset + newSize + 2 + sizeof(char*) <= myCurrentRowSize) {
        myOffsetBeta = oldOffset + newSize;
        return ptr;
    } else {
		myCurrentRowSizeBeta = std::max(myRowSize, newSize + 2 + sizeof(char*));
        char *row = new char[myCurrentRowSizeBeta];
        std::memcpy(row, ptr, myOffsetBeta - oldOffset);

        *ptr++ = 0;
        *ptr++ = 0;
        std::memcpy(ptr, &row, sizeof(char*));
		writeCacheBeta(oldOffset + 2, currentFile);
        // 缓存写入完毕了, 加一个新的char[]到myPool中
        myPoolBeta.push_back(row);
        // char[]的offset从newSize开始
        myOffsetBeta = newSize;
        return row;
    }
}

void ZLCachedMemoryAllocator::writeCacheBeta(std::size_t blockLength, CurProcessFile& currentFile) {
    if (myFailed || myPoolBeta.empty()) {
        return;
    }

    const std::size_t index = myPoolBeta.size() - 1;
    const std::string fileName = makeFileNameBeta(index, currentFile);
    LogUtil::LOGI("解析缓存流程", "writeCache, name = %s", fileName);

    ZLFile file(fileName);
    shared_ptr<ZLOutputStream> stream = file.outputStream();
    if (stream.isNull() || !stream->open()) {
        myFailed = true;
        return;
    }
    stream->write(myPoolBeta[index], blockLength);
    stream->close();
}

std::string ZLCachedMemoryAllocator::makeFileNameBeta(std::size_t index, CurProcessFile& currentFile) {
	std::string name(myDirectoryName);
	// 缓存文件名: xhtml文件名 + 该文件缓存文件数量 + myPool中的idx + 后缀(.ncache)
	// eg: part0000+1_0.cache
	// +1代表只有一个缓存文件, 由于一个.xhtml文件过大导致有多个缓存文件
	currentFile.cacheFileCount++;
	name.append("/").append(currentFile.fileName).append("+");
	ZLStringUtil::appendNumber(name, currentFile.cacheFileCount);
	name.append("_");
	ZLStringUtil::appendNumber(name, index);
	return name.append(".").append(myFileExtension);
}
