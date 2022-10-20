package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.util.ZLColor

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
    object None : SelectionResult()

    /**
     * @param highlightType 高亮的类型：文字高亮/轮廓高亮, 见[org.geometerplus.zlibrary.core.view.Hull.DrawMode]
     * @param coordinates 高亮绘制的坐标
     */
    data class HighlightRegion(
        val highlightType: Int,
        val highlightColor: ZLColor,
        val coordinates: List<HighlightCoordinate>
    ) : SelectionResult()
}