import 'package:flutter/foundation.dart';

mixin DebugInfoProvider {

  void debugFillDescription(List<String> description);

  @override
  String toString() {
    List<String> description = [];
    description.add("$runtimeType");
    debugFillDescription(description);
    return '${describeIdentity(this)} (${description.join(", ")})';
  }
}
