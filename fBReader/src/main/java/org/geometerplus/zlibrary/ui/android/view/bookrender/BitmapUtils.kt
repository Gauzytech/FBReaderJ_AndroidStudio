package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream


/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName BitmapUtils
 * @Date 5/1/22, 2:41 AM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */

fun Bitmap.toByteArray(): ByteArray {
    val baos = ByteArrayOutputStream()
    return try {
        this.compress(Bitmap.CompressFormat.PNG, 100, baos)
        baos.toByteArray()
    } finally {
        baos.close()
        this.recycle()
    }
}