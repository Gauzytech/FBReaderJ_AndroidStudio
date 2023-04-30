package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.text.view.ZLTextSelection

/**
 * 保存需要绘制高亮区域的坐标, 传回flutter进行绘制
 * @param type 高亮的类型, '1': outline, '2': fill.
 * 见[org.geometerplus.zlibrary.core.view.Hull.DrawMode]
 */
data class HighlightCoord(val type: Int, val xs: IntArray, val ys: IntArray) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is HighlightCoord) return false

        if (!xs.contentEquals(other.xs)) return false
        if (!ys.contentEquals(other.ys)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = xs.contentHashCode()
        result = 31 * result + ys.contentHashCode()
        return result
    }
}


/** 选择小耳朵数据 */
data class SelectionCursor(val color: ZLColor, val point: ZLTextSelection.Point, val dpi: Int)