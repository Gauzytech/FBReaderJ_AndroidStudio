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

package org.geometerplus.fbreader.formats.oeb;

import java.util.Collections;
import java.util.List;

import org.geometerplus.zlibrary.core.encodings.EncodingCollection;
import org.geometerplus.zlibrary.core.encodings.AutoEncodingCollection;
import org.geometerplus.zlibrary.core.filesystem.ZLFile;
import org.geometerplus.zlibrary.core.util.SystemInfo;

import org.geometerplus.fbreader.book.AbstractBook;
import org.geometerplus.fbreader.book.BookUtil;
import org.geometerplus.fbreader.bookmodel.BookModel;
import org.geometerplus.fbreader.formats.BookReadingException;
import org.geometerplus.fbreader.formats.NativeFormatPlugin;

import timber.log.Timber;

public class OEBNativePlugin extends NativeFormatPlugin {
	public OEBNativePlugin(SystemInfo systemInfo) {
		super(systemInfo, "ePub");
	}

	/**
	 * 核心方法入口, 调用super开始解析图书
	 * @param model BookModel, 之后要提供给自定义TextView进行渲染操作
	 */
	@Override
	public void readModel(BookModel model) throws BookReadingException {
		Timber.v("ceshi123, 读取图书并创建model: \n" + model.toString());
		// 创建file对象:
		// AndroidAssetsFile,
		// ZLTarEntryFile,
		// ZLZipEntryFile,
		// ZLPhysicalFile
		final ZLFile file = BookUtil.fileByBook(model.Book);
		Timber.v("ceshi123,  创建bookFile: " + file.getClass().getSimpleName());
		file.setCached(true);
		try {
			// 调用cpp层进行解析, 最终解析的图书数据会全部保存到bookModel.myBookTextModel中
			super.readModel(model);
			model.setLabelResolver(new BookModel.LabelResolver() {
				public List<String> getCandidates(String id) {
					final int index = id.indexOf("#");
					return index > 0
						? Collections.<String>singletonList(id.substring(0, index))
						: Collections.<String>emptyList();
				}
			});
		} finally {
			file.setCached(false);
		}
	}

	@Override
	public EncodingCollection supportedEncodings() {
		return new AutoEncodingCollection();
	}

	@Override
	public void detectLanguageAndEncoding(AbstractBook book) {
		book.setEncoding("auto");
	}

	@Override
	public String readAnnotation(ZLFile file) {
		file.setCached(true);
		try {
			return new OEBAnnotationReader().readAnnotation(getOpfFile(file));
		} catch (BookReadingException e) {
			return null;
		} finally {
			file.setCached(false);
		}
	}

	private ZLFile getOpfFile(ZLFile oebFile) throws BookReadingException {
		Timber.v("ceshi123, 读取opf文件");
		if ("opf".equals(oebFile.getExtension())) {
			return oebFile;
		}

		// 第一步
		// 这个方法的参数oebFile参数是Book类的File属性, 最终这个方法会返回一个代表container.xml文件的ZLZipEntryFile类。
		// 这个文件的作用就是“标明了.opf文件的位置”
		final ZLFile containerInfoFile = ZLFile.createFile(oebFile, "META-INF/container.xml");
		if (containerInfoFile.exists()) {
			// 第二步
			final ContainerFileReader reader = new ContainerFileReader();
			reader.readQuietly(containerInfoFile);
			final String opfPath = reader.getRootPath();
			// 通过rootPath获得opf文件
			if (opfPath != null) {
				return ZLFile.createFile(oebFile, opfPath);
			}
		}

		for (ZLFile child : oebFile.children()) {
			if (child.getExtension().equals("opf")) {
				return child;
			}
		}
		throw new BookReadingException("opfFileNotFound", oebFile);
	}

	@Override
	public int priority() {
		return 0;
	}
}
