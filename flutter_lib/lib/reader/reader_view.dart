import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/reader_book_info.dart';
import 'package:flutter_lib/modal/reader_config_model.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/reader_content_view.dart';
import 'package:flutter_lib/widget/base/base_stateful_view.dart';

/// 整个阅读界面: 包括上部菜单栏, 下部菜单栏, 图书内容widget[ReaderContentView]
class ReaderView extends BaseStatefulView<ReaderViewModel> {
  const ReaderView({Key? key}) : super(key: key);

  @override
  BaseStatefulViewState<ReaderView, ReaderViewModel> buildState() => _ReaderState();
}

class _ReaderState extends BaseStatefulViewState<ReaderView, ReaderViewModel>
    with TickerProviderStateMixin {
  GlobalKey readerKey = GlobalKey();
  GlobalKey bottomMenuKey = GlobalKey();

  late ReaderConfigEntity configData;

  // NovelConfigManager _configManager;

  // AnimationController _controller;
  // bool _isMenuOpen = false;

  // NovelMenuState currentMenuState = NovelMenuState.STATE_SHOW_NORMAL;

  // PublishSubject<NovelMenuState> _menuStreamSubject;

  @override
  void onInitState() {
    // _controller = NovelMenuManager.createAnimationController(this);
    // _menuStreamSubject = PublishSubject();

    initConfig();
  }

  @override
  void loadData(BuildContext context, ReaderViewModel? viewModel) {
    // configData
    //   ..currentPageIndex = widget.bookInfo.currentPageIndex
    //   ..currentChapterIndex = widget.bookInfo.currentChapterIndex
    //   ..id = widget.bookInfo.bookId
    //   ..pageSize =
    //   Offset(ScreenUtils.getScreenWidth(), ScreenUtils.getScreenHeight());

    // 设置图书渲染的设置, 行高，字体等
    viewModel?.setConfigData(configData);

    // todo 请求进度, 未实现
    viewModel?.requestCatalog('test_book_id');
  }

  @override
  Widget onBuildView(BuildContext context, ReaderViewModel? viewModel) {
    ReaderViewModel readerViewModel =
        ArgumentError.checkNotNull(viewModel, 'ReaderViewModel');

    return Scaffold(
      body: SafeArea(
          child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                toggleMenu((isOpen) {
                  // if (!isOpen) {
                  //   currentMenuState = NovelMenuState.STATE_SHOW_NORMAL;
                  //   _menuStreamSubject.add(currentMenuState);
                  // }
                });
              },
              child: RepaintBoundary(
                child: ReaderContentView(
                  key: readerKey,
                ),
              ),
            ), ...buildMenus(readerViewModel),
          ],
        ),
      )),
    );
  }

  @override
  ReaderViewModel? buildViewModel(BuildContext context) {
    return ReaderViewModel(
        bookInfo: ReaderBookInfo());
  }

  @override
  void dispose() {
    print('flutter内容绘制流程, dispose1');
    super.dispose();
  }

  void initConfig() {
    configData = ReaderConfigEntity(id: 'test_id');
  }

  void toggleMenu(Function? finishCallback) {}

  List<Widget> buildMenus(ReaderViewModel viewModel) {
    return [];
  }
}
