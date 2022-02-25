package org.geometerplus;

import org.geometerplus.zlibrary.text.view.PaintStateEnum;

/**
 * @Package org.geometerplus.zlibrary.text.view
 * @FileName DebugStringHelper
 * @Date 2/20/22, 7:48 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public class DebugStringHelper {

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
}
