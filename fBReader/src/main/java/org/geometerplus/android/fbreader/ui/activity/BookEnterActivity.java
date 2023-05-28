package org.geometerplus.android.fbreader.ui.activity;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.geometerplus.DebugHelper;
import org.geometerplus.android.fbreader.FBReader;
import org.geometerplus.android.fbreader.libraryService.BookCollectionShadow;
import org.geometerplus.fbreader.book.Book;
import org.geometerplus.zlibrary.ui.android.R;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.annotations.NonNull;
import io.reactivex.rxjava3.core.Single;
import io.reactivex.rxjava3.core.SingleObserver;
import io.reactivex.rxjava3.core.SingleOnSubscribe;
import io.reactivex.rxjava3.disposables.CompositeDisposable;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.schedulers.Schedulers;
import timber.log.Timber;

/**
 * 图书内置打开页
 */
public class BookEnterActivity extends AppCompatActivity {
    String[] name = {
            "reader.epub",
            "毛泽东选集-全五卷.epub",
            "JavaScript高级程序设计（第3版） - [美] Nicholas C. Zakas.epub",
            "魔法使之夜（汉化）.epub",
            "我所爱的香港.epub"};
    public static final int REQUEST_CODE_FOR_SINGLE_FILE = 100;
    public static final String ROOT = "/data/data/org.geometerplus.zlibrary.ui.android/files/";

    // 这是一个bind service, 其实可以换成别的
    private final BookCollectionShadow myCollection = new BookCollectionShadow();
    private ProgressDialog dialog;
    private CompositeDisposable onStopDisposable = new CompositeDisposable();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_book_enter);

        startBook();
    }

    public void startBook() {
        Timber.v("图书导入, 开始获取图书数据");
        myCollection.bindToService(this, () -> {
            if (DebugHelper.ENABLE_SAF) {
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("application/epub+zip");
                startActivityForResult(intent, REQUEST_CODE_FOR_SINGLE_FILE);
            } else {
                // 通过AIDL接口调用数据库，获取之前阅读的图书信息
                int idx = 1;
                Book book = myCollection.getBookByFile(ROOT + name[idx]);

                if (book == null) {
                    Timber.v("打开图书, 无数据, 获取asset demo图书");
                    String path = copy2Storage(idx);
                    System.out.println(path);
                    book = myCollection.getBookByFile(path);
                }
                if (book != null) {
                    Timber.v("打开图书, 数据获取成功, FBReader library -> 解析并打开");
                    // 调用FbReader开始解析图书， 并且打开阅读界面
                    FBReader.openBookActivity(BookEnterActivity.this, book, null);
                    finish();
                } else {
                    Toast.makeText(BookEnterActivity.this, "获取内置epub失败，请检查", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_FOR_SINGLE_FILE && resultCode == Activity.RESULT_OK) {
            Single.create((SingleOnSubscribe<Book>) emitter -> {
                        if (data != null) {
                            Uri uri = data.getData();
                            Cursor cursor = getContentResolver().query(uri, null, null, null, null);
                            String fileName = null;
                            if (cursor != null && cursor.moveToFirst()) {
                                fileName = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
                                cursor.close();
                            }

                            if (fileName != null) {
                                Timber.v("图书导入, fileName = %s", fileName);
                                Book book = importBook(uri, fileName);
                                if (book != null) {
                                    emitter.onSuccess(book);
                                } else {
                                    emitter.onError(new IllegalArgumentException("获取图书失败"));
                                }
                            } else {
                                emitter.onError(new IllegalArgumentException("获取书名失败"));
                            }
                        } else {
                            emitter.onError(new IllegalArgumentException("无法获取选中图书数据"));
                        }
                    })
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .doFinally(() -> dialog.dismiss())
                    .subscribe(new SingleObserver<Book>() {
                        @Override
                        public void onSubscribe(@NonNull Disposable d) {
                            onStopDisposable.add(d);
                            dialog = new ProgressDialog(BookEnterActivity.this);
                            dialog.setTitle("加载图书");
                            dialog.setMessage("等待中");
                            dialog.show();
                        }

                        @Override
                        public void onSuccess(@NonNull Book book) {
                            Timber.v("图书导入, 数据获取成功, FBReader library -> 解析并打开");
                            // 调用FbReader开始解析图书， 并且打开阅读界面
                            FBReader.openBookActivity(BookEnterActivity.this, book, null);
                            finish();
                        }

                        @Override
                        public void onError(@NonNull Throwable e) {
                            Timber.e(e);
                            Toast.makeText(BookEnterActivity.this, e.getMessage(), Toast.LENGTH_SHORT).show();
                        }
                    });
        }
    }

    private Book importBook(Uri uri, String fileName) {
        Book book = myCollection.getBookByFile(ROOT + fileName);
        if (book == null) {
            String path = getPathFromInputStreamUri(uri, fileName);
            Timber.v("图书导入, 将epub文件拷贝到: %s", path);
            if (path != null) {
                book = myCollection.getBookByFile(path);
            }
        }

        return book;
    }

    /**
     * 用流拷贝文件一份到自己APP目录下
     */
    @Nullable
    public String getPathFromInputStreamUri(Uri uri, String fileName) {
        InputStream inputStream = null;
        if (uri.getAuthority() != null) {
            try {
                inputStream = getContentResolver().openInputStream(uri);
                return createTemporalFileFrom(inputStream, fileName);
            } catch (Exception e) {
                Timber.e(e);
            } finally {
                try {
                    if (inputStream != null) {
                        inputStream.close();
                    }
                } catch (Exception e) {
                    Timber.e(e);
                }
            }
        }
        return null;
    }

    @Nullable
    private String createTemporalFileFrom(InputStream inputStream, String fileName)
            throws IOException {

        if (inputStream != null) {
            int read;
            byte[] buffer = new byte[8 * 1024];
            String targetPath = getFilesDir().getAbsolutePath() + "/" + fileName;
            Timber.v("图书导入, 目标路径: %s", targetPath);
            //自己定义拷贝文件路径
            File targetFile = new File(targetPath);
            if (!targetFile.exists()) {
                //自己定义拷贝文件路径
                OutputStream outputStream = new FileOutputStream(targetFile);

                while ((read = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, read);
                }
                outputStream.flush();

                try {
                    outputStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            return targetFile.getPath();
        }

        return null;
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

    @Override
    protected void onStop() {
        onStopDisposable.clear();
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        myCollection.unbind();
        super.onDestroy();
    }
}
