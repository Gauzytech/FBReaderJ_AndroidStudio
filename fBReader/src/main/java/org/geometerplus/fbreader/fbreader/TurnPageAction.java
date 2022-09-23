/*
 * Copyright (C) 2007-2015 FBReader.ORG Limited <contact@fbreader.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

package org.geometerplus.fbreader.fbreader;

import org.geometerplus.fbreader.fbreader.options.PageTurningOptions;
import org.geometerplus.zlibrary.core.view.ZLViewEnums;

import timber.log.Timber;

class TurnPageAction extends FBAction {
    private final boolean myForward;

    TurnPageAction(FBReaderApp fbreader, boolean forward) {
        super(fbreader);
        myForward = forward;
    }

    @Override
    public boolean isEnabled() {
        final PageTurningOptions.FingerScrollingType fingerScrolling =
                Reader.PageTurningOptions.FingerScrolling.getValue();
        return
                fingerScrolling == PageTurningOptions.FingerScrollingType.byTap ||
                        fingerScrolling == PageTurningOptions.FingerScrollingType.byTapAndFlick;
    }

    @Override
    protected void run(Object... params) {
        final PageTurningOptions preferences = Reader.PageTurningOptions;
        Timber.v("点击翻页流程, %s", preferences);
        if (preferences.Animation.getValue() == ZLViewEnums.Animation.previewShift) {
            // 轻敲换页设置成没有动画
            preferences.Animation.setValue(ZLViewEnums.Animation.previewNone);
        }
        if (params.length == 2 && params[0] instanceof Integer && params[1] instanceof Integer) {
            final int x = (Integer) params[0];
            final int y = (Integer) params[1];
            Timber.v("点击翻页流程, start [%s, %s]", x, y);
            Reader.getViewWidget().startAnimatedScrolling(
                    myForward ? FBView.PageIndex.NEXT : FBView.PageIndex.PREV,
                    x, y,
                    preferences.Horizontal.getValue()
                            ? FBView.Direction.rightToLeft : FBView.Direction.up,
                    preferences.AnimationSpeed.getValue()
            );
        } else {
            Timber.v("点击翻页流程, start");
            Reader.getViewWidget().startAnimatedScrolling(
                    myForward ? FBView.PageIndex.NEXT : FBView.PageIndex.PREV,
                    preferences.Horizontal.getValue()
                            ? FBView.Direction.rightToLeft : FBView.Direction.up,
                    preferences.AnimationSpeed.getValue()
            );
        }
    }
}
