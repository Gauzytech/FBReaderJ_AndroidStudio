package org.geometerplus.zlibrary.ui.android.view.bookrender.model

sealed class SelectionResult {

    /**
     * 选中了文字内容
     * @param selectionStartY 选中文字第一行顶部的y坐标
     * @param selectionEndY 选中文字最后一行底部的y坐标
     */
    data class ShowMenu(val selectionStartY: Int, val selectionEndY: Int) : SelectionResult()

    /**
     * 选中了除文字之外的内容
     */
    object NoMenu: SelectionResult()

    /**
     * 没有选中内容
     */
    object None: SelectionResult()
}