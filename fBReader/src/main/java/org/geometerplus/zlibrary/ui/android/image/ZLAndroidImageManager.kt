package org.geometerplus.zlibrary.ui.android.image

import org.geometerplus.zlibrary.core.image.ZLImage
import org.geometerplus.zlibrary.core.image.ZLImageManager
import org.geometerplus.zlibrary.core.image.ZLImageProxy
import org.geometerplus.zlibrary.core.image.ZLImageProxy.Synchronizer
import org.geometerplus.zlibrary.core.image.ZLStreamImage
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.util.*

/**
 * @Package org.geometerplus.zlibrary.ui.android.image
 * @FileName ZLAndroidImageManager
 * @Date 3/5/23, 9:47 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
class ZLAndroidImageManager : ZLImageManager() {

    override fun getImageData(image: ZLImage): ZLAndroidImageData {
        return when (image) {
            is ZLImageProxy -> getImageData(image.realImage)
            is ZLStreamImage -> InputStreamImageData(image)
            is ZLBitmapImage -> BitmapImageData.get(image)
            else -> throw IllegalArgumentException("未知image类型: ${image.javaClass.simpleName}")
        }
    }

    override fun writeImageToCache(path: String, entryId: String, image: ZLImage): String {
        // 文件名就是entryId, eg: EPUB_images_00001.jpeg
        val fileName = entryId.replace("/", "_")
        val cacheFilePath = path + File.separator + fileName
        val targetFile = File(cacheFilePath)
        if (targetFile.parentFile?.exists() == false) {
            targetFile.parentFile?.mkdirs()
        }
        Timber.v("解析缓存流程: fileName = $cacheFilePath")
        check(image is ZLStreamImage) { "$image 不是ZLStreamImage" }
        if (!targetFile.exists()) {
            targetFile.createNewFile()
            image.inputStream().use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                }
            }
        }

        return cacheFilePath
    }

    private var myLoader: ZLAndroidImageLoader? = null

    fun startImageLoading(
        syncronizer: Synchronizer,
        image: ZLImageProxy,
        postLoadingRunnable: Runnable
    ) {
        if (myLoader == null) {
            myLoader = ZLAndroidImageLoader()
        }
        myLoader?.startImageLoading(syncronizer, image, postLoadingRunnable)
    }
}