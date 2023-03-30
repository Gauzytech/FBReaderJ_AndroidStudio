
import 'content_element.dart';

/// 对应ZLTextControlElement
class ContentControlElement extends ContentElement {
  List<ContentControlElement> startElements;
  List<ContentControlElement> endElements;
  int kind;
  bool isStart;

  ContentControlElement.fromJson(Map<String, dynamic> json)
      : startElements = (json['myStartElements'] as List)
            .map((item) => ContentControlElement.fromJson(item))
            .toList(),
        endElements = (json['myEndElements'] as List)
            .map((item) => ContentControlElement.fromJson(item))
            .toList(),
        kind = json['Kind'],
        isStart = json['IsStart'];
}
