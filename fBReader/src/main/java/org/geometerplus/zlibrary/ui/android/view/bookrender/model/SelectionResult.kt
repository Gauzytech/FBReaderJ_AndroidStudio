package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.library.ZLibrary
import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.text.view.ZLTextSelection

sealed class SelectionResult {

    /**
     * 选中了文字内容
     * @param selectionStartY 选中文字第一行顶部的y坐标
     * @param selectionEndY 选中文字最后一行底部的y坐标
     */
    data class ShowMenu(val selectionStartY: Int, val selectionEndY: Int) : SelectionResult()

    /**
     * 选中了除文字之外的内容, 比如选中了图片，视频，超链接.
     */
    object NoMenu : SelectionResult()

    /**
     * 没有选中内容
     */
    object NoOp : SelectionResult()

    object OpenDirectory : SelectionResult()
    object OpenImage : SelectionResult()

    /**
     * @param blocks 高亮区域
     */
    data class Highlight(
        val blocks: List<HighlightBlock>,
        val leftSelectionCursor: SelectionCursor? = null,
        val rightSelectionCursor: SelectionCursor? = null
    ) : SelectionResult()

    companion object {
        fun createHighlight(block: HighlightBlock): Highlight {
            return Highlight(listOf(block))
        }

        fun createHighlight(
            blocks: List<HighlightBlock>,
            cursorColor: ZLColor,
            leftPoint: ZLTextSelection.Point?,
            rightPoint: ZLTextSelection.Point?,
        ): Highlight {
            val dpi = ZLibrary.Instance().displayDPI
            val leftCursor = if (leftPoint != null) SelectionCursor(cursorColor, leftPoint, dpi) else null
            val rightCursor = if (rightPoint != null) SelectionCursor(cursorColor, rightPoint, dpi) else null
            return Highlight(blocks, leftCursor, rightCursor)
        }
    }
}