class NRTextHyperLink {
  final int _type;
  final String? _id;

  List<int>? _elementIndexes;

  static final NRTextHyperLink noLink = NRTextHyperLink(0, null);

  NRTextHyperLink(int type, String? id)
      : _type = type,
        _id = id;

  NRTextHyperLink.fromJson(Map<String, dynamic> json)
      : _type = json['Type'],
        _id = json['Id'],
        _elementIndexes = json['myElementIndexes'] != null
            ? (json['myElementIndexes'] as List)
                .map((item) => item as int)
                .toList()
            : null;
}
