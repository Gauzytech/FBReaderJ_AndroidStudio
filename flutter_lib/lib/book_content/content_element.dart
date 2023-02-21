/// 对应ZLTextElement
class ContentElement {

  // ContentElement.fromJson(Map<String, dynamic> json);
}

// 空格, 正常space
class HorizontalSpace implements ContentElement {

  fromJson() {
    return HorizontalSpace();
  }
}

// NON_BREAKABLE_SPACE
class NonBreakableSpace implements ContentElement {
  static create() => NonBreakableSpace();
}

class AfterParagraph implements ContentElement {
  static create() => AfterParagraph();
}

class Indent implements ContentElement {
  static create() => Indent();
}

class StyleClose implements ContentElement {
  static create() => StyleClose();
}
