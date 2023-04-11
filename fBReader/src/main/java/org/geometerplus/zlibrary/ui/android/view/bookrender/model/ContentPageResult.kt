package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import com.google.gson.annotations.SerializedName
import org.geometerplus.zlibrary.text.view.style.ZLTextStyleCollection
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext.Geometry

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName ContentPaintData
 * @Date 2/22/23, 11:26 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
sealed class ContentPageResult {

    data class Paint(
        @SerializedName("text_style_collection") val textStyleCollection: ZLTextStyleCollection,
        @SerializedName("line_paint_data_list") val linePaintDataList: List<LinePaintData>,
        @SerializedName("geometry") val geometry: Geometry
    ) : ContentPageResult()

    object NoOp : ContentPageResult()
}