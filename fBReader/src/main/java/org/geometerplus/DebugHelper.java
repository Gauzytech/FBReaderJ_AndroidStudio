package org.geometerplus;

import org.geometerplus.zlibrary.text.view.PaintStateEnum;

/**
 * @Package org.geometerplus.zlibrary.text.view
 * @FileName DebugHelper
 * @Date 2/20/22, 7:48 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public class DebugHelper {
   public static boolean ENABLE_FLUTTER = true;
   public static boolean FOOTER_PAGE_COUNT_ENABLE = false;
   public static boolean PRELOAD_NEXT_PREV_PAGE_ENABLE = false;
   public static boolean ON_START_REPAINT = true;
   public static boolean ENABLE_FBLoadingDialog = false;
   public static boolean ENABLE_SET_SCREEN_BRIGHTNESS = true;
   public static boolean ENABLE_SET_ORIENTATION = true;
   public static boolean ENABLE_ON_BOOK_UPDATED = false;
   public static boolean SAVE_BITMAP = false;

   public static String getPatinStateStr(int paintState) {

      if (paintState == PaintStateEnum.NOTHING_TO_PAINT) {
         return "NOTHING_TO_PAINT";
      } else if (paintState == PaintStateEnum.READY) {
         return "READY";
      } else if (paintState == PaintStateEnum.START_IS_KNOWN) {
         return "START_IS_KNOWN";
      } else if (paintState == PaintStateEnum.END_IS_KNOWN) {
         return "END_IS_KNOWN";
      } else if (paintState == PaintStateEnum.TO_SCROLL_FORWARD) {
         return "TO_SCROLL_FORWARD";
      } else if (paintState == PaintStateEnum.TO_SCROLL_BACKWARD) {
         return "TO_SCROLL_BACKWARD";
      }

      return null;
   }

   public static boolean filterTag(String source, String tag) {
      return source.contains(tag);
   }
}
