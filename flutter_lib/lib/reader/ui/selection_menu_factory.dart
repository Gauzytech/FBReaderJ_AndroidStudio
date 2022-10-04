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

  SelectionMenuFactory();

  Widget buildSelectionMenu(ValueSetter<SelectionItem> menuActionCallback) {
    double ratio = ui.window.devicePixelRatio;
    return Container(
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
              child: const Text('Note'),
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
                menuActionCallback(SelectionItem.copy);
              },
              child: const Text('Copy'),
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
            child: const Text('Search'),
          )),
        ],
      ),
    );
  }
}
