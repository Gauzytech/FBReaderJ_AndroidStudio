import 'dart:convert';
import 'dart:core';

import 'package:flutter_lib/reader/animation/model/user_settings/file_info.dart';
import 'package:flutter_lib/utils/compare_helper.dart';

class FontEntry {

  Map<String, FontEntry> ourSystemEntries = <String, FontEntry>{};
  String family;
  List<FileInfo>? fileInfos;

  FontEntry? systemEntry(String family) {
    // synchronized(ourSystemEntries) {
    FontEntry? entry = ourSystemEntries[family];
    if (entry == null) {
      entry = FontEntry.fromFamily(family: family);
      ourSystemEntries[family] = entry;
    }
    return entry;
    // }
  }

  FontEntry(this.family, FileInfo normal, FileInfo bold, FileInfo italic,
      FileInfo boldItalic) {
    fileInfos = [normal, bold, italic, boldItalic];
  }

  FontEntry.fromFamily({required this.family}) {
    fileInfos = null;
  }

  FontEntry.fromJson(Map<String, dynamic> json)
      : ourSystemEntries = Map.castFrom(jsonDecode(json['ourSystemEntries'])),
        family = json['Family'],
        fileInfos = (json['myFileInfos'] as List)
            .map((item) => FileInfo.fromJson(item))
            .toList();

  bool isSystem() {
    return fileInfos == null;
  }

  FileInfo? fileInfo(bool bold, bool italic) {
    return fileInfos != null
        ? fileInfos![(bold ? 1 : 0) + (italic ? 2 : 0)]
        : null;
  }

  @override
  bool operator ==(Object other) {
    if (other == this) {
      return true;
    }
    if (other is! FontEntry) {
      return false;
    }
    final FontEntry entry = other;
    if (!CompareHelper.equals(family, entry.family)) {
      return false;
    }
    if (fileInfos == null) {
      return entry.fileInfos == null;
    }
    if (entry.fileInfos == null) {
      return false;
    }
    for (int i = 0; i < fileInfos!.length; ++i) {
      if (!CompareHelper.equals(fileInfos![i], entry.fileInfos![i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => CompareHelper.createHashCode(family);
}
