import 'dart:core';

import 'package:flutter_lib/reader/animation/model/user_settings/file_info.dart';
import 'package:flutter_lib/utils/compare_helper.dart';

class FontEntry {

  Map<String, FontEntry> ourSystemEntries = <String, FontEntry>{};
  String family;
  List<FileInfo>? myFileInfos;

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
    myFileInfos = [normal, bold, italic, boldItalic];
  }

  FontEntry.fromFamily({required this.family}) {
    myFileInfos = null;
  }

  bool isSystem() {
    return myFileInfos == null;
  }

  FileInfo? fileInfo(bool bold, bool italic) {
    return myFileInfos != null
        ? myFileInfos![(bold ? 1 : 0) + (italic ? 2 : 0)]
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
    if (myFileInfos == null) {
      return entry.myFileInfos == null;
    }
    if (entry.myFileInfos == null) {
      return false;
    }
    for (int i = 0; i < myFileInfos!.length; ++i) {
      if (!CompareHelper.equals(myFileInfos![i], entry.myFileInfos![i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => CompareHelper.createHashCode(family);
}
