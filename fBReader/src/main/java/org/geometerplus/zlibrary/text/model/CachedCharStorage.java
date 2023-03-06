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

import androidx.annotation.VisibleForTesting;

import org.geometerplus.DebugHelper;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Collections;

import timber.log.Timber;

public final class CachedCharStorage {
	// char数组里面的元素就代表一个.xhtml文件的文本信息与标签信息
	// 每个char[]称为block
	// 对应cpp中的mPool, 每个char[]在cpp中称为row
	protected final ArrayList<WeakReference<char[]>> myArray = new ArrayList<>();

	private final String root;
	private final String myDirectoryName;
	private final String myFileExtension;

	public CachedCharStorage(String directoryName, String fileExtension, int blocksNumber) {
		Timber.v("解析缓存流程, 创建: dir = %s ext = %s blocksNumber = %d", directoryName, fileExtension, blocksNumber);
		root = directoryName.substring(0, directoryName.lastIndexOf("/"));
		myDirectoryName = directoryName + '/';
		myFileExtension = '.' + fileExtension;
		myArray.addAll(Collections.nCopies(blocksNumber, new WeakReference<>(null)));
	}

	private String makeFileName(int index) {
		return myDirectoryName + index + myFileExtension;
	}

	public int size() {
		return myArray.size();
	}

	/**
	 * 获得私有目录中图片缓存目录
	 * @return eg: /storage/emulated/0/Android/data/org.geometerplus.zlibrary.ui.android/image_cache
	 */
	public String getImageCacheDirectory() {
		return root + File.separator + "image_cache";
	}

	private String exceptionMessage(int index, String extra) {
		final StringBuilder buffer = new StringBuilder("Cannot read " + makeFileName(index));
		if (extra != null) {
			buffer.append("; ").append(extra);
		}
		buffer.append("\n");
		try {
			final File dir = new File(myDirectoryName);
			buffer.append("ts = ").append(System.currentTimeMillis()).append("\n");
			buffer.append("dir exists = ").append(dir.exists()).append("\n");
			for (File f : dir.listFiles()) {
				buffer.append(f.getName()).append(" :: ");
				buffer.append(f.length()).append(" :: ");
				buffer.append(f.lastModified()).append("\n");
			}
		} catch (Throwable t) {
			buffer.append(t.getClass().getName());
			buffer.append("\n");
			buffer.append(t.getMessage());
		}
		return buffer.toString();
	}

	/**
	 * char数组的长度最长不会超过这个长度（65536），一旦超过这个长度，代码就会新建一个char数组，同时旧的数组会被持久化以便以后再用。
	 * 所以当前在内存中的char数组不一定会包含需要显示的数组，
	 * 如果不包含需要显示的数组就需要根据{@link ZLTextPlainModel}类的myStartEntryIndices属性找到对应的char数组
	 *
	 * 读取本地持久化数组的方法
	 *
	 * @param index myStartEntryIndices中的dataIndex,
	 * @return dataIndex对应的段落部分的char[]
	 */
	public char[] block(int index) {
		if (index < 0 || index >= myArray.size()) {
			return null;
		}
		char[] parseFileData = myArray.get(index).get();
		// 如果当前内存中的char[]不包含需要显示的段落,
		// 就从已经持久化的char[]中需找对应的那一个，读入内存
		if (parseFileData == null) {
			try {
				File file = new File(makeFileName(index));
				Timber.v("解析缓存流程, 读取解析缓存: %s", file.getName());
				int size = (int) file.length();
				if (size < 0) {
					throw new CachedCharStorageException(exceptionMessage(index, "size = " + size));
				}
				parseFileData = new char[size / 2];
				InputStreamReader reader = new InputStreamReader(new FileInputStream(file), "UTF-16LE");
				// 将指定的已经持久化的char[]读入内存block中
				final int totalRead = reader.read(parseFileData);
				if (totalRead != parseFileData.length) {
					throw new CachedCharStorageException(exceptionMessage(index, "; " + totalRead + " != " + parseFileData.length));
				}
				reader.close();

				// 测试, 输出utf8解析文件缓存
				if (DebugHelper.ENABLE_FLUTTER) {
					outputDebugBlockFile(index, parseFileData.clone(), false);
				}
			} catch (IOException e) {
				throw new CachedCharStorageException(exceptionMessage(index, null), e);
			}
			// 将读取的char[]缓存到myArray
			myArray.set(index, new WeakReference<>(parseFileData));
		}
		return parseFileData;
	}

	@VisibleForTesting
	private void outputDebugBlockFile(int index, char[] testBlock, boolean output) throws IOException {
		if (!output) return;
		String root = "/storage/emulated/0/Android/data/org.geometerplus.zlibrary.ui.android";
		File dir = new File(root + "/utf8test");
		if (!dir.exists()) {
			dir.mkdirs();
		}
		OutputStreamWriter writer = new OutputStreamWriter(new FileOutputStream(root + "/utf8test/" + index + "_utf8.txt"), "UTF-8");
		writer.write(testBlock);
		writer.close();
	}
}
