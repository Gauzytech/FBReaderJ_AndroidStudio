import 'package:flutter/foundation.dart';

mixin DebugInfoProvider {

  void debugFillDescription(List<String> description);

  @override
  String toString() {
    List<String> description = [];
    debugFillDescription(description);
    return '${describeIdentity(this)} (${description.join(", ")})';
  }
}
