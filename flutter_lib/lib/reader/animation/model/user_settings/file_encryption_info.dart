import '../../../../utils/compare_helper.dart';

class FileEncryptionInfo {
  final String uri;
  final String method;
  final String algorithm;
  final String contentId;

  FileEncryptionInfo(
      {required this.uri,
      required this.method,
      required this.algorithm,
      required this.contentId});

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
}
