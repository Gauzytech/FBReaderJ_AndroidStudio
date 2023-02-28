package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.core.view.ZLPaintContext.Size
import org.geometerplus.zlibrary.text.view.ZLTextStyle
import org.geometerplus.zlibrary.text.view.ZLTextWord

enum class ElementType {
    WORD,
    IMAGE,
    VIDEO,
    EXTENSION,
    SPACE
}

/** 保存绘制一行所需要的所有信息 */
data class LinePaintData(val elementPaintData: List<ElementPaintData>)

sealed class ElementPaintData(
    open val elementType: Int,
    open val textStyle: ZLTextStyle?,
) {

    data class Word(
        override val elementType: Int,
        override val textStyle: ZLTextStyle,
        val x: Int,
        val y: Int,
        val data: CharArray,
        val offset: Int,
        val length: Int,
        val mark: ZLTextWord.Mark,
        val color: ZLColor,
        val shift: Int
    ) : ElementPaintData(elementType, textStyle) {

        internal class Builder : ElementPaintData.Builder() {
            private var x: Int? = null
            private var y: Int? = null
            private var data: CharArray? = null
            private var offset: Int? = null
            private var length: Int? = null
            private var mark: ZLTextWord.Mark? = null
            private var color: ZLColor? = null
            private var shift: Int? = null

            fun x(x: Int) = apply { this.x = x }
            fun y(y: Int) = apply { this.y = y }
            fun data(data: CharArray) = apply { this.data = data }
            fun offset(offset: Int) = apply { this.offset = offset }
            fun length(length: Int) = apply { this.length = length }
            fun mark(mark: ZLTextWord.Mark) = apply { this.mark = mark }
            fun color(color: ZLColor) = apply { this.color = color }
            fun shift(shift: Int) = apply { this.shift = shift }

            fun build() = Word(
                elementType = ElementType.WORD.ordinal,
                textStyle = requireNotNull(textStyle),
                x = requireNotNull(x),
                y = requireNotNull(y),
                data = requireNotNull(data),
                offset = requireNotNull(offset),
                length = requireNotNull(length),
                mark = requireNotNull(mark),
                color = requireNotNull(color),
                shift = requireNotNull(shift)
            )
        }
    }

    data class Image(
        override val elementType: Int,
        override val textStyle: ZLTextStyle?,
        val left: Float,
        val top: Float,
        val imageSrc: String,
        val adjustingModeForImages: String,
    ) : ElementPaintData(elementType, textStyle) {

        internal class Builder : ElementPaintData.Builder() {
            private var left: Float? = null
            private var top: Float? = null
            private var imageSrc: String? = null
            private var maxSize: Size? = null
            private var scalingType: String? = null
            private var adjustingModeForImages: String? = null

            fun left(left: Float) = apply { this.left = left }
            fun top(top: Float) = apply { this.top = top }
            fun imageSrc(src: String) = apply { this.imageSrc = src }
            fun maxSize(maxSize: Size) = apply { this.maxSize = maxSize }
            fun scalingType(scalingType: String) = apply { this.scalingType = scalingType }
            fun adjustingModeForImages(adjustingModeForImages: String) =
                apply { this.adjustingModeForImages = adjustingModeForImages }

            fun build() = Image(
                elementType = ElementType.IMAGE.ordinal,
                textStyle = textStyle,
                left = requireNotNull(left),
                top = requireNotNull(top),
                imageSrc = requireNotNull(imageSrc),
                adjustingModeForImages = requireNotNull(adjustingModeForImages),
            )
        }
    }

    data class Video(
        override val elementType: Int,
        override val textStyle: ZLTextStyle?,
        var xStart: Int,
        val xEnd: Int,
        var yStart: Int,
        var yEnd: Int
    ) : ElementPaintData(elementType, textStyle) {

        internal class Builder : ElementPaintData.Builder() {
            private var lineColor: ZLColor? = null
            private var xStart: Int? = null
            private var xEnd: Int? = null
            private var yStart: Int? = null
            private var yEnd: Int? = null

            fun lineColor(color: ZLColor) = apply { this.lineColor = color }
            fun xStart(xStart: Int) = apply { this.xStart = xStart }
            fun xEnd(xEnd: Int) = apply { this.xEnd = xEnd }
            fun yStart(yStart: Int) = apply { this.yStart = yStart }
            fun yEnd(yEnd: Int) = apply { this.yEnd = yEnd }

            fun build() = Video(
                elementType = ElementType.VIDEO.ordinal,
                textStyle = textStyle,
                xStart = requireNotNull(xStart),
                xEnd = requireNotNull(xEnd),
                yStart = requireNotNull(yEnd),
                yEnd = requireNotNull(yEnd)
            )
        }
    }

    data class Extension(
        override val elementType: Int,
        override val textStyle: ZLTextStyle?,
        val imagePaintData: Image?,
        val videoPaintData: Video?,
    ) : ElementPaintData(elementType, textStyle) {

        internal class Builder : ElementPaintData.Builder() {
            private var imagePaintData: Image? = null
            private var videoPaintData: Video? = null

            fun imagePaintData(data: Image) = apply { this.imagePaintData = data }
            fun videoPaintData(data: Video) = apply { this.videoPaintData = data }

            fun build() = Extension(
                elementType = ElementType.EXTENSION.ordinal,
                textStyle = textStyle,
                imagePaintData = imagePaintData,
                videoPaintData = videoPaintData
            )
        }
    }

    data class Space(
        override val elementType: Int,
        override val textStyle: ZLTextStyle?,
        val spaceWidth: Int,
        val textBlocks: List<TextBlock>
    ) : ElementPaintData(elementType, textStyle) {

        internal class Builder : ElementPaintData.Builder() {
            private var spaceWidth: Int? = null
            private var textBlocks: List<TextBlock>? = null

            fun spaceWidth(spaceWidth: Int) = apply { this.spaceWidth = spaceWidth }
            fun textBlocks(textBlocks: List<TextBlock>) =
                apply { this.textBlocks = textBlocks.toList() }

            fun build() = Space(
                elementType = ElementType.SPACE.ordinal,
                textStyle = textStyle,
                spaceWidth = requireNotNull(spaceWidth),
                textBlocks = requireNotNull(textBlocks)
            )
        }
    }

    internal open class Builder {
        protected var textStyle: ZLTextStyle? = null

        fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
    }
}