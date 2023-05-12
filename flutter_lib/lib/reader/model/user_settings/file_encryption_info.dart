import 'package:flutter_lib/interface/debug_info_provider.dart';

import '../../../../utils/compare_helper.dart';

class FileEncryptionInfo with DebugInfoProvider {
  final String uri;
  final String method;
  final String algorithm;
  final String contentId;

  FileEncryptionInfo(
      {required this.uri,
      required this.method,
      required this.algorithm,
      required this.contentId});

  FileEncryptionInfo.fromJson(Map<String, dynamic> json)
      : uri = json['Uri'],
        method = json['Method'],
        algorithm = json['Algorithm'],
        contentId = json['ContentId'];

  @override
  int get hashCode {
    return CompareHelper.createHashCode(uri) +
        23 *
            (CompareHelper.createHashCode(method) +
                23 *
                    (CompareHelper.createHashCode(algorithm) +
                        23 * CompareHelper.createHashCode(contentId)));
  }

  @override
  bool operator ==(Object other) {
    return CompareHelper.equals(this, other);
  }

  @override
  void debugFillDescription(List<String> description) {
    description.add("uri: $uri");
    description.add("method: $method");
    description.add("algorithm: $algorithm");
    description.add("contentId: $contentId");
  }
}
