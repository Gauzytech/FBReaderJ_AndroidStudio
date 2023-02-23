

abstract class ContentStyleEntry {

   // final int depth;
   // short featureMask;
   //
   // List<Length> lengths;
   // int alignmentType;
   // List<fontEntry> fontEntries;
   // int supportedFontModifiers;
   // int fontModifiers;
   // int verticalAlignCode;
   //
   //
}


class Length {
   final int size;
   final int unit;

   Length.fromJson(Map<String, dynamic> json):
         size = json['Size'],
         unit = json['Unit'];

  @override
  String toString() {
    return "$size.$unit";
  }
}