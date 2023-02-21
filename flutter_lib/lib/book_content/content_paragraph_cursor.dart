
import 'package:flutter_lib/book_content/content_element.dart';

/// 对应ZLTextParagraphCursor
class ContentParagraphCursor {
  int get paragraphIdx => _paragraphIdx;
  int _paragraphIdx;
  List<ContentElement> _elements;

  ContentParagraphCursor.fromJson(Map<String, dynamic> json)
      : _paragraphIdx = json['paragraphIdx'],
        _elements = (json['myElements'] as List)
            .map((item) => ContentElement.fromJson(item))
            .toList();
}