
import 'package:flutter_lib/book_content/model/elements/content_element.dart';
import 'package:flutter_lib/book_content/model/elements/content_hyperlink.dart';

/// 对应ZLTextHyperlinkControlElement
class ContentHyperlinkControlElement extends ContentElement {
  ContentHyperlink hyperlink;

  ContentHyperlinkControlElement.fromJson(Map<String, dynamic> json)
      : hyperlink = ContentHyperlink.fromJson(json['Hyperlink']);
}
