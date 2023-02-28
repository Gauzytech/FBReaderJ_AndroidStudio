package org.geometerplus.zlibrary.ui.android.view.bookrender

import android.graphics.Bitmap
import timber.log.Timber
import java.io.ByteArrayOutputStream
import java.io.InputStream


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

fun InputStream.convertToString(): String? {
    val out = StringBuilder()
    val b = ByteArray(4096)
    try {
        var n: Int
        while (this.read(b).also { n = it } != -1) {
            out.append(String(b, 0, n))
        }
        return out.toString()
    } catch (e: Exception) {
        Timber.e(e)
    }
    return null
}