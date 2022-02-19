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
import androidx.collection.LruCache;

import org.geometerplus.zlibrary.text.model.ZLTextModel;

final class CursorManager extends LruCache<Integer, ZLTextParagraphCursor> {
	private final ZLTextModel textModel;
	final ExtensionElementManager extensionManager;

	/**
	 * @param extManager FbView中的bookElementManager, 用来加载一些图书信息: OPDS
	 */
	public CursorManager(ZLTextModel model, ExtensionElementManager extManager) {
		super(200); // max 200 cursors in the cache
		textModel = model;
		extensionManager = extManager;
	}

	/**
	 * LRU value的创建方法
	 *
	 * 一组p标签就代表一个段落(Paragraph),
	 * ZLTextParagraphCursor对应一个paragraph的解析信息
	 *
	 * @param index 缓存解析文件的index
	 */
	@Override
	protected ZLTextParagraphCursor create(@NonNull Integer index) {
		return new ZLTextParagraphCursor(this, textModel, index);
	}
}
