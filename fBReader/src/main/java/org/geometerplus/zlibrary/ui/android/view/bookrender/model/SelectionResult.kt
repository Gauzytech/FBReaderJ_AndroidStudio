package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import com.google.gson.annotations.SerializedName
import org.geometerplus.zlibrary.core.library.ZLibrary
import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.text.view.ZLTextSelection

enum class ResultType {
    HIGHLIGHT,
    DIRECTORY,
    IMAGE,
    VIDEO,
    HYPER_LINK,
    CLEAR,
    MENU,
    NO_MENU,
    NO_OP,
}

sealed class SelectionResult(val resultType: Int) {

    /**
     * 选中了文字内容
     * @param selectionStartY 选中文字第一行顶部的y坐标
     * @param selectionEndY 选中文字最后一行底部的y坐标
     */
    data class ShowMenu(val selectionStartY: Int, val selectionEndY: Int) :
        SelectionResult(ResultType.MENU.ordinal)

    /**
     * 选中了除文字之外的内容, 比如选中了图片，视频，超链接.
     */
    object NoMenu : SelectionResult(ResultType.NO_MENU.ordinal)

    /**
     * 没有选中内容
     */
    object NoOp : SelectionResult(ResultType.NO_OP.ordinal)

    object OpenDirectory : SelectionResult(ResultType.DIRECTORY.ordinal)
    object OpenImage : SelectionResult(ResultType.IMAGE.ordinal)
    object SelectionCleared : SelectionResult(ResultType.CLEAR.ordinal)
    object OpenHyperLink : SelectionResult(ResultType.HYPER_LINK.ordinal)
    object OpenVideo : SelectionResult(ResultType.VIDEO.ordinal)

    /**
     * @param paintBlocks 高亮区域
     */
    data class Highlight(
        @SerializedName("paint_blocks") val paintBlocks: List<PaintBlock.HighlightBlock>,
        @SerializedName("left_cursor") val leftSelectionCursor: SelectionCursor? = null,
        @SerializedName("right_cursor") val rightSelectionCursor: SelectionCursor? = null
    ) : SelectionResult(ResultType.HIGHLIGHT.ordinal)

    companion object {

        @JvmStatic
        fun withHighlight(block: PaintBlock.HighlightBlock): Highlight {
            return Highlight(listOf(block))
        }

        @JvmStatic
        fun withHighlight(
            blocks: List<PaintBlock.HighlightBlock>,
            cursorColor: ZLColor,
            leftPoint: ZLTextSelection.Point?,
            rightPoint: ZLTextSelection.Point?,
        ): Highlight {
            val dpi = ZLibrary.Instance().displayDPI
            val leftCursor =
                if (leftPoint != null) SelectionCursor(cursorColor, leftPoint, dpi) else null
            val rightCursor =
                if (rightPoint != null) SelectionCursor(cursorColor, rightPoint, dpi) else null
            return Highlight(blocks, leftCursor, rightCursor)
        }
    }
}