package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.text.view.ZLTextPage
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext.Geometry

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName ContentPaintData
 * @Date 2/22/23, 11:26 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
sealed class ContentPageResult {

    data class Paint(val linePaintDataList: List<LinePaintData>, val geometry: Geometry) : ContentPageResult()
    object NoOp : ContentPageResult()
}