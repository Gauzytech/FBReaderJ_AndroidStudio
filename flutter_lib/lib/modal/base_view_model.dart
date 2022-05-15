import 'package:flutter/material.dart';

enum LoadingStateEnum { LOADING, IDLE, ERROR }

/// 对model的数据进行处理，是跟view逻辑相关的部分
abstract class BaseViewModel extends BaseProvider {
  LoadingStateEnum isLoading = LoadingStateEnum.IDLE;

  bool isDisposed = false;

  @protected
  void refreshRequestState(LoadingStateEnum state) {
    isLoading = state;
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }
}


abstract class BaseProvider extends ChangeNotifier {

  Widget? getProviderContainer();

}