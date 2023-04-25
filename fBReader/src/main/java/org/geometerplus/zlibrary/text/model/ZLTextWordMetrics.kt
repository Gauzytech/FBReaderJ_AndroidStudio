package org.geometerplus.zlibrary.text.model

import org.geometerplus.zlibrary.text.view.ZLTextStyle
import org.geometerplus.zlibrary.text.view.ZLTextWord

/**
 * 缓存[org.geometerplus.zlibrary.text.view.ZLTextWord]的测量信息
 */
data class ZLTextWordMetrics(val width: Int, val descent: Int)

data class ZLTextWordCacheKey(val textWord: ZLTextWord, val textStyle: ZLTextStyle)
