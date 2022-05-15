import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:provider/provider.dart';

abstract class BaseStatelessView<M extends BaseViewModel>
    extends StatelessWidget {
  const BaseStatelessView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    M? viewModel = buildViewModel(context);

    Widget resultWidget;
    if (viewModel != null) {
      resultWidget = ChangeNotifierProvider<M>(create: (context) {
        loadData(context, viewModel);
        return viewModel;
      }, child: Consumer<M>(
          builder: (BuildContext context, M viewModel, Widget? child) {
        return buildView(context, viewModel);
      }));
    } else {
      loadData(context, null);
      resultWidget = buildView(context, null);
    }
    return resultWidget;
  }

  Widget buildView(BuildContext context, M? viewModel);

  /// 为什么buildViewModel方法要放以一个抽象自己构建出来？直接让父Widget构建出来传过来不更好么？
  /// 因为我发现像tabLayout会触发viewModel的dispose方法……但是如果以父widget传入，那么viewModel是final的，自然会触发已经dispose的provider不能再次绑定的错误
  M? buildViewModel(BuildContext context);

  /// 需要使用viewModel加载数据、或者页面刷新重新配置数据
  void loadData(BuildContext context, M? viewModel);

  bool isEnableLoadingView() {
    return false;
  }
}
