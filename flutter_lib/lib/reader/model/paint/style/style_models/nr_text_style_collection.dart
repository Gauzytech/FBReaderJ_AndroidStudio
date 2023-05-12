import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/model/paint/style/nr_text_base_style.dart';
import 'package:flutter_lib/reader/model/paint/style/style_models/nr_text_ng_style_description.dart';

class NRTextStyleCollection with DebugInfoProvider {
  final String screen;

  NRTextBaseStyle get baseStyle => _baseStyle;
  final NRTextBaseStyle _baseStyle;

  List<NRTextNGStyleDescription> get descriptionList => _descriptionList;
  final List<NRTextNGStyleDescription> _descriptionList;

  List<NRTextNGStyleDescription?> _descriptionMap = List.filled(256, null);

  NRTextStyleCollection.fromJson(Map<String, dynamic> json)
      : screen = json['Screen'],
        _baseStyle = NRTextBaseStyle.fromJson(json['myBaseStyle']),
        _descriptionList =
            NRTextNGStyleDescription.fromJsonList(json['myDescriptionList']),
        _descriptionMap = NRTextNGStyleDescription.fromJsonListNullable(
            json['myDescriptionMap'] as List);

  NRTextNGStyleDescription? getDescription(int kind) =>
      _descriptionMap[kind & 0xFF];

  @override
  void debugFillDescription(List<String> description) {
    description.add("screen: $screen");
    description.add("baseStyle: $_baseStyle");
    description.add("descriptionList: $_descriptionList");
    description.add("descriptionMap: $_descriptionMap");
  }


}
