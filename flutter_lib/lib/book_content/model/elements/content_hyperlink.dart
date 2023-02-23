/// 对应ZLTextHyperlink
class ContentHyperlink {
  final int type;
  final String? id;
  List<int> _elementIndexes = [];
  final ContentHyperlink NO_LINK = ContentHyperlink(type: 0, id: null);

  ContentHyperlink({required this.type, required this.id});

  ContentHyperlink.fromJson(Map<String, dynamic> json)
      : type = json['Type'],
        id = json['Id'];
}
