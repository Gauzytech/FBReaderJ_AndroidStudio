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

package org.geometerplus.fbreader.fbreader;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.geometerplus.fbreader.network.NetworkImage;
import org.geometerplus.fbreader.network.opds.OPDSBookItem;
import org.geometerplus.fbreader.network.urlInfo.UrlInfo;
import org.geometerplus.zlibrary.core.image.ZLImageData;
import org.geometerplus.zlibrary.core.image.ZLImageManager;
import org.geometerplus.zlibrary.core.image.ZLImageProxy;
import org.geometerplus.zlibrary.core.library.ZLibrary;
import org.geometerplus.zlibrary.core.util.ZLColor;
import org.geometerplus.zlibrary.core.view.ZLPaintContext;
import org.geometerplus.zlibrary.text.view.ExtensionElement;
import org.geometerplus.zlibrary.text.view.ZLTextElementArea;
import org.geometerplus.zlibrary.text.view.ZLTextHyperlink;
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ElementPaintData;

public final class BookElement extends ExtensionElement {
	private final FBView myView;

	private OPDSBookItem myItem;
	private NetworkImage myCover;

	BookElement(FBView view) {
		super("BookElement");
		myView = view;
	}

	public void setData(OPDSBookItem item) {
		final String bookUrl = item.getUrl(UrlInfo.Type.Book);
		String coverUrl = item.getUrl(UrlInfo.Type.Image);
		if (coverUrl == null) {
			coverUrl = item.getUrl(UrlInfo.Type.Thumbnail);
		}
		if (bookUrl == null || coverUrl == null) {
			myItem = null;
			myCover = null;
		} else {
			myItem = item;
			myCover = new NetworkImage(coverUrl, myView.Application.SystemInfo);
			myCover.synchronize();
		}
	}

	public boolean isInitialized() {
		return myItem != null && myCover != null;
	}

	public OPDSBookItem getItem() {
		return myItem;
	}

	public @Nullable
	ZLImageData getImageData() {
		if (myCover == null) {
			return null;
		}
		return ZLImageManager.Instance().getImageData(myCover);
	}

	private @Nullable
	String getImageUrl() {
		if (myCover == null) {
			return null;
		}
		return myCover.Url;
	}

	@Override
	protected int getWidth() {
		// 1/\phi (= 0.618) inch width + 1/10 inch left & right margin
		return Math.min(ZLibrary.Instance().getDisplayDPI() * 818 / 1000, myView.getTextColumnWidth());
	}

	@Override
	protected int getHeight() {
		// 1 inch height + 1/15 inch top & bottom margin
		return ZLibrary.Instance().getDisplayDPI() * 17 / 15;
	}

	@Override
	protected void draw(@NonNull ZLPaintContext context, @NonNull ZLTextElementArea area) {
		final int vMargin = ZLibrary.Instance().getDisplayDPI() / 15;
		final int hMargin = ZLibrary.Instance().getDisplayDPI() / 10;
		final ZLImageData imageData = getImageData();
		if (imageData != null) {
			context.drawImage(
				area.XStart + hMargin, area.YEnd - vMargin,
				imageData,
				new ZLPaintContext.Size(
					area.XEnd - area.XStart - 2 * hMargin + 1,
					area.YEnd - area.YStart - 2 * vMargin + 1
				),
				ZLPaintContext.ScalingType.FitMaximum,
				ZLPaintContext.ColorAdjustingMode.NONE
			);
		} else {
			final ZLColor color = myView.getTextColor(ZLTextHyperlink.NO_LINK);
			context.setLineColor(color);
			context.setFillColor(color, 0x33);
			final int xStart = area.XStart + hMargin;
			final int xEnd = area.XEnd - hMargin;
			final int yStart = area.YStart + vMargin;
			final int yEnd = area.YEnd - vMargin;
			context.fillRectangle(xStart, yStart, xEnd, yEnd);
			context.drawLine(xStart, yStart, xStart, yEnd);
			context.drawLine(xStart, yEnd, xEnd, yEnd);
			context.drawLine(xEnd, yEnd, xEnd, yStart);
			context.drawLine(xEnd, yStart, xStart, yStart);
		}
	}

	@Override
	protected ElementPaintData.Extension.Builder getDrawData(@NonNull ZLPaintContext context, @NonNull ZLTextElementArea area) {
		final int vMargin = ZLibrary.Instance().getDisplayDPI() / 15;
		final int hMargin = ZLibrary.Instance().getDisplayDPI() / 10;
		final String imageUrl = getImageUrl();

		if (imageUrl != null) {
			ElementPaintData.Extension.Builder extensionBuilder = new ElementPaintData.Extension.Builder();
			ElementPaintData.Image imagePaintData = new ElementPaintData.Image.Builder()
					.sourceType(ZLImageProxy.SourceType.NETWORK.ordinal())
					.left(area.XStart + hMargin)
					.top(area.YEnd - vMargin)
					.imageSrc(imageUrl)
					.maxSize(new ZLPaintContext.Size(
							area.XEnd - area.XStart - 2 * hMargin + 1,
							area.YEnd - area.YStart - 2 * vMargin + 1
					))
					.scalingType(ZLPaintContext.ScalingType.FitMaximum.ordinal())
					.adjustingModeForImages(ZLPaintContext.ColorAdjustingMode.NONE.ordinal())
					.build();
			return extensionBuilder.imagePaintData(imagePaintData);

		} else {
			ElementPaintData.Video.Builder videoPaintDataBuilder = new ElementPaintData.Video.Builder();

			final ZLColor color = myView.getTextColor(ZLTextHyperlink.NO_LINK);
//			context.setLineColor(color);
			videoPaintDataBuilder.lineColor(color);
//			context.setFillColor(color, 0x33);
			final int xStart = area.XStart + hMargin;
			final int xEnd = area.XEnd - hMargin;
			final int yStart = area.YStart + vMargin;
			final int yEnd = area.YEnd - vMargin;
			videoPaintDataBuilder.xStart(xStart)
					.xEnd(xEnd)
					.yStart(yStart)
					.yEnd(yEnd);
			ElementPaintData.Extension.Builder extensionBuilder = new ElementPaintData.Extension.Builder();
			return extensionBuilder
					.videoPaintData(videoPaintDataBuilder.build());
//			context.fillRectangle(xStart, yStart, xEnd, yEnd);
//			context.drawLine(xStart, yStart, xStart, yEnd);
//			context.drawLine(xStart, yEnd, xEnd, yEnd);
//			context.drawLine(xEnd, yEnd, xEnd, yStart);
//			context.drawLine(xEnd, yStart, xStart, yStart);
		}
	}
}
