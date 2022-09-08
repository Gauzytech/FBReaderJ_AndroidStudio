package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.text.view.ZLTextRegion.Soul

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender.model
 * @FileName SelectionRanage
 * @Date 9/5/22, 8:09 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
data class SelectionRange(val leftMostRegionSoul: Soul?, val rightMostRegionSoul: Soul?) {

    fun isSame(leftMost: Soul?, rightMost: Soul?): Boolean {
        return leftMostRegionSoul == leftMost
                && rightMostRegionSoul == rightMost
    }
}