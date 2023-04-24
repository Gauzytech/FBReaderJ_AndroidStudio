/*
 * Copyright (C) 2009-2015 FBReader.ORG Limited <contact@fbreader.org>
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

package org.geometerplus.zlibrary.core.view;

import android.graphics.Rect;

import org.geometerplus.zlibrary.ui.android.view.bookrender.model.HighlightCoord;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;

import timber.log.Timber;

public final class HorizontalConvexHull implements Hull {

    private final LinkedList<Rect> myRectangles = new LinkedList<>();

    public HorizontalConvexHull(Collection<Rect> rects) {
        for (Rect r : rects) {
            addRect(r);
        }
        normalize();
    }

    private void addRect(Rect rectangle) {
        if (myRectangles.isEmpty()) {
            myRectangles.add(new Rect(rectangle));
            return;
        }
        final int top = rectangle.top;
        final int bottom = rectangle.bottom;
        for (ListIterator<Rect> iter = myRectangles.listIterator(); iter.hasNext(); ) {
            Rect r = iter.next();
            if (r.bottom <= top) {
                continue;
            }
            if (r.top >= bottom) {
                break;
            }
            if (r.top < top) {
                final Rect before = new Rect(r);
                before.bottom = top;
                r.top = top;
                iter.previous();
                iter.add(before);
                iter.next();
            }
            if (r.bottom > bottom) {
                final Rect after = new Rect(r);
                after.top = bottom;
                r.bottom = bottom;
                iter.add(after);
            }
            r.left = Math.min(r.left, rectangle.left);
            r.right = Math.max(r.right, rectangle.right);
        }

        final Rect first = myRectangles.getFirst();
        if (top < first.top) {
            myRectangles.add(0, new Rect(rectangle.left, top, rectangle.right, Math.min(bottom, first.top)));
        }

        final Rect last = myRectangles.getLast();
        if (bottom > last.bottom) {
            myRectangles.add(new Rect(rectangle.left, Math.max(top, last.bottom), rectangle.right, bottom));
        }
    }

    private void normalize() {
        Rect previous = null;
        for (ListIterator<Rect> iter = myRectangles.listIterator(); iter.hasNext(); ) {
            final Rect current = iter.next();
            if (previous != null) {
                if ((previous.left == current.left) && (previous.right == current.right)) {
                    previous.bottom = current.bottom;
                    iter.remove();
                    continue;
                }
                if ((previous.bottom != current.top) &&
                        (current.left <= previous.right) &&
                        (previous.left <= current.right)) {
                    iter.previous();
                    iter.add(new Rect(
                            Math.max(previous.left, current.left),
                            previous.bottom,
                            Math.min(previous.right, current.right),
                            current.top
                    ));
                    iter.next();
                }
            }
            previous = current;
        }
    }

    public int distanceTo(int x, int y) {
        int distance = Integer.MAX_VALUE;
        for (Rect r : myRectangles) {
            final int xd = r.left > x ? r.left - x : (r.right < x ? x - r.right : 0);
            final int yd = r.top > y ? r.top - y : (r.bottom < y ? y - r.bottom : 0);
            distance = Math.min(distance, Math.max(xd, yd));
            if (distance == 0) {
                break;
            }
        }
        return distance;
    }

    public boolean isBefore(int x, int y) {
        for (Rect r : myRectangles) {
            if (r.bottom < y || (r.top < y && r.right < x)) {
                return true;
            }
        }
        return false;
    }

    public void draw(ZLPaintContext context, int mode) {
        if (mode == DrawMode.None) {
            return;
        }
        Timber.v("长按选中流程[HorizontalConvexHull], mode = %s", mode);
        final LinkedList<Rect> rectangles = new LinkedList<>(myRectangles);

        Timber.v("长按选中流程[HorizontalConvexHull], rectangles = %s", rectangles.size());
        while (!rectangles.isEmpty()) {
            final LinkedList<Rect> connected = new LinkedList<>();
            Rect previous = null;
            for (final Iterator<Rect> iterator = rectangles.iterator(); iterator.hasNext(); ) {
                final Rect current = iterator.next();
                if ((previous != null) && ((previous.left > current.right) || (current.left > previous.right))) {
                    break;
                }
                iterator.remove();
                connected.add(current);
                previous = current;
            }

            final LinkedList<Integer> xList = new LinkedList<>();
            final LinkedList<Integer> yList = new LinkedList<>();
            int x, xPrev;

            final ListIterator<Rect> iterator = connected.listIterator();
            Rect r = iterator.next();
            x = r.right + 2;
            xList.add(x);
            yList.add(r.top);
            while (iterator.hasNext()) {
                xPrev = x;
                r = iterator.next();
                x = r.right + 2;
                if (x != xPrev) {
                    final int y = (x < xPrev) ? r.top + 2 : r.top;
                    xList.add(xPrev);
                    yList.add(y);
                    xList.add(x);
                    yList.add(y);
                }
            }
            xList.add(x);
            yList.add(r.bottom + 2);

            r = iterator.previous();
            x = r.left - 2;
            xList.add(x);
            yList.add(r.bottom + 2);
            while (iterator.hasPrevious()) {
                xPrev = x;
                r = iterator.previous();
                x = r.left - 2;
                if (x != xPrev) {
                    final int y = (x > xPrev) ? r.bottom : r.bottom + 2;
                    xList.add(xPrev);
                    yList.add(y);
                    xList.add(x);
                    yList.add(y);
                }
            }
            xList.add(x);
            yList.add(r.top);

            final int[] xs = new int[xList.size()];
            final int[] ys = new int[yList.size()];
            int count = 0;
            for (int xx : xList) {
                xs[count++] = xx;
            }
            count = 0;
            for (int yy : yList) {
                ys[count++] = yy;
            }

            // 绘制选中区域
            if ((mode & DrawMode.Fill) == DrawMode.Fill) {
                context.fillPolygon(xs, ys);
            }
            if ((mode & DrawMode.Outline) == DrawMode.Outline) {
                StringBuilder sb = new StringBuilder("xs = ");
                for (int i : xs) {
                    sb.append(i + ",");
                }
                sb.deleteCharAt(sb.length() - 1);
                sb.append(" ys = ");
                for (int i : ys) {
                    sb.append(i + ",");
                }
                Timber.v("长按选中流程[HorizontalConvexHull], %s", sb);
                context.drawOutline(xs, ys);
            }
        }
    }

    @Override
    public List<HighlightCoord> getDrawHighlightCoordinates(int mode) {
        List<HighlightCoord> coordinates = new ArrayList<>();

        if (mode == DrawMode.None) {
            return coordinates;
        }
        final LinkedList<Rect> rectangles = new LinkedList<>(myRectangles);

        while (!rectangles.isEmpty()) {
            final LinkedList<Rect> connected = new LinkedList<>();
            Rect previous = null;
            for (final Iterator<Rect> iterator = rectangles.iterator(); iterator.hasNext(); ) {
                final Rect current = iterator.next();
                if ((previous != null) && ((previous.left > current.right) || (current.left > previous.right))) {
                    break;
                }
                iterator.remove();
                connected.add(current);
                previous = current;
            }

            final LinkedList<Integer> xList = new LinkedList<>();
            final LinkedList<Integer> yList = new LinkedList<>();
            int x, xPrev;

            final ListIterator<Rect> iterator = connected.listIterator();
            Rect r = iterator.next();
            x = r.right + 2;
            xList.add(x);
            yList.add(r.top);
            while (iterator.hasNext()) {
                xPrev = x;
                r = iterator.next();
                x = r.right + 2;
                if (x != xPrev) {
                    final int y = (x < xPrev) ? r.top + 2 : r.top;
                    xList.add(xPrev);
                    yList.add(y);
                    xList.add(x);
                    yList.add(y);
                }
            }
            xList.add(x);
            yList.add(r.bottom + 2);

            r = iterator.previous();
            x = r.left - 2;
            xList.add(x);
            yList.add(r.bottom + 2);
            while (iterator.hasPrevious()) {
                xPrev = x;
                r = iterator.previous();
                x = r.left - 2;
                if (x != xPrev) {
                    final int y = (x > xPrev) ? r.bottom : r.bottom + 2;
                    xList.add(xPrev);
                    yList.add(y);
                    xList.add(x);
                    yList.add(y);
                }
            }
            xList.add(x);
            yList.add(r.top);

            final int[] xs = new int[xList.size()];
            final int[] ys = new int[yList.size()];
            int count = 0;
            for (int xx : xList) {
                xs[count++] = xx;
            }
            count = 0;
            for (int yy : yList) {
                ys[count++] = yy;
            }

            // 绘制选中区域
            if ((mode & DrawMode.Fill) == DrawMode.Fill) {
                coordinates.add(new HighlightCoord(DrawMode.Fill, xs.clone(), ys.clone()));
            }

            if ((mode & DrawMode.Outline) == DrawMode.Outline) {
                coordinates.add(new HighlightCoord(DrawMode.Outline, xs.clone(), ys.clone()));
            }
        }

        return coordinates;
    }
}