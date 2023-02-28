package org.geometerplus.zlibrary.ui.android.view.bookrender.model

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName TextBlock
 * @Date 2/28/23, 12:19 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
data class TextBlock(
    val data: CharArray,
    val offset: Int,
    val length: Int,
    val x: Int,
    val y: Int
) {

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TextBlock) return false

        if (!data.contentEquals(other.data)) return false
        if (offset != other.offset) return false
        if (length != other.length) return false
        if (x != other.x) return false
        if (y != other.y) return false

        return true
    }

    override fun hashCode(): Int {
        var result = data.contentHashCode()
        result = 31 * result + offset
        result = 31 * result + length
        result = 31 * result + x
        result = 31 * result + y
        return result
    }
}