package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.util.ZLColor

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName PaintBlock
 * @Date 4/19/23, 11:25 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */

enum class BlockType {
    TEXT,
    RECTANGLE
}

sealed class PaintBlock(val blockType: Int) {

    data class TextBlock(
        val color: ZLColor? = null,
        val text: String,
        val x: Int,
        val y: Int,
    ) : PaintBlock(BlockType.TEXT.ordinal)

    data class RectangleBlock(
        val color: ZLColor,
        val x0: Int,
        val y0: Int,
        val x1: Int,
        val y1: Int
    ) : PaintBlock(BlockType.RECTANGLE.ordinal)
}