
import 'package:flutter_lib/book_content/model/elements/content_element.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';

/// 对应ZLTextHyperlinkControlElement
class ContentHyperlinkControlElement extends ContentElement {
  NRTextHyperLink hyperlink;

  ContentHyperlinkControlElement.fromJson(Map<String, dynamic> json)
      : hyperlink = NRTextHyperLink.fromJson(json['Hyperlink']);
}
