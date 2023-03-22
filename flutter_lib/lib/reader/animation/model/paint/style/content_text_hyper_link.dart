class ContentTextHyperLink {
  final int _type;
  final String? _id;

  List<int>? _elementIndexes;

  static final ContentTextHyperLink noLink = ContentTextHyperLink(0, null);

  ContentTextHyperLink(int type, String? id)
      : _type = type,
        _id = id;

  ContentTextHyperLink.fromJson(Map<String, dynamic> json)
      : _type = json['Type'],
        _id = json['Id'],
        _elementIndexes = json['myElementIndexes'];
}
