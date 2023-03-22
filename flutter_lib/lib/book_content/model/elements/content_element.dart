
import 'package:flutter_lib/book_content/model/elements/content_control_element.dart';
import 'package:flutter_lib/book_content/model/elements/content_fixed_horizontal_space_element.dart';

import 'content_hyperlink_control_element.dart';
import 'content_image_element.dart';

/// 对应ZLTextElement
abstract class ContentElement {
  static ContentElement fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    switch (type) {
      case 'HSpaceElement':
        return HorizontalSpace();
      case 'NBSpaceElement':
        return NonBreakingSpace();
      case 'AfterParagraphElement':
        return AfterParagraph();
      case 'IndentElement':
        return Indent();
      case 'StyleCloseElement':
        return StyleClose();
      case 'ZLTextControlElement':
        return ContentControlElement.fromJson(json);
      case 'ZLTextFixedHSpaceElement':
        return ContentFixedHorizontalSpaceElement.fromJson(json);
      case 'ZLTextHyperlinkControlElement':
        return ContentHyperlinkControlElement.fromJson(json);
      // case 'ZLTextImageElement':
      //   return ContentImageElement.fromJson(json);
      // case 'ZLTextStyleElement':
      //   return;
      // case 'ZLTextVideoElement':
      //   return;
      // case 'ZLTextWord':
      //   return;
    }

    throw Exception("Unsupported type: $type");
  }
}

// 空格, 正常space
class HorizontalSpace implements ContentElement {

  fromJson() {
    return HorizontalSpace();
  }
}

// NON_BREAKABLE_SPACE
class NonBreakingSpace implements ContentElement {}

class AfterParagraph implements ContentElement {}

class Indent implements ContentElement {}

class StyleClose implements ContentElement {}
