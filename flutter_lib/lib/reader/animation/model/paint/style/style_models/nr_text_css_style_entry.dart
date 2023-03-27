import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_entry.dart';

class NRTextCSSStyleEntry extends NRTextStyleEntry {
  NRTextCSSStyleEntry(int depth) : super(depth);

  NRTextCSSStyleEntry.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);
}
