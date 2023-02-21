
/// 对应ZLTextPage.myTwoColumnView
enum ColumnMode {
  singleColumnView,
  twoColumnView;

  static ColumnMode create(bool isTwoColumnView) {
    if (isTwoColumnView) {
      return ColumnMode.twoColumnView;
    }
    return ColumnMode.singleColumnView;
  }
}