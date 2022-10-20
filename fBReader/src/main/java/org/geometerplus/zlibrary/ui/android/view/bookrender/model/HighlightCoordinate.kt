package org.geometerplus.zlibrary.ui.android.view.bookrender.model

/**
 * 保存需要绘制高亮区域的坐标, 传回flutter进行绘制
 */
data class HighlightCoordinate(val drawMode: Int, val xs: IntArray, val ys: IntArray) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is HighlightCoordinate) return false

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
