package org.geometerplus.zlibrary.ui.android.view.bookrender;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import timber.log.Timber;

/**
 * @Package org.geometerplus.zlibrary.ui.android.view.bookrender
 * @FileName FlutterCallHandler
 * @Date 4/26/22, 11:31 PM
 * @Author Created by fengchengding
 * @Description FBReaderJ_AndroidStudio
 */
public class FlutterCallHandler implements MethodChannel.MethodCallHandler {

   private MethodChannel channel;
   private Handler mainHandler;

   public FlutterCallHandler(BinaryMessenger messenger) {
      channel = new MethodChannel(messenger, "com.flutter.guide.MethodChannel");
      channel.setMethodCallHandler(this);
      mainHandler = new Handler(Looper.getMainLooper());
   }

   @Override
   public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
      if (call.method.equals("")) {
         // 获取Flutter传递的参数
         String name = call.argument("name");
         int age = call.argument("age");
         Timber.v("ceshi123 收到了 name = %s, age = %d", name, age);

         // 回传给Flutter
         Map<String, Integer> map = new HashMap<>();
         map.put("battery", 79);
         result.success(map);
      }
   }

   @MainThread
   public void invokeMethod(@NonNull String method, @Nullable Object arguments, @Nullable MethodChannel.Result callback) {
      channel.invokeMethod(method, arguments, callback);
   }
}
