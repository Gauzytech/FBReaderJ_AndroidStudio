
import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/utils/compare_helper.dart';

import 'file_encryption_info.dart';

class FileInfo with DebugInfoProvider {
  final String path;
  final FileEncryptionInfo encryptionInfo;

  FileInfo({required this.path, required this.encryptionInfo});

  FileInfo.fromJson(Map<String, dynamic> json)
      : path = json['Path'],
        encryptionInfo = FileEncryptionInfo.fromJson(json['EncryptionInfo']);

  static List<FileInfo>? fromJsonList(dynamic rawData) {
    return rawData != null
        ? (rawData as List)
            .map((item) => FileInfo.fromJson(item))
            .toList()
        : null;
  }

  @override
  bool operator ==(Object other) {
    if (other is! FileInfo) {
      return false;
    }
    return path == other.path &&
        CompareHelper.equals(encryptionInfo, other.encryptionInfo);
  }

  @override
  int get hashCode {
    return path.hashCode + 23 * CompareHelper.createHashCode(encryptionInfo);
  }

  @override
  void debugFillDescription(List<String> description) {
    description.add("path: $path");
    description.add("encryptionInfo: $encryptionInfo");
  }
}