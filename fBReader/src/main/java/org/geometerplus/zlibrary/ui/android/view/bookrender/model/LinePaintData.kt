package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.image.ZLImageProxy.SourceType
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

sealed class ElementPaintData {

    data class Word(
        val elementType: Int = ElementType.WORD.ordinal,
        val textStyle: ZLTextStyle,
        var textBlock: TextBlock,
        val mark: ZLTextWord.Mark,
        val color: ZLColor,
        val shift: Int,
    ) : ElementPaintData() {

        internal class Builder  {
            private var textStyle: ZLTextStyle? = null
            private var textBlock: TextBlock? = null
            private var mark: ZLTextWord.Mark? = null
            private var color: ZLColor? = null
            private var shift: Int? = null

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun textBlock(textBlock: TextBlock) = apply { this.textBlock = textBlock }
            fun mark(mark: ZLTextWord.Mark) = apply { this.mark = mark }
            fun color(color: ZLColor) = apply { this.color = color }
            fun shift(shift: Int) = apply { this.shift = shift }

            fun build() = Word(
                textStyle = requireNotNull(textStyle),
                textBlock = requireNotNull(textBlock),
                mark = requireNotNull(mark),
                color = requireNotNull(color),
                shift = requireNotNull(shift)
            )
        }
    }

    data class Image(
        val elementType: Int = ElementType.IMAGE.ordinal,
        val sourceType: String,
        val left: Float,
        val top: Float,
        val imageSrc: String,
        val maxSize: Size,
        val scalingType: String,
        val adjustingModeForImages: String,
    ) : ElementPaintData() {

        internal class Builder {
            private var sourceType: String? = null
            private var left: Float? = null
            private var top: Float? = null
            private var imageSrc: String? = null
            private var maxSize: Size? = null
            private var scalingType: String? = null
            private var adjustingModeForImages: String? = null

            fun sourceType(sourceType: String) = apply { this.sourceType = sourceType }
            fun left(left: Float) = apply { this.left = left }
            fun top(top: Float) = apply { this.top = top }
            fun imageSrc(src: String) = apply { this.imageSrc = src }
            fun maxSize(maxSize: Size) = apply { this.maxSize = maxSize }
            fun scalingType(scalingType: String) = apply { this.scalingType = scalingType }
            fun adjustingModeForImages(adjustingModeForImages: String) =
                apply { this.adjustingModeForImages = adjustingModeForImages }

            fun build() = Image(
                sourceType = requireNotNull(sourceType),
                left = requireNotNull(left),
                top = requireNotNull(top),
                imageSrc = requireNotNull(imageSrc),
                maxSize = requireNotNull(maxSize),
                scalingType = requireNotNull(scalingType),
                adjustingModeForImages = requireNotNull(adjustingModeForImages),
            )
        }
    }

    data class Video(
        val elementType: Int = ElementType.VIDEO.ordinal,
        var lineColor: ZLColor,
        var xStart: Int,
        val xEnd: Int,
        var yStart: Int,
        var yEnd: Int
    ) : ElementPaintData() {

        internal class Builder {
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
                lineColor = requireNotNull(lineColor),
                xStart = requireNotNull(xStart),
                xEnd = requireNotNull(xEnd),
                yStart = requireNotNull(yEnd),
                yEnd = requireNotNull(yEnd)
            )
        }
    }

    data class Extension(
        val elementType: Int = ElementType.EXTENSION.ordinal,
        val imagePaintData: Image?,
        val videoPaintData: Video?,
    ) : ElementPaintData() {

        internal class Builder {
            private var imagePaintData: Image? = null
            private var videoPaintData: Video? = null

            fun imagePaintData(data: Image) = apply { this.imagePaintData = data }
            fun videoPaintData(data: Video) = apply { this.videoPaintData = data }

            fun build() = Extension(
                imagePaintData = imagePaintData,
                videoPaintData = videoPaintData
            )
        }
    }

    data class Space(
        val elementType: Int = ElementType.SPACE.ordinal,
        val spaceWidth: Int,
        val textBlocks: List<TextBlock>
    ) : ElementPaintData() {

        internal class Builder {
            private var spaceWidth: Int? = null
            private var textBlocks: List<TextBlock>? = null

            fun spaceWidth(spaceWidth: Int) = apply { this.spaceWidth = spaceWidth }
            fun textBlocks(textBlocks: List<TextBlock>) =
                apply { this.textBlocks = textBlocks.toList() }

            fun build() = Space(
                spaceWidth = requireNotNull(spaceWidth),
                textBlocks = requireNotNull(textBlocks)
            )
        }
    }
}