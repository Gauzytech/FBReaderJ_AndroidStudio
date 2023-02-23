
import 'package:flutter_lib/book_content/model/elements/content_element.dart';

import 'content_style_entry.dart';

/// 对应ZLTextStyleElement
// todo
class ContentStyleElement extends ContentElement {
  final ContentStyleEntry entry;

  ContentStyleElement.fromJson(Map<String, dynamic> json) :
        entry = json['Entry'];
}