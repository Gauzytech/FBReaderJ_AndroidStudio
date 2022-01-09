package org.geometerplus.android.fbreader.ui.activity;

import android.content.Context;
import android.os.Bundle;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.geometerplus.android.fbreader.FBReader;
import org.geometerplus.android.fbreader.libraryService.BookCollectionShadow;
import org.geometerplus.fbreader.book.Book;
import org.geometerplus.zlibrary.ui.android.R;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

import timber.log.Timber;

/**
 * 图书内置打开页
 */
public class BookEnterActivity extends AppCompatActivity {
    String[] name = {"reader.epub",
            "毛泽东选集-全五卷.epub",
            "JavaScript高级程序设计（第3版） - [美] Nicholas C. Zakas.epub",
            "魔法使之夜（汉化）.epub"};

    // 这是一个bind service, 其实可以换成别的
    private final BookCollectionShadow myCollection = new BookCollectionShadow();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_book_enter);

        startBook();
    }

    public void startBook() {
        Timber.v("ceshi123, 开始获取图书数据");
        myCollection.bindToService(this, () -> {
            // 通过AIDL接口调用数据库，获取之前阅读的图书信息
            int idx = 2;
            String targetPath = "/data/data/org.geometerplus.zlibrary.ui.android/files/" + name[idx];
            Book book = myCollection.getBookByFile(targetPath);

            if (book == null) {
                Timber.v("ceshi123, 无数据, 获取asset demo图书");
                String path = copy2Storage(idx);
                System.out.println(path);
                book = myCollection.getBookByFile(path);
            }
            if (book != null) {
                Timber.v("ceshi123, 数据获取成功, FBReader library -> 解析并打开");
                // 调用FbReader开始解析图书， 并且打开阅读界面
                FBReader.openBookActivity(BookEnterActivity.this, book, null);
                finish();
            } else {
                Toast.makeText(BookEnterActivity.this, "获取内置epub失败，请检查", Toast.LENGTH_SHORT).show();
            }
        });
    }

    /**
     * @param assetsName 要复制的文件名
     * @param savePath   要保存的路径
     * @param saveName   复制后的文件名
     *                   testCopy(Context context)是一个测试例子。
     */
    public void copy(Context context, String assetsName, String savePath, String saveName) {
        String filename = savePath + "/" + saveName;
        File dir = new File(savePath);
        // 如果目录不中存在，创建这个目录
        if (!dir.exists())
            dir.mkdir();
        try {
            if (!(new File(filename)).exists()) {
                InputStream is = context.getResources().getAssets().open(assetsName);
                FileOutputStream fos = new FileOutputStream(filename);
                byte[] buffer = new byte[1024];
                int count;
                while ((count = is.read(buffer)) > 0) {
                    fos.write(buffer, 0, count);
                }
                fos.close();
                is.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 复制
     */
    public String copy2Storage(int idx) {
        String path = getFilesDir().getAbsolutePath();
        copy(this, name[idx], path, name[idx]);
        return path + File.separator + name[idx];
    }
}
