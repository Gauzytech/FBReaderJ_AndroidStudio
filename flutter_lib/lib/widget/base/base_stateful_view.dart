import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:provider/provider.dart';

abstract class BaseStatefulView<M extends BaseViewModel>
    extends StatefulWidget {
  const BaseStatefulView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => buildState();

  BaseStatefulViewState<BaseStatefulView, M> buildState();
}

abstract class BaseStatefulViewState<T extends BaseStatefulView,
    M extends BaseViewModel> extends State<T> {
  M? viewModel;

  @override
  void initState() {
    super.initState();
    onInitState();
  }

  @override
  Widget build(BuildContext context) {
    viewModel = buildViewModel(context);

    if (isBindViewModel()) {
      print("viewModel, bind");
      return ChangeNotifierProvider<M>(
        create: (ctx) {
          loadData(ctx, viewModel);
          return viewModel!;
        },
        // Consumer widget 唯一必须的参数就是 builder。当 ChangeNotifier 发生变化的时候会调用 builder 这个函数。
        //（换言之，当你在模型中调用 notifyListeners() 时，所有和 Consumer 相关的 builder 方法都会被调用。）
        child: Consumer<M>(builder: (
          BuildContext ctx,
          /* ChangeNotifier 的实例 */
          viewModel,
          /* 用于优化目的。如果 Consumer 下面有一个庞大的子树，当模型发生改变的时候，该子树并不会改变，那么你就可以仅仅创建它一次，然后通过 builder 获得该实例 */
          Widget? child,
        ) {
          return onBuildView(ctx, viewModel);
        }),
      );
    } else {
      print("viewModel, not bind");
      loadData(context, viewModel);
      return onBuildView(context, viewModel);
    }
  }

  Widget onBuildView(BuildContext context, M? viewModel);

  /// 初始化数据
  void onInitState();

  M? buildViewModel(BuildContext context);

  /// 需要使用viewModel加载数据、或者页面刷新重新配置数据
  void loadData(BuildContext context, M? viewModel);

  bool isBindViewModel() {
    return true;
  }
}
