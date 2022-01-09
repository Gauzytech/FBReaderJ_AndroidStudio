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

package org.geometerplus.android.util;

import java.util.Queue;
import java.util.LinkedList;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.os.Handler;
import android.os.Message;

import org.fbreader.util.Pair;

import org.geometerplus.android.fbreader.view.FBLoadingDialog;
import org.geometerplus.zlibrary.core.application.ZLApplication;
import org.geometerplus.zlibrary.core.resources.ZLResource;

import timber.log.Timber;

public abstract class UIUtil {
    private static final Object ourMonitor = new Object();
    private static ProgressDialog ourProgress;
    private static final Queue<Pair<Runnable, String>> ourTaskQueue = new LinkedList<Pair<Runnable, String>>();
    private static volatile Handler ourProgressHandler;

    private static boolean init() {
        if (ourProgressHandler != null) {
            return true;
        }
        try {
            ourProgressHandler = new Handler() {
                public void handleMessage(Message message) {
                    try {
                        synchronized (ourMonitor) {
                            // 所有任务都执行完毕了，取消进度条
                            if (ourTaskQueue.isEmpty()) {
                                ourProgress.dismiss();
                                ourProgress = null;
                            } else {
                                // 如果还存在后台任务，就再向Handler类发送一个通知
                                ourProgress.setMessage(ourTaskQueue.peek().Second);
                            }
                            // 保证ourTaskQueue变量线程同步
                            ourMonitor.notify();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        ourProgress = null;
                    }
                }
            };
            return true;
        } catch (Throwable t) {
            t.printStackTrace();
            return false;
        }
    }

    public static void wait(String key, String param, Runnable action, Context context) {
        Timber.v("ceshi123, " + key);
        waitInternal(getWaitMessage(key).replace("%s", param), action, context);
    }

    public static void wait(String key, Runnable action, Context context) {
        Timber.v("ceshi123, " + key);
        waitInternal(getWaitMessage(key), action, context);
    }

    private static String getWaitMessage(String key) {
        return ZLResource.resource("dialog").getResource("waitMessage").getResource(key).getValue();
    }

    private static void waitInternal(String message, Runnable action, Context context) {
        if (!init()) {
            action.run();
            return;
        }
        // 在有多个后台任务的情况下保证线程同步
        synchronized (ourMonitor) {
            // 后台可能有多个任务同时等待运行
            ourTaskQueue.offer(new Pair(action, message));
            if (ourProgress == null) {
                // 主线程显示一个进度条
                ourProgress = ProgressDialog.show(context, null, message, true, false);
            } else {
                return;
            }
        }
        final ProgressDialog currentProgress = ourProgress;
        // 新建子线程
        new Thread(new Runnable() {
            public void run() {
                while (ourProgress == currentProgress && !ourTaskQueue.isEmpty()) {
                    final Pair<Runnable, String> p = ourTaskQueue.poll();
                    // 运行runnable类中的内容
                    p.First.run();
                    synchronized (ourMonitor) {
                        // 子线程中的代码运行完毕后, 通过Handler向主线程发送一个信息
                        ourProgressHandler.sendEmptyMessage(0);
                        try {
                            // 保证ourTaskQueue变量线程同步
                            ourMonitor.wait();
                        } catch (InterruptedException e) {
                        }
                    }
                }
            }
        // 运行子线程
        }).start();
    }

    /**
     * 显示进度条，并执行异步操作. eg: 打开图书loadingbook
     */
    public static ZLApplication.SynchronousExecutor createExecutor(final Activity activity, final String key) {
        return new ZLApplication.SynchronousExecutor() {
            private final ZLResource myResource = ZLResource.resource("dialog").getResource("waitMessage");
            private final String myMessage = myResource.getResource(key).getValue();
            private volatile FBLoadingDialog myProgress;

            public void execute(final Runnable action, final Runnable uiPostAction) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        myProgress = FBLoadingDialog.show(activity, null, myMessage, true, false);
                        final Thread runner = new Thread() {
                            public void run() {
                                action.run();
                                activity.runOnUiThread(new Runnable() {
                                    public void run() {
                                        try {
                                            myProgress.dismiss();
                                            myProgress = null;
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        }
                                        if (uiPostAction != null) {
                                            uiPostAction.run();
                                        }
                                    }
                                });
                            }
                        };
                        runner.setPriority(Thread.MAX_PRIORITY);
                        runner.start();
                    }
                });
            }

            private void setMessage(final FBLoadingDialog progress, final String message) {
                if (progress == null) {
                    return;
                }
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        progress.setMessage(message);
                    }
                });
            }

            public void executeAux(String key, Runnable runnable) {
                setMessage(myProgress, myResource.getResource(key).getValue());
                runnable.run();
                setMessage(myProgress, myMessage);
            }
        };
    }
}
