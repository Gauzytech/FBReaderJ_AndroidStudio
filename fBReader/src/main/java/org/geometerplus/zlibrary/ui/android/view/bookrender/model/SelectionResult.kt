package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import com.google.gson.annotations.SerializedName
import org.geometerplus.zlibrary.core.library.ZLibrary
import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.text.view.ZLTextSelection

enum class ResultType {
    CLEAR_ALL,
    DIRECTORY,
    HIGHLIGHT,
    NO_ACTION_MENU,
    NO_OP,
    HYPER_LINK,
    ACTION_MENU,
    IMAGE,
    VIDEO,
}

sealed class SelectionResult(val resultType: Int) {

    /**
     * @param paintBlocks 高亮区域
     * @param leftSelectionCursor 左侧小耳朵坐标
     * @param rightSelectionCursor 右侧小耳朵坐标
     */
    data class Highlight(
        @SerializedName("paint_blocks") val paintBlocks: List<PaintBlock.HighlightBlock>,
        @SerializedName("left_cursor") val leftSelectionCursor: SelectionCursor? = null,
        @SerializedName("right_cursor") val rightSelectionCursor: SelectionCursor? = null
    ) : SelectionResult(ResultType.HIGHLIGHT.ordinal)

    /** 选中了除文字之外的内容, 比如选中了图片，视频，超链接. */
    object NoActionMenu : SelectionResult(ResultType.NO_ACTION_MENU.ordinal)

    /** 没有选中内容 */
    object NoOp : SelectionResult(ResultType.NO_OP.ordinal)

    object OpenDirectory : SelectionResult(ResultType.DIRECTORY.ordinal)
    object OpenHyperLink : SelectionResult(ResultType.HYPER_LINK.ordinal)
    object OpenImage : SelectionResult(ResultType.IMAGE.ordinal)
    object OpenVideo : SelectionResult(ResultType.VIDEO.ordinal)

    /**
     * 选中了文字内容
     * @param selectionStartY 选中文字第一行顶部的y坐标
     * @param selectionEndY 选中文字最后一行底部的y坐标
     */
    data class ActionMenu(
        @SerializedName("selection_start_y") val selectionStartY: Int,
        @SerializedName("selection_end_y") val selectionEndY: Int
    ) :
        SelectionResult(ResultType.ACTION_MENU.ordinal)

    object ClearAll : SelectionResult(ResultType.CLEAR_ALL.ordinal)

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