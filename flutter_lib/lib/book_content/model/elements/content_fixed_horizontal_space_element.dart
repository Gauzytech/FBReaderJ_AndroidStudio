

import 'package:flutter_lib/book_content/model/elements/content_element.dart';

/// 对应ZLTextFixedHSpaceElement
class ContentFixedHorizontalSpaceElement extends ContentElement {
  List<ContentElement> collection;
  int length;

  ContentFixedHorizontalSpaceElement.fromJson(Map<String, dynamic> json)
      : collection = (json['ourCollection'] as List)
            .map((item) => ContentElement.fromJson(item))
            .toList(),
        length = json['Length'];
}
