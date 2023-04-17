package org.geometerplus.zlibrary.ui.android.view.bookrender.model

import org.geometerplus.zlibrary.core.util.ZLColor
import org.geometerplus.zlibrary.core.view.ZLPaintContext.Size
import org.geometerplus.zlibrary.text.view.ZLTextStyle
import org.geometerplus.zlibrary.text.view.ZLTextWord
import org.geometerplus.zlibrary.text.view.style.ZLTextStyleCollection

enum class ElementType {
    WORD,
    IMAGE,
    VIDEO,
    EXTENSION,
    SPACE
}

/** 保存绘制一行所需要的所有信息 */
data class LinePaintData(
    val elementPaintData: List<ElementPaintData>
)

sealed class ElementPaintData(
    val elementType: Int,
) {

    data class Word(
        val textStyle: ZLTextStyle?,
        var textBlock: TextBlock,
        val mark: ZLTextWord.Mark?,
        val color: ZLColor?,
        val shift: Int,
        val highlightBackgroundColor: ZLColor?,
        val highlightForegroundColor: ZLColor?,
        val spaceAfterWord: Int
    ) : ElementPaintData(ElementType.WORD.ordinal) {

        class Builder {
            private var textStyle: ZLTextStyle? = null
            private var textBlock: TextBlock? = null
            private var mark: ZLTextWord.Mark? = null
            private var color: ZLColor? = null
            private var shift: Int? = null
            private var highlightBackgroundColor: ZLColor? = null
            private var highlightForegroundColor: ZLColor? = null
            private var spaceAfterWord: Int = 0

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun textBlock(textBlock: TextBlock) = apply { this.textBlock = textBlock }
            fun mark(mark: ZLTextWord.Mark?) = apply { this.mark = mark }
            fun color(color: ZLColor?) = apply { this.color = color }
            fun shift(shift: Int) = apply { this.shift = shift }
            fun highlightBackgroundColor(color: ZLColor?) =
                apply { this.highlightBackgroundColor = color }

            fun highlightForegroundColor(color: ZLColor?) =
                apply { this.highlightForegroundColor = color }

            fun spaceAfterWord(spaceAfterWord: Int) = apply { this.spaceAfterWord = spaceAfterWord }

            fun build() = Word(
                textStyle = textStyle,
                textBlock = requireNotNull(textBlock),
                mark = mark,
                color = color,
                shift = requireNotNull(shift),
                highlightBackgroundColor = highlightBackgroundColor,
                highlightForegroundColor = highlightForegroundColor,
                spaceAfterWord = spaceAfterWord
            )
        }
    }

    data class Image(
        val textStyle: ZLTextStyle?,
        val sourceType: Int,
        val left: Float,
        val top: Float,
        val imageSrc: String,
        val maxSize: Size,
        val scalingType: Int,
        val adjustingModeForImages: Int,
    ) : ElementPaintData(ElementType.IMAGE.ordinal) {

        class Builder {
            private var textStyle: ZLTextStyle? = null
            private var sourceType: Int? = null
            private var left: Float? = null
            private var top: Float? = null
            private var imageSrc: String? = null
            private var maxSize: Size? = null
            private var scalingType: Int? = null
            private var adjustingModeForImages: Int? = null

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun sourceType(sourceType: Int) = apply { this.sourceType = sourceType }
            fun left(left: Float) = apply { this.left = left }
            fun top(top: Float) = apply { this.top = top }
            fun imageSrc(src: String) = apply { this.imageSrc = src }
            fun maxSize(maxSize: Size) = apply { this.maxSize = maxSize }
            fun scalingType(scalingType: Int) = apply { this.scalingType = scalingType }
            fun adjustingModeForImages(adjustingModeForImages: Int) =
                apply { this.adjustingModeForImages = adjustingModeForImages }

            fun build() = Image(
                textStyle = textStyle,
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
        val textStyle: ZLTextStyle?,
        val lineColor: ZLColor,
        val xStart: Int,
        val xEnd: Int,
        val yStart: Int,
        val yEnd: Int
    ) : ElementPaintData(ElementType.VIDEO.ordinal) {

        class Builder {
            private var textStyle: ZLTextStyle? = null
            private var lineColor: ZLColor? = null
            private var xStart: Int? = null
            private var xEnd: Int? = null
            private var yStart: Int? = null
            private var yEnd: Int? = null

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun lineColor(color: ZLColor) = apply { this.lineColor = color }
            fun xStart(xStart: Int) = apply { this.xStart = xStart }
            fun xEnd(xEnd: Int) = apply { this.xEnd = xEnd }
            fun yStart(yStart: Int) = apply { this.yStart = yStart }
            fun yEnd(yEnd: Int) = apply { this.yEnd = yEnd }

            fun build() = Video(
                textStyle = textStyle,
                lineColor = requireNotNull(lineColor),
                xStart = requireNotNull(xStart),
                xEnd = requireNotNull(xEnd),
                yStart = requireNotNull(yEnd),
                yEnd = requireNotNull(yEnd)
            )
        }
    }

    data class Extension(
        val textStyle: ZLTextStyle?,
        val imagePaintData: Image?,
        val videoPaintData: Video?,
    ) : ElementPaintData(ElementType.EXTENSION.ordinal) {

        class Builder {
            private var textStyle: ZLTextStyle? = null
            private var imagePaintData: Image? = null
            private var videoPaintData: Video? = null

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun imagePaintData(data: Image) = apply { this.imagePaintData = data }
            fun videoPaintData(data: Video) = apply { this.videoPaintData = data }

            fun build() = Extension(
                textStyle = textStyle,
                imagePaintData = imagePaintData,
                videoPaintData = videoPaintData
            )
        }
    }

    data class Space(
        val textStyle: ZLTextStyle?,
        val spaceWidth: Int,
        val textBlocks: List<TextBlock>
    ) : ElementPaintData(ElementType.SPACE.ordinal) {

        class Builder {
            private var textStyle: ZLTextStyle? = null
            private var spaceWidth: Int? = null
            private var textBlocks: List<TextBlock>? = null

            fun textStyle(textStyle: ZLTextStyle) = apply { this.textStyle = textStyle }
            fun spaceWidth(spaceWidth: Int) = apply { this.spaceWidth = spaceWidth }
            fun textBlocks(textBlocks: List<TextBlock>) =
                apply { this.textBlocks = textBlocks.toList() }

            fun build() = Space(
                textStyle = textStyle,
                spaceWidth = requireNotNull(spaceWidth),
                textBlocks = requireNotNull(textBlocks)
            )
        }
    }
}