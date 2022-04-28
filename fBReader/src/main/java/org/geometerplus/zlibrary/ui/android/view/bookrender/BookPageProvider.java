package org.geometerplus.zlibrary.ui.android.view.bookrender;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PaintFlagsDrawFilter;
import android.graphics.Path;

import org.geometerplus.zlibrary.core.util.SystemInfo;
import org.geometerplus.zlibrary.core.view.ZLView;
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext;
import org.geometerplus.zlibrary.ui.android.view.animation.AnimationProvider;
import org.geometerplus.zlibrary.ui.android.view.callbacks.BookMarkCallback;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import timber.log.Timber;

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName BookPageProvider
 * @Date 4/24/22, 12:06 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public class BookPageProvider {

   private final SystemInfo mySystemInfo;

   public BookPageProvider(SystemInfo systemInfo) {
      mySystemInfo = systemInfo;
   }

   /**
    * 在Bitmap上绘制
    * 创建一个空白的canvas, 将当前页的内容绘制在canvas上面
    *
    * @param bitmap Bitmap
    * @param index  页面索引
    */
   public void drawOnBitmap(ZLView view, Bitmap bitmap, ZLView.PageIndex index, int width, int height, int mainAreaHeight, int verticalScrollbarWidth) {
      Timber.v("渲染流程, drawOnBitmap -> getCurrentView");

      final ZLAndroidPaintContext context = new ZLAndroidPaintContext(
              mySystemInfo,
              // 以bitmap类为参数创建一个Canvas类
              // 代码通过Canvas类对bitmap类进行操作
              new Canvas(bitmap),
              new ZLAndroidPaintContext.Geometry(
                      width,
                      height,
                      width,
                      mainAreaHeight,
                      0,
                      0
              ),
              view.isScrollbarShown() ? verticalScrollbarWidth : 0
      );
      view.paint(context, index);
   }

   /**
    * 准备上一页/下一页
    */
   public void preparePage(ZLView view, ZLView.PageIndex index, int width, int height, int mainAreaHeight, int verticalScrollbarWidth) {
      final ZLAndroidPaintContext context = new ZLAndroidPaintContext(
              mySystemInfo,
              new Canvas(),
              new ZLAndroidPaintContext.Geometry(
                      width,
                      height,
                      width,
                      mainAreaHeight,
                      0,
                      0
              ),
              view.isScrollbarShown() ? verticalScrollbarWidth : 0
      );

      // 准备上一页/下一页
      view.preparePage(context, index);
   }

}
