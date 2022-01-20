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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Collections;

public final class CachedCharStorage {
	// char数组里面的元素就代表一个.xhtml文件的文本信息与标签信息
	// 每个char[]称为block
	protected final ArrayList<WeakReference<char[]>> myArray = new ArrayList<>();

	private final String myDirectoryName;
	private final String myFileExtension;

	public CachedCharStorage(String directoryName, String fileExtension, int blocksNumber) {
		myDirectoryName = directoryName + '/';
		myFileExtension = '.' + fileExtension;
		myArray.addAll(Collections.nCopies(blocksNumber, new WeakReference<char[]>(null)));
	}

	private String fileName(int index) {
		return myDirectoryName + index + myFileExtension;
	}

	public int size() {
		return myArray.size();
	}

	private String exceptionMessage(int index, String extra) {
		final StringBuilder buffer = new StringBuilder("Cannot read " + fileName(index));
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
	 * ”所以当前在内存中的char数组不一定会包含需要显示的数组，
	 * 如果不包含需要显示的数组就需要根据ZLTextWritablePlainModel类的myStartEntryIndices属性找到对应的char数组
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
		char[] block = myArray.get(index).get();
		// 如果当前内存中的char[]不包含需要显示的段落,
		// 就从已经持久化的char[]中需找对应的那一个，读入内存
		if (block == null) {
			try {
				File file = new File(fileName(index));
				int size = (int) file.length();
				if (size < 0) {
					throw new CachedCharStorageException(exceptionMessage(index, "size = " + size));
				}
				block = new char[size / 2];
				InputStreamReader reader = new InputStreamReader(new FileInputStream(file), "UTF-16LE");
				// 将指定的已经持久化的char[]读入内存block中
				final int totalRead = reader.read(block);
				if (totalRead != block.length) {
					throw new CachedCharStorageException(exceptionMessage(index, "; " + totalRead + " != " + block.length));
				}
				reader.close();
			} catch (IOException e) {
				throw new CachedCharStorageException(exceptionMessage(index, null), e);
			}
			// 将读取的char[]缓存到myArray
			myArray.set(index, new WeakReference<>(block));
		}
		return block;
	}
}
