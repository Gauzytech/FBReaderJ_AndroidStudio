import 'package:flutter_lib/book_content/content_paragraph_cursor.dart';
import 'package:flutter_lib/interface/content_position.dart';

/// 对应ZLTextWordCursor
class ContentWordCursor extends ContentPosition {
  // 代表当前需要显示的段落的ZLTextParagraphCursor类
  // 一组p标签就代表一个段落
  // ZLTextParagraphCursor对应一个paragraph的解析信息
  @override
  int get paragraphIndex =>
      _paragraphCursor != null ? _paragraphCursor!.paragraphIdx : 0;
  final ContentParagraphCursor? _paragraphCursor;

  // 每个element代表一个word或者一个标签元素, 所以elementIndex就是wordIndex
  @override
  int get elementIndex => _elementIndex;
  final int _elementIndex;

  // 针对英文单词中的字母, 从第一个字母开始
  @override
  int get charIndex => _charIndex;
  final int _charIndex;

  ContentWordCursor.fromJson(Map<String, dynamic> json)
      : _paragraphCursor =
            ContentParagraphCursor.fromJson(json['myParagraphCursor']),
        _elementIndex = json['myElementIndex'],
        _charIndex = json['myCharIndex'];
}
