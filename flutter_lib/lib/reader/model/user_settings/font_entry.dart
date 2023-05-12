import 'dart:core';

import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/model/user_settings/file_info.dart';
import 'package:flutter_lib/utils/compare_helper.dart';

const Map<String, FontEntry> _ourSystemEntries = {};

class FontEntry with DebugInfoProvider {
  // Map<String, FontEntry> ourSystemEntries = <String, FontEntry>{};
  String family;
  List<FileInfo>? fileInfos;

  static FontEntry systemEntry(String family) {
    // synchronized(ourSystemEntries) {
    FontEntry? entry = _ourSystemEntries[family];
    if (entry == null) {
      entry = FontEntry.fromFamily(family: family);
      _ourSystemEntries[family] = entry;
    }
    return entry;
    // }
  }

  FontEntry(this.family, FileInfo normal, FileInfo bold, FileInfo italic,
      FileInfo boldItalic) {
    fileInfos = [normal, bold, italic, boldItalic];
  }

  FontEntry.fromFamily({required this.family});

  FontEntry.fromJson(Map<String, dynamic> json)
      : family = json['Family'],
        fileInfos = FileInfo.fromJsonList(json['myFileInfos']);

  static List<FontEntry> fromJsonList(dynamic rawData) {
    return rawData != null
        ? (rawData as List).map((item) => FontEntry.fromJson(item)).toList()
        : [];
  }

  bool isSystem() => fileInfos == null;

  FileInfo? fileInfo(bool bold, bool italic) {
    return fileInfos != null
        ? fileInfos![(bold ? 1 : 0) + (italic ? 2 : 0)]
        : null;
  }

  @override
  bool operator ==(Object other) {
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

  @override
  void debugFillDescription(List<String> description) {
    description.add("family: $family");
    description.add("fileInfos: $fileInfos");
  }
}
