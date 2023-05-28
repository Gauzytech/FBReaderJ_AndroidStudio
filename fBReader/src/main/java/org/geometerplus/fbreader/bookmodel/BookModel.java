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

package org.geometerplus.fbreader.bookmodel;

import org.geometerplus.fbreader.book.Book;
import org.geometerplus.fbreader.formats.BookReadingException;
import org.geometerplus.fbreader.formats.BuiltinFormatPlugin;
import org.geometerplus.fbreader.formats.FormatPlugin;
import org.geometerplus.zlibrary.core.fonts.FileInfo;
import org.geometerplus.zlibrary.core.fonts.FontEntry;
import org.geometerplus.zlibrary.core.fonts.FontManager;
import org.geometerplus.zlibrary.core.image.ZLImage;
import org.geometerplus.zlibrary.text.model.CachedCharStorage;
import org.geometerplus.zlibrary.text.model.ZLTextModel;
import org.geometerplus.zlibrary.text.model.ZLTextPlainModel;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import timber.log.Timber;

public final class BookModel {

	/**
	 * 1. 创建book渲染数据model第一步
	 */
	public static BookModel createModel(Book book, FormatPlugin plugin) throws BookReadingException {
		Timber.v("图书解析流程, 开始解析图书, 创建图书model, %s",  plugin.getClass().getSimpleName());
		// 只有FB2NativePlugin和OEBNativePlugin才会执行cpp层解析
		if (!(plugin instanceof BuiltinFormatPlugin)) {
			throw new BookReadingException(
					"unknownPluginType", null, new String[]{String.valueOf(plugin)}
			);
		}

		// 保存图书基本信息: title, path, encoding,
		final BookModel model = new BookModel(book);
		// 图书解析入口, 调用cpp层开始图书解析
		((BuiltinFormatPlugin) plugin).readModel(model);
		return model;
	}

	public final Book Book;
	public final TOCTree TOCTree = new TOCTree();
	public final FontManager FontManager = new FontManager();

	protected CachedCharStorage myInternalHyperlinks;
	protected final HashMap<String,ZLImage> myImageMap = new HashMap<>();
	protected ZLTextModel myBookTextModel;
	protected final HashMap<String,ZLTextModel> myFootnotes = new HashMap<>();

	public static final class Label {
		public final String ModelId;
		public final int ParagraphIndex;

		public Label(String modelId, int paragraphIndex) {
			ModelId = modelId;
			ParagraphIndex = paragraphIndex;
		}
	}

	protected BookModel(Book book) {
		Book = book;
	}

	public interface LabelResolver {
		List<String> getCandidates(String id);
	}

	private LabelResolver myResolver;

	public void setLabelResolver(LabelResolver resolver) {
		myResolver = resolver;
	}

	/**
	 * 获得footNote/超链接数据
	 */
	public Label getLabel(String id) {
		Timber.v("超链接, id = %s", id);
		Label label = getLabelInternal(id);
		if (label == null && myResolver != null) {
			for (String candidate : myResolver.getCandidates(id)) {
				label = getLabelInternal(candidate);
				if (label != null) {
					break;
				}
			}
		}
		return label;
	}

	public ZLTextModel getTextModel() {
		return myBookTextModel;
	}

	public ZLTextModel getFootnoteModel(String id) {
		return myFootnotes.get(id);
	}

	public void addImage(String id, ZLImage image) {
		myImageMap.put(id, image);
	}

	private Label getLabelInternal(String id) {
		final int len = id.length();
		final int size = myInternalHyperlinks.size();

		for (int i = 0; i < size; ++i) {
			final char[] block = myInternalHyperlinks.block(i);
			for (int offset = 0; offset < block.length; ) {
				final int labelLength = block[offset++];
				if (labelLength == 0) {
					break;
				}
				final int idLength = (int)block[offset + labelLength];
				if (labelLength != len || !id.equals(new String(block, offset, labelLength))) {
					offset += labelLength + idLength + 3;
					continue;
				}
				offset += labelLength + 1;
				final String modelId = (idLength > 0) ? new String(block, offset, idLength) : null;
				offset += idLength;
				final int paragraphNumber = (int)block[offset] + (((int)block[offset + 1]) << 16);
				return new Label(modelId, paragraphNumber);
			}
		}
		return null;
	}

	/********************************** 以下为cpp调用java的方法 *******************************/
	public void registerFontFamilyList(String[] families) {
		FontManager.index(Arrays.asList(families));
	}

	public void registerFontEntry(String family, FontEntry entry) {
		FontManager.Entries.put(family, entry);
	}

	public void registerFontEntry(String family, FileInfo normal, FileInfo bold, FileInfo italic, FileInfo boldItalic) {
		registerFontEntry(family, new FontEntry(family, normal, bold, italic, boldItalic));
	}

	public ZLTextModel createTextModel(
			String id, String language, int paragraphsNumber,
			int[] entryIndices, int[] entryOffsets,
			int[] paragraphLenghts, int[] textSizes, byte[] paragraphKinds,
			String directoryName, String fileExtension, int blocksNumber
	) {
		return new ZLTextPlainModel(
				id, language, paragraphsNumber,
				entryIndices, entryOffsets,
				paragraphLenghts, textSizes, paragraphKinds,
				directoryName, fileExtension, blocksNumber, myImageMap, FontManager
		);
	}

	public void setBookTextModel(ZLTextModel model) {
		Timber.v("cpp解析打印, cpp调用java方法");
		myBookTextModel = model;
	}

	public void setFootnoteModel(ZLTextModel model) {
		myFootnotes.put(model.getId(), model);
	}

	public void initInternalHyperlinks(String directoryName, String fileExtension, int blocksNumber) {
		myInternalHyperlinks = new CachedCharStorage(directoryName, fileExtension, blocksNumber);
	}

	private TOCTree myCurrentTree = TOCTree;

	public void addTOCItem(String text, int reference) {
		myCurrentTree = new TOCTree(myCurrentTree);
		myCurrentTree.setText(text);
		myCurrentTree.setReference(myBookTextModel, reference);
	}

	public void leaveTOCItem() {
		myCurrentTree = myCurrentTree.Parent;
		if (myCurrentTree == null) {
			myCurrentTree = TOCTree;
		}
	}
	/********************************** 以上为cpp调用java的方法 *******************************/

	@Override
	public String toString() {
		return "BookModel{" +
				"\nBook=" + Book +
				", \nTOCTree=" + TOCTree +
				", \nFontManager=" + FontManager +
				", \nmyInternalHyperlinks=" + myInternalHyperlinks +
				", \nmyImageMap=" + myImageMap +
				", \nmyBookTextModel=" + myBookTextModel +
				", \nmyFootnotes=" + myFootnotes +
				", \nmyResolver=" + myResolver +
				", \nmyCurrentTree=" + myCurrentTree +
				'}';
	}
}
