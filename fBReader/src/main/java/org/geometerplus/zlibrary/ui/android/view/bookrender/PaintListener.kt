package org.geometerplus.zlibrary.ui.android.view.bookrender

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName PaintListener
 * @Date 8/25/22, 11:10 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
interface PaintListener {

    /**
     * 重新绘制当前页bitmap, 并传给flutter重新渲染
     */
    fun repaint(shouldRepaint: Boolean)
}