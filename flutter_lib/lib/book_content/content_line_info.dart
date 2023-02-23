import 'content_paragraph_cursor.dart';

/// 对应ZLTextLineInfo
class ContentLineInfo {
  final ContentParagraphCursor paragraphCursor;
  final int paragraphCursorLength;

  final int startElementIndex;
  final int startCharIndex;

  // 代表每一行第一个字在myElements List中的位置
  int realStartElementIndex;
  int realStartCharIndex;

  // 代表每一行最后一个字在myElements List中的位置
  int endElementIndex;
  int endCharIndex;

  bool isVisible;
  int leftIndent;
  int width;
  int height;

  // 字符baseline到bottom到距离
  // https://www.jianshu.com/p/71cf11c120f0
  int descent;
  int vSpaceBefore;
  int vSpaceAfter;
  bool previousInfoUsed;
  int spaceCounter;

  // ZLTextStyle startStyle;

  ContentLineInfo.fromJson(Map<String, dynamic> json)
      : paragraphCursor =
            ContentParagraphCursor.fromJson(json['paragraphCursor']),
        paragraphCursorLength = json['paragraphCursorLength'],
        startElementIndex = json['startElementIndex'],
        startCharIndex = json['startCharIndex'],
        realStartElementIndex = json['realStartElementIndex'],
        realStartCharIndex = json['realStartCharIndex'],
        endElementIndex = json['endElementIndex'],
        endCharIndex = json['endCharIndex'],
        isVisible = json['isVisible'],
        leftIndent = json['leftIndent'],
        width = json['width'],
        height = json['height'],
        descent = json['descent'],
        vSpaceBefore = json['VSpaceBefore'],
        vSpaceAfter = json['VSpaceAfter'],
        previousInfoUsed = json['previousInfoUsed'],
        spaceCounter = json['spaceCounter'];

  bool isEndOfParagraph() {
    return endElementIndex == paragraphCursorLength;
  }

  @override
  bool operator ==(Object other) {
    other as ContentLineInfo;
    return (paragraphCursor == other.paragraphCursor) &&
        (startElementIndex == other.startElementIndex) &&
        (startCharIndex == other.startCharIndex);
  }

  @override
  int get hashCode =>
      paragraphCursor.hashCode + startElementIndex + 239 * startCharIndex;
}
