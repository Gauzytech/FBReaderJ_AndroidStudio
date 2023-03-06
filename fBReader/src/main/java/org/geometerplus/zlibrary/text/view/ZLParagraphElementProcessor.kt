package org.geometerplus.zlibrary.text.view

import org.geometerplus.DebugHelper
import org.geometerplus.zlibrary.core.image.ZLImageManager
import org.geometerplus.zlibrary.text.model.ZLTextMark
import org.geometerplus.zlibrary.text.model.ZLTextParagraph
import org.geometerplus.zlibrary.text.view.ZLTextElement.Companion.hSpace
import org.geometerplus.zlibrary.text.view.ZLTextElement.Companion.nbSpace
import org.geometerplus.zlibrary.text.view.ZLTextElement.Companion.styleClose
import org.vimgadgets.linebreak.LineBreaker
import timber.log.Timber


/**
 * [ZLTextParagraphCursor.myElements]填充类
 */
private const val NO_SPACE = 0
private const val SPACE = 1
private const val NON_BREAKABLE_SPACE = 2

class ZLParagraphElementProcessor(
    private val myParagraph: ZLTextParagraph,
    private val myExtManager: ExtensionElementManager,
    private val myLineBreaker: LineBreaker,
    private val myMarks: List<ZLTextMark>,
    private var myOffset: Int,
    paragraphIndex: Int,
    private var imageCacheRootPath: String,
) {

    private var ourBreaks = ByteArray(1024)
    private var myFirstMark = 0
    private var myLastMark = 0

    init {
        // 定位mark操作
        // 在addWord()中会被用到
        // 定位mark操作
        // 在addWord()中会被用到
        val mark = ZLTextMark(paragraphIndex, 0, 0)
        for (i in myMarks.indices) {
            val currentMark = myMarks[i]
            /*
			 * == 0: mark相等
			 * > 0: currentMark > mark
			 * < 0: currentMark < mark
		     */
            if (currentMark >= mark) {
                myFirstMark = i
                break
            }
        }
        myLastMark = myFirstMark
        // 定位lastMark, 应该是paragraphIndex之后的paragraphIndex
        while (myLastMark != myMarks.size && myMarks[myLastMark].ParagraphIndex == paragraphIndex) {
            myLastMark++
        }
//			for (; myLastMark != myMarks.size() && myMarks.get(myLastMark).ParagraphIndex == paragraphIndex; myLastMark++);
    }

    fun fillElements(): List<ZLTextElement> {
        val elements = mutableListOf<ZLTextElement>()
        var hyperlinkDepth = 0
        var hyperlink: ZLTextHyperlink? = null

        // 这里会最终调用EntryIteratorImpl类的构造函数
        // kind: 见FBTextKind
        val iterator = myParagraph.iterator()
        while (iterator.next()) {
            when (iterator.type) {
                // 对于文本信息
                // 1. 先在iterator.next()对ZLTextParagraph.Entry.TEXT的处理:
                // 	1.1 记录文本信息的长度: textLength
                // 	1.2 将读取到的本地持久化char[]存到myTextData
                // 	1.3 存当前读取的dataOffset
                // 	1.4 更新dataOffset += textLength
                // 2. 调用Processor类的processTextEntry方法
                // 	2.1 将ZLTextWord类加入ZLTextParagraphCursor.myElements
                ZLTextParagraph.Entry.TEXT -> {
                    elements.addAll(
                        processTextEntry(
                            iterator.textData,
                            iterator.textOffset,
                            iterator.textLength,
                            hyperlink
                        )
                    )
                }
                // 对于标签信息
                // 1. 先在iterator.next()对ZLTextParagraph.Entry.CONTROL的处理:
                //  1.1 判断标签kind
                //  1.2 通过kind判断是开始标签/结束标签
                //  1.3 初始化超链接type
                // 2. 则直接将ZLTextControlElement类加入ZLTextParagraphCursor.myElements
                ZLTextParagraph.Entry.CONTROL -> {
                    // 超链接嵌套
                    if (hyperlink != null) {
                        hyperlinkDepth += if (iterator.controlIsStart) 1 else -1
                        if (hyperlinkDepth == 0) {
                            hyperlink = null
                        }
                    }
                    // style嵌套
                    elements.add(
                        ZLTextControlElement.get(
                            iterator.controlKind,  // 获取myControlKind属性, 代表标签种类
                            iterator.controlIsStart  // 获取myControlStart属性, 代表是标签对的开始/结束标签
                        )
                    )
                }
                ZLTextParagraph.Entry.HYPERLINK_CONTROL -> {
                    val hyperlinkType = iterator.hyperlinkType
                    if (hyperlinkType.toInt() != 0) {
                        val control = ZLTextHyperlinkControlElement(
                            iterator.controlKind,
                            hyperlinkType,
                            iterator.hyperlinkId
                        )
                        elements.add(control)
                        hyperlink = control.Hyperlink
                        hyperlinkDepth = 1
                    }
                }
                ZLTextParagraph.Entry.IMAGE -> {
                    val imageEntry = iterator.imageEntry
                    val image = imageEntry.image
                    if (image != null) {
                        val data = ZLImageManager.Instance().getImageData(image)
                        if (data != null) {
                            val cachePath = if (DebugHelper.ENABLE_FLUTTER) {
                                Timber.v("解析缓存流程 entryId = ${imageEntry.Id}")
                                ZLImageManager.Instance().writeImageToCache(imageCacheRootPath, imageEntry.Id, image)
                            } else null

                            hyperlink?.addElementIndex(elements.size)
                            elements.add(
                                ZLTextImageElement(
                                    imageEntry.Id,
                                    data,
                                    image.uri,
                                    imageEntry.IsCover,
                                    cachePath
                                )
                            )
                        }
                    }
                }
                ZLTextParagraph.Entry.AUDIO -> Unit
                ZLTextParagraph.Entry.VIDEO -> elements.add(ZLTextVideoElement(iterator.videoEntry.sources()))
                ZLTextParagraph.Entry.EXTENSION -> {
                    elements.addAll(
                        myExtManager.getElements(
                            iterator.extensionEntry
                        )
                    )
                }
                ZLTextParagraph.Entry.STYLE_CSS, ZLTextParagraph.Entry.STYLE_OTHER -> {
                    elements.add(
                        ZLTextStyleElement(iterator.styleEntry)
                    )
                }
                ZLTextParagraph.Entry.STYLE_CLOSE -> elements.add(styleClose())
                ZLTextParagraph.Entry.FIXED_HSPACE -> {
                    elements.add(
                        ZLTextFixedHSpaceElement.getElement(
                            iterator.fixedHSpaceLength
                        )
                    )
                }
            }
        }

        return elements
    }

    private fun processTextEntry(
        data: CharArray,
        offset: Int,
        length: Int,
        hyperlink: ZLTextHyperlink?
    ): List<ZLTextElement> {
        val myElements = mutableListOf<ZLTextElement>()
        if (length != 0) {
            if (ourBreaks.size < length) {
                ourBreaks = ByteArray(length)
            }
            val breaks = ourBreaks
            myLineBreaker.setLineBreaks(data, offset, length, breaks)

//			final ArrayList<ZLTextElement> elements = myElements;
            var ch = 0.toChar()
            var previousChar: Char
            var spaceState = NO_SPACE
            var wordStart = 0
            // 使用for循环一个一个读取char数组中的元素，然后对每个元素调用Processor类的addWord方法
            for (index in 0 until length) {
                previousChar = ch
                ch = data[offset + index]
                Timber.v("渲染流程:element填充, idx = %d, %s", offset + index, ch)
                // 判断当前的char元素是否是空格
                if (Character.isWhitespace(ch)) {
                    // 正常space
                    if (index > 0 && spaceState == NO_SPACE) {
                        val word = createWord(
                            myElements.size,
                            data,
                            offset + wordStart,
                            index - wordStart,
                            myOffset + wordStart,
                            hyperlink
                        )
                        myElements.add(word)
                    }
                    spaceState = SPACE
                } else if (Character.isSpaceChar(ch)) {
                    // NON_BREAKABLE_SPACE
                    if (index > 0 && spaceState == NO_SPACE) {
                        val word = createWord(
                            myElements.size,
                            data,
                            offset + wordStart,
                            index - wordStart,
                            myOffset + wordStart,
                            hyperlink
                        )
                        myElements.add(word)
                    }
                    myElements.add(nbSpace())
                    // 正常space > NON_BREAKABLE_SPACE, 如果两种space连在一起, 继续当做正常space
                    if (spaceState != SPACE) {
                        spaceState = NON_BREAKABLE_SPACE
                    }
                } else {
                    when (spaceState) {
                        SPACE -> {
                            // 空格, 正常space: SPACE
                            //if (breaks[index - 1] == LineBreak.NOBREAK || previousChar == '-') {
                            //}
                            myElements.add(hSpace())
                            wordStart = index
                        }
                        NON_BREAKABLE_SPACE -> wordStart = index
                        NO_SPACE -> {
                            // 正常文本
                            if (index > 0 && breaks[index - 1] != LineBreaker.NOBREAK.code.toByte() && previousChar != '-' && index != wordStart) {
                                val word = createWord(
                                    myElements.size,
                                    data,  // char数组的引用
                                    offset + wordStart,  // 这个字在char[]中的偏移量
                                    index - wordStart,  // 此参数一直为1
                                    myOffset + wordStart,  // 这个字在该段落中的偏移量
                                    hyperlink
                                ) // 代表超链接信息
                                myElements.add(word)
                                // 将index赋值给wordStart
                                // 保证下次循环index - wordStart为1
                                wordStart = index
                            }
                        }
                    }
                    spaceState = NO_SPACE
                }
            }
            when (spaceState) {
                SPACE -> myElements.add(hSpace())
                NON_BREAKABLE_SPACE -> myElements.add(nbSpace())
                NO_SPACE -> {
                    val word = createWord(
                        myElements.size,
                        data,
                        offset + wordStart,
                        length - wordStart,
                        myOffset + wordStart,
                        hyperlink
                    )
                    myElements.add(word)
                }
            }
            myOffset += length
        }
        return myElements
    }

    private fun createWord(
        elementIdx: Int,
        data: CharArray,
        offset: Int,
        len: Int,
        paragraphOffset: Int,
        hyperlink: ZLTextHyperlink?
    ): ZLTextWord {
        // 初始化一个ZLTextWord类
        val word = ZLTextWord(data, offset, len, paragraphOffset)
        for (i in myFirstMark until myLastMark) {
            val mark = myMarks[i]
            if (mark.Offset < paragraphOffset + len && mark.Offset + mark.Length > paragraphOffset) {
                word.addMark(mark.Offset - paragraphOffset, mark.Length)
            }
        }
        hyperlink?.addElementIndex(elementIdx)
        return word
    }
}




//	/**
//	 * myElement填充类
//	 */
//	private static final class Processor {
//		private final ZLTextParagraph myParagraph;
//		private final ExtensionElementManager myExtManager;
//		private final LineBreaker myLineBreaker;
//		private int myOffset;
//		private int myFirstMark;
//		private int myLastMark;
//		private final List<ZLTextMark> myMarks;
//
//		/**
//		 * <p>
//		 * 将char[]中代表当前段落的部分转换成一个元素为ZLTextElement类的ArrayList的工作
//		 *
//		 * @param paragraph      段落处理工具类, 代表一对p标签对应的paragraph. 利用工具类中的方法操作textModel中段落数据
//		 * @param extManager     FbView中的bookElementManager, 用来加载一些图书信息: OPDS
//		 * @param lineBreaker    分行cpp工具类
//		 * @param marks          textModel中mark类, 这是干啥的????
//		 * @param paragraphIndex 段落号
//		 */
//		private Processor(ZLTextParagraph paragraph, ExtensionElementManager extManager, LineBreaker lineBreaker, List<ZLTextMark> marks, int paragraphIndex) {
//			this.myParagraph = paragraph;
//			this.myExtManager = extManager;
//			this.myLineBreaker = lineBreaker;
//			this.myMarks = marks;
//			// 定位mark操作
//			// 在addWord()中会被用到
//			final ZLTextMark mark = new ZLTextMark(paragraphIndex, 0, 0);
//			for (int i = 0; i < myMarks.size(); i++) {
//				ZLTextMark currentMark = myMarks.get(i);
//				/*
//				 * == 0: mark相等
//				 * > 0: currentMark > mark
//				 * < 0: currentMark < mark
//				 */
//				if (currentMark.compareTo(mark) >= 0) {
//					myFirstMark = i;
//					break;
//				}
//			}
//			myLastMark = myFirstMark;
//			// 定位lastMark, 应该是paragraphIndex之后的paragraphIndex
//			while (myLastMark != myMarks.size() && myMarks.get(myLastMark).ParagraphIndex == paragraphIndex) {
//				myLastMark++;
//			}
////			for (; myLastMark != myMarks.size() && myMarks.get(myLastMark).ParagraphIndex == paragraphIndex; myLastMark++);
//			myOffset = 0;
//		}
//
//		/**
//		 * 根据myParagraph entry初始化myElements
//		 * 一组p标签就代表一个Paragraph
//		 */
//		public void fillElements(List<ZLTextElement> myElements) {
//			int hyperlinkDepth = 0;
//			ZLTextHyperlink hyperlink = null;
//
//			// reference传递
////			final List<ZLTextElement> elements = myElements;
//			// 这里会最终调用EntryIteratorImpl类的构造函数
//			// kind: 见FBTextKind
//			for (ZLTextParagraph.EntryIterator it = myParagraph.iterator(); it.next(); ) {
//				switch (it.getType()) {
//					// 对于文本信息
//					// 1. 先在iterator.next()对ZLTextParagraph.Entry.TEXT的处理:
//					// 	1.1 记录文本信息的长度: textLength
//					// 	1.2 将读取到的本地持久化char[]存到myTextData
//					// 	1.3 存当前读取的dataOffset
//					// 	1.4 更新dataOffset += textLength
//					// 2. 调用Processor类的processTextEntry方法
//					// 	2.1 将ZLTextWord类加入ZLTextParagraphCursor.myElements
//					case ZLTextParagraph.Entry.TEXT:
//						processTextEntry(myElements, it.getTextData(), it.getTextOffset(), it.getTextLength(), hyperlink);
//						break;
//					// 对于标签信息
//					// 1. 先在iterator.next()对ZLTextParagraph.Entry.CONTROL的处理:
//					//  1.1 判断标签kind
//					//  1.2 通过kind判断是开始标签/结束标签
//					//  1.3 初始化超链接type
//					// 2. 则直接将ZLTextControlElement类加入ZLTextParagraphCursor.myElements
//					case ZLTextParagraph.Entry.CONTROL:
//						// 超链接嵌套
//						if (hyperlink != null) {
//							hyperlinkDepth += it.getControlIsStart() ? 1 : -1;
//							if (hyperlinkDepth == 0) {
//								hyperlink = null;
//							}
//						}
//						//
//						myElements.add(ZLTextControlElement.get(
//								it.getControlKind(),           // 获取myControlKind属性, 代表标签种类
//								it.getControlIsStart())        // 获取myControlStart属性, 代表是标签对的开始/结束标签
//						);
//						break;
//					case ZLTextParagraph.Entry.HYPERLINK_CONTROL: {
//						final byte hyperlinkType = it.getHyperlinkType();
//						if (hyperlinkType != 0) {
//							final ZLTextHyperlinkControlElement control = new ZLTextHyperlinkControlElement(
//									it.getControlKind(),
//									hyperlinkType,
//									it.getHyperlinkId()
//							);
//							myElements.add(control);
//							hyperlink = control.Hyperlink;
//							hyperlinkDepth = 1;
//						}
//						break;
//					}
//					case ZLTextParagraph.Entry.IMAGE:
//						final ZLImageEntry imageEntry = it.getImageEntry();
//						final ZLImage image = imageEntry.getImage();
//						if (image != null) {
//							ZLImageData data = ZLImageManager.Instance().getImageData(image);
//							if (data != null) {
//								if (hyperlink != null) {
//									hyperlink.addElementIndex(myElements.size());
//								}
//								myElements.add(new ZLTextImageElement(imageEntry.Id, data, image.getURI(), imageEntry.IsCover));
//							}
//						}
//						break;
//					case ZLTextParagraph.Entry.AUDIO:
//						break;
//					case ZLTextParagraph.Entry.VIDEO:
//						myElements.add(new ZLTextVideoElement(it.getVideoEntry().sources()));
//						break;
//					case ZLTextParagraph.Entry.EXTENSION:
//						if (myExtManager != null) {
//							myElements.addAll(myExtManager.getElements(it.getExtensionEntry()));
//						}
//						break;
//					case ZLTextParagraph.Entry.STYLE_CSS:
//					case ZLTextParagraph.Entry.STYLE_OTHER:
//						myElements.add(new ZLTextStyleElement(it.getStyleEntry()));
//						break;
//					case ZLTextParagraph.Entry.STYLE_CLOSE:
//						myElements.add(ZLTextElement.Companion.styleClose());
//						break;
//					case ZLTextParagraph.Entry.FIXED_HSPACE:
//						myElements.add(ZLTextFixedHSpaceElement.getElement(it.getFixedHSpaceLength()));
//						break;
//				}
//			}
//		}
//
//		private static byte[] ourBreaks = new byte[1024];
//		private static final int NO_SPACE = 0;
//		private static final int SPACE = 1;
//		private static final int NON_BREAKABLE_SPACE = 2;
//
//		private void processTextEntry(List<ZLTextElement> myElements, final char[] data, final int offset, final int length, ZLTextHyperlink hyperlink) {
//			if (length != 0) {
//				if (ourBreaks.length < length) {
//					ourBreaks = new byte[length];
//				}
//				final byte[] breaks = ourBreaks;
//				myLineBreaker.setLineBreaks(data, offset, length, breaks);
//
////				final ArrayList<ZLTextElement> elements = myElements;
//				char ch = 0;
//				char previousChar;
//				int spaceState = NO_SPACE;
//				int wordStart = 0;
//				// 使用for循环一个一个读取char数组中的元素，然后对每个元素调用Processor类的addWord方法
//				for (int index = 0; index < length; ++index) {
//					previousChar = ch;
//					ch = data[offset + index];
//					Timber.v("渲染流程:element填充, idx = %d, %s", offset + index, ch);
//					// 判断当前的char元素是否是空格
//					if (Character.isWhitespace(ch)) {
//						// 正常space
//						if (index > 0 && spaceState == NO_SPACE) {
//							ZLTextWord word = createWord(myElements.size(), data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
//							myElements.add(word);
//						}
//						spaceState = SPACE;
//					} else if (Character.isSpaceChar(ch)) {
//						// NON_BREAKABLE_SPACE
//						if (index > 0 && spaceState == NO_SPACE) {
//							ZLTextWord word = createWord(myElements.size(), data, offset + wordStart, index - wordStart, myOffset + wordStart, hyperlink);
//							myElements.add(word);
//						}
//						myElements.add(ZLTextElement.Companion.nbSpace());
//						// 正常space > NON_BREAKABLE_SPACE, 如果两种space连在一起, 继续当做正常space
//						if (spaceState != SPACE) {
//							spaceState = NON_BREAKABLE_SPACE;
//						}
//					} else {
//						switch (spaceState) {
//							// 空格, 正常space: SPACE
//							case SPACE:
//								//if (breaks[index - 1] == LineBreak.NOBREAK || previousChar == '-') {
//								//}
//								myElements.add(ZLTextElement.Companion.hSpace());
//								wordStart = index;
//								break;
//							case NON_BREAKABLE_SPACE:
//								wordStart = index;
//								break;
//							// 正常文本
//							case NO_SPACE:
//								if (index > 0 &&
//										breaks[index - 1] != LineBreaker.NOBREAK &&
//										previousChar != '-' &&
//										index != wordStart) {
//									ZLTextWord word = createWord(myElements.size(),
//											data,                                      // char数组的引用
//											offset + wordStart,                  // 这个字在char[]中的偏移量
//											index - wordStart,                     // 此参数一直为1
//											myOffset + wordStart,        // 这个字在该段落中的偏移量
//											hyperlink);                                 // 代表超链接信息
//									myElements.add(word);
//									// 将index赋值给wordStart
//									// 保证下次循环index - wordStart为1
//									wordStart = index;
//								}
//								break;
//						}
//						spaceState = NO_SPACE;
//					}
//				}
//				switch (spaceState) {
//					case SPACE:
//						myElements.add(ZLTextElement.Companion.hSpace());
//						break;
//					case NON_BREAKABLE_SPACE:
//						myElements.add(ZLTextElement.Companion.nbSpace());
//						break;
//					case NO_SPACE:
//						ZLTextWord word = createWord(myElements.size(), data, offset + wordStart, length - wordStart, myOffset + wordStart, hyperlink);
//						myElements.add(word);
//						break;
//				}
//				myOffset += length;
//			}
//		}
//
//		private ZLTextWord createWord(int elementIdx, char[] data, int offset, int len, int paragraphOffset, ZLTextHyperlink hyperlink) {
//			// 初始化一个ZLTextWord类
//			ZLTextWord word = new ZLTextWord(data, offset, len, paragraphOffset);
//			for (int i = myFirstMark; i < myLastMark; ++i) {
//				final ZLTextMark mark = (ZLTextMark) myMarks.get(i);
//				if ((mark.Offset < paragraphOffset + len) && (mark.Offset + mark.Length > paragraphOffset)) {
//					word.addMark(mark.Offset - paragraphOffset, mark.Length);
//				}
//			}
//			if (hyperlink != null) {
//				hyperlink.addElementIndex(elementIdx);
//			}
//			return word;
//		}
//	}