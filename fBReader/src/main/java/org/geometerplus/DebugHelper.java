package org.geometerplus;

import org.geometerplus.fbreader.bookmodel.FBTextKind;
import org.geometerplus.zlibrary.core.util.ZLColor;
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
   public static boolean ENABLE_PRELOAD_ADJACENT_PAGE = false;
   public static boolean ON_START_REPAINT = true;
   public static boolean ENABLE_FBLoadingDialog = false;
   public static boolean ENABLE_SET_SCREEN_BRIGHTNESS = true;
   public static boolean ENABLE_SET_ORIENTATION = true;
   public static boolean ENABLE_ON_BOOK_UPDATED = false;
   public static boolean SAVE_BITMAP = false;
   public static boolean ENABLE_SAF = false;

   public static String stringifyPatinState(int paintState) {
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

   public static boolean filterTag(String source, String... tags) {
      for (String tag : tags) {
         if (source.contains(tag)) {
            return true;
         }
      }
      return false;
   }

   public static ZLColor outlineColor() {
      return new ZLColor(66, 117, 245);
   }

   public static String stringifyControlKind(byte controlKind) {
      StringBuilder sb = new StringBuilder();
      if (controlKind == FBTextKind.REGULAR) {
         sb.append("REGULAR");
      } else if (controlKind == FBTextKind.TITLE) {
         sb.append("TITLE");
      } else if (controlKind == FBTextKind.SECTION_TITLE) {
         sb.append("SECTION_TITLE");
      } else if (controlKind == FBTextKind.POEM_TITLE) {
         sb.append("POEM_TITLE");
      } else if (controlKind == FBTextKind.SUBTITLE) {
         sb.append("SUBTITLE");
      } else if (controlKind == FBTextKind.ANNOTATION) {
         sb.append("ANNOTATION");
      } else if (controlKind == FBTextKind.EPIGRAPH) {
         sb.append("EPIGRAPH");
      } else if (controlKind == FBTextKind.STANZA) {
         sb.append("STANZA");
      } else if (controlKind == FBTextKind.VERSE) {
         sb.append("VERSE");
      } else if (controlKind == FBTextKind.PREFORMATTED) {
         sb.append("PREFORMATTED");
      } else if (controlKind == FBTextKind.IMAGE) {
         sb.append("IMAGE");
      } else if (controlKind == FBTextKind.CITE) {
         sb.append("CITE");
      } else if (controlKind == FBTextKind.AUTHOR) {
         sb.append("AUTHOR");
      } else if (controlKind == FBTextKind.DATE) {
         sb.append("DATE");
      } else if (controlKind == FBTextKind.INTERNAL_HYPERLINK) {
         sb.append("INTERNAL_HYPERLINK");
      } else if (controlKind == FBTextKind.FOOTNOTE) {
         sb.append("FOOTNOTE");
      } else if (controlKind == FBTextKind.EMPHASIS) {
         sb.append("EMPHASIS");
      } else if (controlKind == FBTextKind.STRONG) {
         sb.append("STRONG");
      } else if (controlKind == FBTextKind.SUB) {
         sb.append("SUB");
      } else if (controlKind == FBTextKind.SUP) {
         sb.append("SUP");
      } else if (controlKind == FBTextKind.CODE) {
         sb.append("CODE");
      } else if (controlKind == FBTextKind.STRIKETHROUGH) {
         sb.append("STRIKETHROUGH");
      } else if (controlKind == FBTextKind.ITALIC) {
         sb.append("ITALIC");
      } else if (controlKind == FBTextKind.BOLD) {
         sb.append("BOLD");
      } else if (controlKind == FBTextKind.DEFINITION) {
         sb.append("DEFINITION");
      } else if (controlKind == FBTextKind.DEFINITION_DESCRIPTION) {
         sb.append("DEFINITION_DESCRIPTION");
      } else if (controlKind == FBTextKind.H1) {
         sb.append("H1");
      } else if (controlKind == FBTextKind.H2) {
         sb.append("H2");
      } else if (controlKind == FBTextKind.H3) {
         sb.append("H3");
      } else if (controlKind == FBTextKind.H4) {
         sb.append("H4");
      } else if (controlKind == FBTextKind.H5) {
         sb.append("H5");
      } else if (controlKind == FBTextKind.H6) {
         sb.append("H6");
      } else if (controlKind == FBTextKind.XHTML_TAG_P) {
         sb.append("XHTML_TAG_P");
      } else {
         sb.append("UNKNOWN");
      }
      sb.append("(").append(controlKind).append(")");
      return sb.toString();
   }
}
