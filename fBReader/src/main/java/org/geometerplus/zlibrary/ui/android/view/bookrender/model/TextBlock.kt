package org.geometerplus.zlibrary.ui.android.view.bookrender.model

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName TextBlock
 * @Date 2/28/23, 12:19 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
data class TextBlock(
    // ASCII code for char
    val data: List<Int>,
    val offset: Int,
    val length: Int,
    val x: Int,
    val y: Int
) {

    companion object {
        @JvmStatic
        fun create(
            data: CharArray, offset: Int, length: Int, x: Int, y: Int
        ): TextBlock {
            return TextBlock(data.map { it.code }, offset, length, x, y)
        }
    }
}