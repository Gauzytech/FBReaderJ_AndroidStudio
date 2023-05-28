package org.geometerplus.fbreader.bookmodel

import org.geometerplus.fbreader.book.Book
import org.geometerplus.fbreader.formats.BookReadingException
import org.geometerplus.fbreader.formats.BuiltinFormatPlugin
import org.geometerplus.fbreader.formats.FormatPlugin
import org.geometerplus.zlibrary.core.fonts.FileInfo
import org.geometerplus.zlibrary.core.fonts.FontEntry
import org.geometerplus.zlibrary.core.fonts.FontManager
import org.geometerplus.zlibrary.core.image.ZLImage
import org.geometerplus.zlibrary.text.model.CachedCharStorage
import org.geometerplus.zlibrary.text.model.ZLTextModel
import org.geometerplus.zlibrary.text.model.ZLTextPlainModel
import timber.log.Timber
import java.util.*

/**
 * @Package org.geometerplus.fbreader.bookmodel
 * @FileName BookModel
 * @Date 5/28/23, 2:19 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
class BookModel(
    @get:JvmName("book") val book: Book?,
    @get:JvmName("tocTree") val tocTree: TOCTree = TOCTree(),
) {

    private val fontManager = FontManager()

    private var internalHyperlinks: CachedCharStorage? = null
    private val imageMap = mutableMapOf<String, ZLImage>()
    private var bookTextModel: ZLTextModel? = null
    private val footnotes = mutableMapOf<String, ZLTextModel>()
    private var labelResolver: LabelResolver? = null

    interface LabelResolver {
        fun getCandidates(id: String?): List<String>
    }

    fun setLabelResolver(resolver: LabelResolver) {
        labelResolver = resolver
    }

    /**
     * 获得footNote/超链接数据
     */
    fun getLabel(id: String): Label? {
        Timber.v("超链接, id = %s", id)
        var label = getLabelInternal(id)
        if (label == null && labelResolver != null) {
            for (candidate in labelResolver!!.getCandidates(id)) {
                label = getLabelInternal(candidate)
                if (label != null) {
                    break
                }
            }
        }
        return label
    }

    fun getTextModel(): ZLTextModel? {
        return bookTextModel
    }

    fun getFootnoteModel(id: String): ZLTextModel? {
        return footnotes[id]
    }

    fun addImage(id: String, image: ZLImage) {
        imageMap[id] = image
    }

    private fun getLabelInternal(id: String): Label? {
        val len = id.length
        val size = internalHyperlinks!!.size()
        for (i in 0 until size) {
            val block = internalHyperlinks!!.block(i)
            var offset = 0
            while (offset < block.size) {
                val labelLength = block[offset++].code
                if (labelLength == 0) {
                    break
                }
                val idLength = block[offset + labelLength].code
                if (labelLength != len || id != String(block, offset, labelLength)) {
                    offset += labelLength + idLength + 3
                    continue
                }
                offset += labelLength + 1
                val modelId = if (idLength > 0) String(block, offset, idLength) else null
                offset += idLength
                val paragraphNumber = block[offset].code + (block[offset + 1].code shl 16)
                return Label(modelId, paragraphNumber)
            }
        }
        return null
    }

    /********************************** 以下为cpp调用java的方法 *******************************/
    fun registerFontFamilyList(families: Array<String>) {
        fontManager.index(families.toList())
    }

    fun registerFontEntry(family: String, entry: FontEntry) {
        fontManager.Entries[family] = entry
    }

    fun registerFontEntry(
        family: String,
        normal: FileInfo,
        bold: FileInfo,
        italic: FileInfo,
        boldItalic: FileInfo
    ) {
        registerFontEntry(family, FontEntry(family, normal, bold, italic, boldItalic))
    }

    fun createTextModel(
        id: String?,
        language: String,
        paragraphsNumber: Int,
        entryIndices: IntArray,
        entryOffsets: IntArray,
        paragraphLenghts: IntArray,
        textSizes: IntArray,
        paragraphKinds: ByteArray,
        directoryName: String,
        fileExtension: String,
        blocksNumber: Int
    ): ZLTextModel =
        ZLTextPlainModel(
            id,
            language,
            paragraphsNumber,
            entryIndices,
            entryOffsets,
            paragraphLenghts,
            textSizes,
            paragraphKinds,
            directoryName,
            fileExtension,
            blocksNumber,
            imageMap,
            fontManager
        )

    fun setBookTextModel(model: ZLTextModel) {
        bookTextModel = model
    }

    fun setFootnoteModel(model: ZLTextModel) {
        footnotes[model.id] = model
    }

    fun initInternalHyperlinks(directoryName: String, fileExtension: String, blocksNumber: Int) {
        internalHyperlinks = CachedCharStorage(directoryName, fileExtension, blocksNumber)
    }

    private var myCurrentTree = tocTree

    fun addTOCItem(text: String, reference: Int) {
        myCurrentTree = TOCTree(myCurrentTree)
        myCurrentTree.text = text
        myCurrentTree.setReference(bookTextModel, reference)
    }

    fun leaveTOCItem() {
        myCurrentTree = myCurrentTree.Parent
        if (myCurrentTree == null) {
            myCurrentTree = tocTree
        }
    }

    /********************************** 以上为cpp调用java的方法 *******************************/

    class Label(
        @get:JvmName("modelId") val modelId: String?,
        @get:JvmName("paragraphIndex") val paragraphIndex: Int
    )

    companion object {

        @JvmStatic
        @Throws(BookReadingException::class)
        fun createModel(book: Book, plugin: FormatPlugin): BookModel {
            Timber.v("图书解析流程, 开始解析图书, 创建图书model, %s", plugin.javaClass.simpleName)
            // 只有FB2NativePlugin和OEBNativePlugin才会执行cpp层解析
            if (plugin !is BuiltinFormatPlugin) {
                throw BookReadingException("unknownPluginType", null, arrayOf("$plugin"))
            }

            // 保存图书基本信息: title, path, encoding,
            val model = BookModel(book)
            // 图书解析入口, 调用cpp层开始图书解析
            plugin.readModel(model)
            return model
        }
    }
}