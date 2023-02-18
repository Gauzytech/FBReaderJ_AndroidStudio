/// 页面索引（前两页，前一页，当前页，下一页，下两页）
enum PageIndex { prev_2, prev, current, next, next_2 }

extension PageIndexExtension on PageIndex {
  /// 获取下一页对应索引
  ///
  /// @return 下一页对应索引
  PageIndex? getNext() {
    switch (this) {
      case PageIndex.prev_2:
        return PageIndex.prev_2;
      case PageIndex.prev:
        return PageIndex.current;
      case PageIndex.current:
        return PageIndex.next;
      case PageIndex.next:
        return PageIndex.next_2;
      default:
        return null;
    }
  }

  /// 获取上一页对应索引
  ///
  /// @return 上一页对应索引
  PageIndex? getPrevious() {
    switch (this) {
      case PageIndex.next_2:
        return PageIndex.next;
      case PageIndex.next:
        return PageIndex.current;
      case PageIndex.current:
        return PageIndex.prev;
      case PageIndex.prev:
        return PageIndex.prev_2;
      default:
        return null;
    }
  }
}
