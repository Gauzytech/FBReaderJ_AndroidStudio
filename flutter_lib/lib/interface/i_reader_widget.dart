import '../modal/Direction.dart';
import '../modal/PageIndex.dart';

class IReaderWidget {
  /// 重置缓存索引
  /// @see BitmapManagerImpl
  void reset(String from) {}

  void repaint(String from) {}

  void startManualScrolling(int x, int y, Direction direction) {}

  void scrollManuallyTo(int x, int y) {}

  void startAnimatedScrolling1(
      PageIndex pageIndex, int x, int y, Direction direction, int speed) {}

  void startAnimatedScrolling2(
      PageIndex pageIndex, Direction direction, int speed) {}

  void startAnimatedScrolling3(int x, int y, int speed) {}

  void setScreenBrightness(int percent) {}

  int getScreenBrightness() {
    throw UnimplementedError();
  }
}
