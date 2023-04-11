enum FontTypeFace {
  sans,
  serif,
  monospace,
}

class FontUtil {
  static FontTypeFace fontTypeFace(String fontFamily) {
    String fontStr = fontFamily.toLowerCase();
    if ("serif" == fontStr || "droid serif" == fontStr) {
      return FontTypeFace.serif;
    }
    if ("sans-serif" == fontStr ||
        "sans serif" == fontStr ||
        "droid sans" == fontStr) {
      return FontTypeFace.sans;
    }
    if ("monospace" == fontStr || "droid mono" == fontStr) {
      return FontTypeFace.monospace;
    }
    return FontTypeFace.sans;
  }
}
