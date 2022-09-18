/*
 * Copyright (C) 2007-2015 FBReader.ORG Limited <contact@fbreader.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

package org.geometerplus.android.fbreader;

import androidx.annotation.NonNull;

import com.facebook.stetho.Stetho;
import com.haowen.bugreport.CrashHandler;

import org.geometerplus.DebugHelper;
import org.geometerplus.zlibrary.ui.android.library.ZLAndroidApplication;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BinaryMessenger;
import skin.support.SkinCompatManager;
import skin.support.app.SkinAppCompatViewInflater;
import skin.support.app.SkinCardViewInflater;
import skin.support.constraint.app.SkinConstraintViewInflater;
import skin.support.design.app.SkinMaterialViewInflater;
import timber.log.Timber;

public class FBReaderApplication extends ZLAndroidApplication {
    public static String ENGINE_ID = "engine_id";
    private FlutterEngine flutterEngine;

    @Override
    public void onCreate() {
        super.onCreate();

        CrashHandler.getInstance().init(this.getApplicationContext());

        Stetho.initializeWithDefaults(this);

        SkinCompatManager.withoutActivity(this)
                .addInflater(new SkinAppCompatViewInflater())           // 基础控件换肤初始化
                .addInflater(new SkinMaterialViewInflater())            // material design 控件换肤初始化[可选]
                .addInflater(new SkinConstraintViewInflater())          // ConstraintLayout 控件换肤初始化[可选]
                .addInflater(new SkinCardViewInflater())                // CardView v7 控件换肤初始化[可选]
                .setSkinStatusBarColorEnable(false)                     // 关闭状态栏换肤，默认打开[可选]
                .setSkinWindowBackgroundEnable(false)                   // 关闭windowBackground换肤，默认打开[可选]
                .loadSkin();

        // Timber日志
        setDebug();

        if (DebugHelper.ENABLE_FLUTTER) {
            configFlutterEngine();
        }
    }

    private void setDebug() {
        Timber.plant(new Timber.DebugTree() {
            @Override
            protected String createStackElementTag(@NonNull StackTraceElement element) {
                return "(" + element.getFileName() + ":" + element.getLineNumber() + ")#" + element.getMethodName();
            }
        });
    }

    private void configFlutterEngine() {
        flutterEngine = new FlutterEngine(this);
//        flutterEngine.getNavigationChannel().setInitialRoute("/");
        flutterEngine.getDartExecutor().executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault());

        FlutterEngineCache.getInstance()
                .put(ENGINE_ID, flutterEngine);
    }

    public BinaryMessenger getEngineMessenger() {
        return flutterEngine.getDartExecutor().getBinaryMessenger();
    }

    public void destroyEngine() {
        flutterEngine.destroy();
    }

    @Override
    public void onTerminate() {
        destroyEngine();
        super.onTerminate();
    }
}