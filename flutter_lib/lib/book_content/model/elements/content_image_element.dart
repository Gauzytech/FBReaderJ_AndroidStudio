import 'package:flutter_lib/book_content/model/elements/content_element.dart';

class ContentImageElement extends ContentElement {
  final String id;
  // final ZLImageData imageData;
  final String url;
  final bool isCover;

  ContentImageElement.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        url = json['url'],
        isCover = json['isCover'];
}
