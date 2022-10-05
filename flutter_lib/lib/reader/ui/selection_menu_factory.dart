import 'dart:ui' as ui;

import 'package:flutter/material.dart';

typedef MenuActionFunc = Function(SelectionItem menu);

enum SelectionItem {
  note,
  copy,
  search
}

class SelectionMenuFactory {
  static const selectionMenuSize = Size(200, 40);
  GlobalKey menuKey = GlobalKey();

  SelectionMenuFactory();

  Widget buildSelectionMenu(ValueSetter<SelectionItem> menuActionCallback) {
    double ratio = ui.window.devicePixelRatio;
    return Container(
      key: menuKey,
      width: selectionMenuSize.width * ratio,
      height: selectionMenuSize.height * ratio,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.black,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                menuActionCallback(SelectionItem.note);
              },
              onLongPress: () {},
              child: const Text('Note'),
            ),
          ),
          Expanded(
            child: TextButton(
              style: ButtonStyle(backgroundColor: createTextBtnBgColor()),
              onPressed: () {
                menuActionCallback(SelectionItem.copy);
              },
              onLongPress: () {},
              child: const Text(
                'Copy',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              menuActionCallback(SelectionItem.search);
            },
            onLongPress: () {},
            child: const Text('Search'),
          )),
        ],
      ),
    );
  }

  /// 处理点击按钮背景颜色
  /// 设置当前按钮为不可点击时，设置onPressed回调为null。
  MaterialStateProperty<ui.Color> createTextBtnBgColor() {
    return MaterialStateProperty.resolveWith((states) {
      // If the button is pressed, return green, otherwise blue
      if (states.contains(MaterialState.pressed)) {
        // 点击返回绿色
        return "#ff063c91".toColor();
      } else if (states.contains(MaterialState.disabled)) {
        return "#509cf6".toColor();
      }
      return Colors.black;
    });
  }
}

extension StringToColor on String {
  Color toColor() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}