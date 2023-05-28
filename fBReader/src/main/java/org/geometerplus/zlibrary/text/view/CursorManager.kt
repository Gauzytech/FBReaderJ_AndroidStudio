package org.geometerplus.zlibrary.text.view

import androidx.collection.LruCache
import org.geometerplus.zlibrary.text.model.ZLTextModel

/**
 * @param extensionManager FbView中的bookElementManager, 用来加载一些图书信息: OPDS
 */
class CursorManager(
    val textModel: ZLTextModel,
    val extensionManager: ExtensionElementManager?,
) :
    // max 200 cursors in the cache
    LruCache<Int, ZLTextParagraphCursor>(200) {

    /**
     * LRU value的创建方法
     *
     * 一组p标签就代表一个段落(Paragraph),
     * ZLTextParagraphCursor对应一个paragraph的解析信息
     *
     * @param key 缓存解析文件的index
     */
    override fun create(key: Int): ZLTextParagraphCursor {
        return ZLTextParagraphCursor(this, textModel, key)
    }
}