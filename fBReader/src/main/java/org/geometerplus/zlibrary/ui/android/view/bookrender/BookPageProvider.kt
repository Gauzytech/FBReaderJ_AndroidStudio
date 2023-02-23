package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import android.graphics.Canvas
import org.geometerplus.zlibrary.core.util.SystemInfo
import org.geometerplus.zlibrary.core.view.ZLView
import org.geometerplus.zlibrary.core.view.ZLViewEnums.PageIndex
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext
import org.geometerplus.zlibrary.ui.android.view.bookrender.model.ContentPageResult

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName BookPageProvider
 * @Date 4/24/22, 12:06 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
class BookPageProvider(private val mySystemInfo: SystemInfo) {
    /**
     * 在Bitmap上绘制
     * 创建一个空白的canvas, 将当前页的内容绘制在canvas上面
     *
     * @param bitmap Bitmap
     * @param index  页面索引
     */
    fun drawOnBitmap(
        view: ZLView,
        bitmap: Bitmap?,
        index: PageIndex?,
        width: Int,
        height: Int,
        mainAreaHeight: Int,
        verticalScrollbarWidth: Int
    ) {
        val context = ZLAndroidPaintContext(
            mySystemInfo,  // 以bitmap类为参数创建一个Canvas类
            // 代码通过Canvas类对bitmap类进行操作
            Canvas(bitmap!!),
            ZLAndroidPaintContext.Geometry(
                width,
                height,
                width,
                mainAreaHeight,
                0,
                0
            ),
            if (view.isScrollbarShown) verticalScrollbarWidth else 0
        )
        view.paint(context, index)
    }

    fun processPageData(
        view: ZLView,
        pageIdx: PageIndex?,
        width: Int,
        height: Int,
        mainAreaHeight: Int,
        verticalScrollbarWidth: Int
    ): ContentPageResult {
        val context = ZLAndroidPaintContext(
            mySystemInfo,  // 以bitmap类为参数创建一个Canvas类
            // 代码通过Canvas类对bitmap类进行操作
            null,
            ZLAndroidPaintContext.Geometry(
                width,
                height,
                width,
                mainAreaHeight,
                0,
                0
            ),
            if (view.isScrollbarShown) verticalScrollbarWidth else 0
        )
        return view.processPage(context, pageIdx)
    }

    /** 准备上一页/下一页 */
    fun preparePage(
        view: ZLView,
        index: PageIndex?,
        width: Int,
        height: Int,
        mainAreaHeight: Int,
        verticalScrollbarWidth: Int
    ) {
        val context = ZLAndroidPaintContext(
            mySystemInfo,
            Canvas(),
            ZLAndroidPaintContext.Geometry(
                width,
                height,
                width,
                mainAreaHeight,
                0,
                0
            ),
            if (view.isScrollbarShown) verticalScrollbarWidth else 0
        )

        // 准备上一页/下一页
        view.preparePage(context, index)
    }
}