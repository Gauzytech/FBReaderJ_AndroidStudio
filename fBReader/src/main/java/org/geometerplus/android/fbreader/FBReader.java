/*
 * Copyright (C) 2009-2015 FBReader.ORG Limited <contact@fbreader.org>
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

import android.Manifest;
import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.SearchManager;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RadioGroup;
import android.widget.RelativeLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentPagerAdapter;
import androidx.viewpager.widget.ViewPager;

import com.google.android.material.tabs.TabLayout;

import org.geometerplus.DebugHelper;
import org.geometerplus.android.fbreader.api.ApiListener;
import org.geometerplus.android.fbreader.api.ApiServerImplementation;
import org.geometerplus.android.fbreader.api.FBReaderIntents;
import org.geometerplus.android.fbreader.api.MenuNode;
import org.geometerplus.android.fbreader.api.PluginApi;
import org.geometerplus.android.fbreader.dict.DictionaryUtil;
import org.geometerplus.android.fbreader.formatPlugin.PluginUtil;
import org.geometerplus.android.fbreader.httpd.DataService;
import org.geometerplus.android.fbreader.libraryService.BookCollectionShadow;
import org.geometerplus.android.fbreader.sync.SyncOperations;
import org.geometerplus.android.fbreader.tips.TipsActivity;
import org.geometerplus.android.fbreader.tts.TTSPlayer;
import org.geometerplus.android.fbreader.tts.util.TimeUtils;
import org.geometerplus.android.fbreader.ui.BookMarkFragment;
import org.geometerplus.android.fbreader.ui.BookNoteFragment;
import org.geometerplus.android.fbreader.ui.BookTOCFragment;
import org.geometerplus.android.fbreader.ui.TTSPlayerActivity;
import org.geometerplus.android.fbreader.util.AndroidImageSynchronizer;
import org.geometerplus.android.fbreader.util.AnimationHelper;
import org.geometerplus.android.util.DeviceType;
import org.geometerplus.android.util.SearchDialogUtil;
import org.geometerplus.android.util.UIMessageUtil;
import org.geometerplus.android.util.UIUtil;
import org.geometerplus.fbreader.Paths;
import org.geometerplus.fbreader.book.Book;
import org.geometerplus.fbreader.book.BookUtil;
import org.geometerplus.fbreader.book.Bookmark;
import org.geometerplus.fbreader.book.CoverUtil;
import org.geometerplus.fbreader.bookmodel.BookModel;
import org.geometerplus.fbreader.fbreader.ActionCode;
import org.geometerplus.fbreader.fbreader.DictionaryHighlighting;
import org.geometerplus.fbreader.fbreader.FBReaderApp;
import org.geometerplus.fbreader.fbreader.FBView;
import org.geometerplus.fbreader.fbreader.options.CancelMenuHelper;
import org.geometerplus.fbreader.fbreader.options.ColorProfile;
import org.geometerplus.fbreader.formats.ExternalFormatPlugin;
import org.geometerplus.fbreader.formats.PluginCollection;
import org.geometerplus.fbreader.tips.TipsManager;
import org.geometerplus.zlibrary.core.application.ZLReaderWindow;
import org.geometerplus.zlibrary.core.filesystem.ZLFile;
import org.geometerplus.zlibrary.core.image.ZLImage;
import org.geometerplus.zlibrary.core.image.ZLImageProxy;
import org.geometerplus.zlibrary.core.library.ZLibrary;
import org.geometerplus.zlibrary.core.options.Config;
import org.geometerplus.zlibrary.core.resources.ZLResource;
import org.geometerplus.zlibrary.core.view.ZLViewWidget;
import org.geometerplus.zlibrary.text.view.ZLTextRegion;
import org.geometerplus.zlibrary.text.view.ZLTextView;
import org.geometerplus.zlibrary.ui.android.R;
import org.geometerplus.zlibrary.ui.android.error.ErrorKeys;
import org.geometerplus.zlibrary.ui.android.image.ZLAndroidImageData;
import org.geometerplus.zlibrary.ui.android.image.ZLAndroidImageManager;
import org.geometerplus.zlibrary.ui.android.library.ZLAndroidLibrary;
import org.geometerplus.zlibrary.ui.android.view.AndroidFontUtil;
import org.geometerplus.zlibrary.ui.android.view.ZLAndroidWidget;
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterBridge;
import org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand;
import org.geometerplus.zlibrary.ui.android.view.callbacks.BookMarkCallback;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.android.FlutterFragment;
import io.flutter.plugin.common.MethodChannel;
import skin.support.SkinCompatManager;
import timber.log.Timber;

/**
 * 阅读主界面
 */
public final class FBReader extends FBReaderMainActivity implements ZLReaderWindow {

    public static final int RESULT_DO_NOTHING = RESULT_FIRST_USER;
    public static final int RESULT_REPAINT = RESULT_FIRST_USER + 1;
    private static final String PLUGIN_ACTION_PREFIX = "___";
    // 提供image, video的service, 通过nanoHttpd实现
    final DataService.Connection DataConnection = new DataService.Connection();
    private final FBReaderApp.Notifier myNotifier = new AppNotifier(this);
    private final List<PluginApi.ActionInfo> myPluginActions =
            new LinkedList<>();
    private final HashMap<MenuItem, String> myMenuItemMap = new HashMap<>();
    private final AndroidImageSynchronizer myImageSynchronizer = new AndroidImageSynchronizer(this);
    volatile boolean IsPaused = false;
    volatile Runnable OnResumeAction = null;
    List<Fragment> fragments = new ArrayList<>();
    // 管理阅读渲染的单例
    private FBReaderApp readerController;
    private final BroadcastReceiver myPluginInfoReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final ArrayList<PluginApi.ActionInfo> actions = getResultExtras(true).getParcelableArrayList(PluginApi.PluginInfo.KEY);
            if (actions != null) {
                synchronized (myPluginActions) {
                    int index = 0;
                    while (index < myPluginActions.size()) {
                        readerController.removeAction(PLUGIN_ACTION_PREFIX + index++);
                    }
                    myPluginActions.addAll(actions);
                    index = 0;
                    for (PluginApi.ActionInfo info : myPluginActions) {
                        readerController.addAction(
                                PLUGIN_ACTION_PREFIX + index++,
                                new RunPluginAction(FBReader.this, readerController, info.getId())
                        );
                    }
                }
            }
        }
    };
    private final MenuItem.OnMenuItemClickListener myMenuListener =
            new MenuItem.OnMenuItemClickListener() {
                public boolean onMenuItemClick(MenuItem item) {
                    readerController.runAction(myMenuItemMap.get(item));
                    return true;
                }
            };

    private volatile Book myBook;
    private volatile boolean myShowStatusBarFlag;
    private String myMenuLanguage;
    private volatile long myResumeTimestamp;
    private Intent myCancelIntent = null;
    private Intent myOpenBookIntent = null;
    private PowerManager.WakeLock myWakeLock;
    private boolean myWakeLockToCreate;
    private boolean myStartTimer;
    private int myBatteryLevel;
    private BroadcastReceiver myBatteryInfoReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            final int level = intent.getIntExtra("level", 100);
            setBatteryLevel(level);
            switchWakeLock(
                    hasWindowFocus() &&
                            getZLibrary().BatteryLevelToTurnScreenOffOption.getValue() < level
            );
        }
    };
    private BroadcastReceiver mySyncUpdateReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            readerController.useSyncInfo(myResumeTimestamp + 10 * 1000 > System.currentTimeMillis(), myNotifier);
        }
    };

    private boolean isLoad = false;

    /**
     * View
     */
    private RelativeLayout myRootView;
    private ZLAndroidWidget myMainView;
    private View firstMenu;
    private TextView tvTitle;
    private ImageView ivPlayer;
    private View quickThemeChange;
    private TextView quickThemeChangeText;
    private ImageView quickThemeChangeImg;
    private View menuTop;
    private View ivMore;
    private View menuMore;
    private View menuSetting;
    private View bookMark;
    private ImageView ivBookMarkState;
    private TextView tvBookMarkState;
    private View previousPage;
    private View nextPage;
    private SeekBar bookProgress;
    private View slideMenu;
    private View viewBackground;
    private FrameLayout readerView;
    private View showSetMenu;
    private View fontChoice;
    private TabLayout tabLayout;
    private ViewPager viewPager;
    private TextView tvBookName;
    private TextView tvAuthor;
    private View bookSearch;
    private View bookShare;
    private ImageView coverView;
    private View gotoTTS;
    private View scrollH;
    private View scrollV;
    private View menuPlayer;
    private View ivClose;
    private RadioGroup radioGroup;
    private View fontSmall;
    private View fontBig;
    private SeekBar lightProgress;
    private View openSlideMenu;
    private ImageView ivMarkArrow;
    private TextView tvMarkHint;
    private ImageView ivMarkState;
    private SeekBar audioProgress;
    private TextView tvPosition;
    private TextView tvDuration;
    /**
     * 语音合成播放器
     */
    private TTSPlayer ttsPlayer;

    // flutter相关内容
    private FlutterFragment flutterFragment;
    private FlutterBridge flutterBridge;

    public static void openBookActivity(Context context, Book book, Bookmark bookmark) {
        final Intent intent = defaultIntent(context);
        FBReaderIntents.putBookExtra(intent, book);
        FBReaderIntents.putBookmarkExtra(intent, bookmark);
        context.startActivity(intent);
    }

    public static Intent defaultIntent(Context context) {
        return new Intent(context, FBReader.class)
                .setAction(FBReaderIntents.Action.VIEW)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 321);

        bindService(
                new Intent(this, DataService.class),
                DataConnection,
                DataService.BIND_AUTO_CREATE
        );

        final Config config = Config.Instance();
        config.runOnConnect(() -> {
            config.requestAllValuesForGroup("Options");
            config.requestAllValuesForGroup("Style");
            config.requestAllValuesForGroup("LookNFeel");
            config.requestAllValuesForGroup("Fonts");
            config.requestAllValuesForGroup("Colors");
            config.requestAllValuesForGroup("Files");
        });

        // 是否显示顶部状态栏
        myShowStatusBarFlag = getZLibrary().ShowStatusBarOption.getValue();

        // 全屏
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        // 阅读界面
        setContentView(R.layout.main);
        // findViewById
        setUpView();
        setDefaultKeyMode(DEFAULT_KEYS_SEARCH_LOCAL);

        initListener();

        // 初始化阅读控制单例
        readerController = (FBReaderApp) FBReaderApp.Instance();
        if (readerController == null) {
            readerController = new FBReaderApp(Paths.systemInfo(this),
                    new BookCollectionShadow());
        }
        getCollection().bindToService(this, null);
        myBook = null;

        // 注册阅读界面管理类的回调
        readerController.setZLReaderWindowCallback(this);
        // iniWindow方法将负责建立子线程并在主线程显示进度条
        // 此时对myMainView重置
        readerController.initWindow();

        // 管理打开外部文件类
        readerController.setExternalFileOpener(new ExternalFileOpener(this));

        /// 设置是否隐藏状态栏
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                myShowStatusBarFlag ? 0 : WindowManager.LayoutParams.FLAG_FULLSCREEN
        );

        // 全书关键字搜索, (右上角三个点 -> 搜索全书内容)
        // TODO 没用, 应该有bug
        if (readerController.getPopupById(TextSearchPopup.ID) == null) {
            new TextSearchPopup(readerController);
        }

        // 初始化底部导航栏
        if (readerController.getPopupById(NavigationPopup.ID) == null) {
            new NavigationPopup(readerController);
        }
        // 初始化长按弹窗 笔记/删除/分享/复制
        if (readerController.getPopupById(SelectionPopup.ID) == null) {
            new SelectionPopup(readerController);
        }

        // 添加阅读界面的事件
        setControllerAction();

        // 获取包含图书信息的intent, 保存openBookIntent, 在onResume时候会调用
        setUpOpenBookIntent();

        // 初始化语音朗读
        ttsPlayer = TTSPlayer.getInstance();
        ttsPlayer.init(this, readerController);

        // todo 设置flutter
        if (DebugHelper.ENABLE_FLUTTER) {
            myMainView.setVisibility(View.GONE);
            // 设置flutter和native通信
            setFlutterBridge();

            // 设置flutter阅读组件
            if (flutterFragment == null) {
                Timber.v("flutter内容绘制流程, 创建flutterFragment");
                flutterFragment = FlutterFragment
                        .withCachedEngine(FBReaderApplication.ENGINE_ID)
                        .build();

                getSupportFragmentManager()
                        .beginTransaction()
                        .replace(R.id.readerView, flutterFragment, "flutter_fragment")
                        .commit();
            }
        }
    }

    private void setFlutterBridge() {
        flutterBridge = new FlutterBridge(this, readerController, ((FBReaderApplication) getApplication()).getEngineMessenger());
    }

    /**
     * 赋值myOpenBookIntent, 在onResume时候会调用
     */
    private void setUpOpenBookIntent() {
        final Intent intent = getIntent();
        final String action = intent.getAction();

        myOpenBookIntent = intent;
        if ((intent.getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0) {
            if (FBReaderIntents.Action.CLOSE.equals(action)) {
                myCancelIntent = intent;
                myOpenBookIntent = null;
            } else if (FBReaderIntents.Action.PLUGIN_CRASH.equals(action)) {
                readerController.externalBook = null;
                myOpenBookIntent = null;
                getCollection().bindToService(this, () ->
                        readerController.openBook(null, null, null, myNotifier, "FBReaderIntents.Action.PLUGIN_CRASH.equals(action)"));
            }
        }
    }

    /**
     * 添加阅读界面的事件
     */
    private void setControllerAction() {
        readerController.addAction(ActionCode.SHOW_LIBRARY, new ShowLibraryAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_PREFERENCES, new ShowPreferencesAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_BOOK_INFO, new ShowBookInfoAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_TOC, new ShowTOCAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_BOOKMARKS, new ShowBookmarksAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_NETWORK_LIBRARY, new ShowNetworkLibraryAction(this, readerController));

        readerController.addAction(ActionCode.SHOW_MENU, new ShowMenuAction(this, readerController));
        readerController.addAction(ActionCode.SHOW_NAVIGATION, new ShowNavigationAction(this, readerController));
        readerController.addAction(ActionCode.SEARCH, new SearchAction(this, readerController));
        readerController.addAction(ActionCode.SHARE_BOOK, new ShareBookAction(this, readerController));

        readerController.addAction(ActionCode.SELECTION_SHOW_PANEL, new SelectionShowPanelAction(this, readerController));
        readerController.addAction(ActionCode.SELECTION_HIDE_PANEL, new SelectionHidePanelAction(this, readerController));
        readerController.addAction(ActionCode.SELECTION_COPY_TO_CLIPBOARD, new SelectionCopyAction(this, readerController));
        readerController.addAction(ActionCode.SELECTION_SHARE, new SelectionShareAction(this, readerController));
        readerController.addAction(ActionCode.SELECTION_TRANSLATE, new SelectionTranslateAction(this, readerController));
        readerController.addAction(ActionCode.SELECTION_BOOKMARK, new SelectionBookmarkAction(this, readerController));

        readerController.addAction(ActionCode.DISPLAY_BOOK_POPUP, new DisplayBookPopupAction(this, readerController));
        readerController.addAction(ActionCode.PROCESS_HYPERLINK, new ProcessHyperlinkAction(this, readerController));
        readerController.addAction(ActionCode.OPEN_VIDEO, new OpenVideoAction(this, readerController));
        readerController.addAction(ActionCode.HIDE_TOAST, new HideToastAction(this, readerController));

        readerController.addAction(ActionCode.SHOW_CANCEL_MENU, new ShowCancelMenuAction(this, readerController));
        readerController.addAction(ActionCode.OPEN_START_SCREEN, new StartScreenAction(this, readerController));

        readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_SYSTEM, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_SYSTEM));
        readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_SENSOR, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_SENSOR));
        readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_PORTRAIT, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_PORTRAIT));
        readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_LANDSCAPE, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_LANDSCAPE));
        if (getZLibrary().supportsAllOrientations()) {
            readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_REVERSE_PORTRAIT, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_REVERSE_PORTRAIT));
            readerController.addAction(ActionCode.SET_SCREEN_ORIENTATION_REVERSE_LANDSCAPE, new SetScreenOrientationAction(this, readerController, ZLibrary.SCREEN_ORIENTATION_REVERSE_LANDSCAPE));
        }
        readerController.addAction(ActionCode.OPEN_WEB_HELP, new OpenWebHelpAction(this, readerController));
        readerController.addAction(ActionCode.INSTALL_PLUGINS, new InstallPluginsAction(this, readerController));

        readerController.addAction(ActionCode.SWITCH_THEME_WHITE_PROFILE, new SwitchProfileAction(this, readerController, ColorProfile.THEME_WHITE));
        readerController.addAction(ActionCode.SWITCH_THEME_YELLOW_PROFILE, new SwitchProfileAction(this, readerController, ColorProfile.THEME_YELLOW));
        readerController.addAction(ActionCode.SWITCH_THEME_GREEN_PROFILE, new SwitchProfileAction(this, readerController, ColorProfile.THEME_GREEN));
        readerController.addAction(ActionCode.SWITCH_THEME_BLACK_PROFILE, new SwitchProfileAction(this, readerController, ColorProfile.THEME_BLACK));

    }

    /**
     * findViewByIds
     */
    private void setUpView() {
        myRootView = findViewById(R.id.root_view);
        myMainView = findViewById(R.id.main_view);
        ivPlayer = findViewById(R.id.ivPlay);
        firstMenu = findViewById(R.id.firstMenu);
        tvTitle = findViewById(R.id.tvTitle);
        quickThemeChange = findViewById(R.id.quick_theme_change);
        quickThemeChangeText = findViewById(R.id.quick_theme_change_txt);
        quickThemeChangeImg = findViewById(R.id.quick_theme_change_img);
        menuTop = findViewById(R.id.menuTop);
        ivMore = findViewById(R.id.ivMore);
        menuMore = findViewById(R.id.menuMore);
        menuSetting = findViewById(R.id.menuSetting);
        bookMark = findViewById(R.id.book_mark);
        ivBookMarkState = findViewById(R.id.book_mark_state_icon);
        tvBookMarkState = findViewById(R.id.book_mark_state_txt);
        previousPage = findViewById(R.id.shangyizhang);
        nextPage = findViewById(R.id.xiayizhang);
        bookProgress = findViewById(R.id.bookProgress);
        slideMenu = findViewById(R.id.slideMenu);
        viewBackground = findViewById(R.id.viewBackground);
        readerView = findViewById(R.id.readerView);
        showSetMenu = findViewById(R.id.showSetMenu);
        viewPager = findViewById(R.id.viewPager);
        tabLayout = findViewById(R.id.tabLayout);
        bookSearch = findViewById(R.id.book_search);
        bookShare = findViewById(R.id.book_share);
        tvAuthor = findViewById(R.id.author);
        coverView = findViewById(R.id.book_img);
        tvBookName = findViewById(R.id.book_name);
        gotoTTS = findViewById(R.id.goto_tts_play);
        menuPlayer = findViewById(R.id.menuPlayer);
        ivClose = findViewById(R.id.ivClose);
        scrollH = findViewById(R.id.h);
        scrollV = findViewById(R.id.v);
        fontSmall = findViewById(R.id.font_small);
        fontBig = findViewById(R.id.font_big);
        radioGroup = findViewById(R.id.book_menu_color_group);
        lightProgress = findViewById(R.id.lightProgress);
        openSlideMenu = findViewById(R.id.open_slid_menu);
        ivMarkArrow = findViewById(R.id.ivMarkArrow);
        tvMarkHint = findViewById(R.id.tvMarkHint);
        ivMarkState = findViewById(R.id.ivMarkState);
        fontChoice = findViewById(R.id.font_choice);
        audioProgress = findViewById(R.id.audioProgress);
        tvPosition = findViewById(R.id.tvPosition);
        tvDuration = findViewById(R.id.tvDuration);
    }

    @SuppressLint("ClickableViewAccessibility")
    private void initListener() {

        myMainView.setBookMarkCallback(new BookMarkCallback() {

            @Override
            public void onCanceling() {
                if (readerController.getTextView().hasBookMark()) {
                    tvMarkHint.setText("下拉删除书签");
                    ivMarkState.setImageResource(R.drawable.reader_book_mark_marked);
                } else {
                    tvMarkHint.setText("下拉添加书签");
                    ivMarkState.setImageResource(R.drawable.reader_book_mark_cancel);
                }
                ivMarkArrow.animate()
                        .rotation(0)
                        .setDuration(200)
                        .start();
            }

            @Override
            public void onChanging() {
                if (readerController.getTextView().hasBookMark()) {
                    tvMarkHint.setText("松手删除书签");
                    ivMarkState.setImageResource(R.drawable.reader_book_mark_cancel);
                } else {
                    tvMarkHint.setText("松手添加书签");
                    ivMarkState.setImageResource(R.drawable.reader_book_mark_marked);
                }
                ivMarkArrow.animate()
                        .rotation(180)
                        .setDuration(200)
                        .start();
            }

            @Override
            public void onChanged() {
                if (readerController.getTextView().hasBookMark()) {
                    List<Bookmark> bookMarks = readerController.getTextView().getBookMarks();
                    for (Bookmark bookmark : bookMarks) {
                        getCollection().deleteBookmark(bookmark);
                    }
                } else {
                    getCollection().saveBookmark(readerController.createBookmark(20, Bookmark.Type.BookMark));
                }
            }
        });

        firstMenu.setOnClickListener(v -> {
            // Empty body.
        });
        // 主题切换
        quickThemeChange.setOnClickListener(v -> {
            if (readerController.isActionVisible(ActionCode.SWITCH_THEME_BLACK_PROFILE)) {
                readerController.runAction(ActionCode.SWITCH_THEME_BLACK_PROFILE);
                SkinCompatManager.getInstance().loadSkin(ColorProfile.THEME_BLACK, SkinCompatManager.SKIN_LOADER_STRATEGY_BUILD_IN);
            } else {
                readerController.runAction(ActionCode.SWITCH_THEME_WHITE_PROFILE);
                SkinCompatManager.getInstance().restoreDefaultTheme();
            }
            // 主题状态（当前为夜间主题，字面为日常模式,否则反之）
            if (readerController.isActionVisible(ActionCode.SWITCH_THEME_BLACK_PROFILE)) {
                quickThemeChangeText.setText("夜间模式");
                quickThemeChangeImg.setImageResource(R.drawable.ic_book_night);
            } else {
                quickThemeChangeText.setText("日常模式");
                quickThemeChangeImg.setImageResource(R.drawable.ic_book_day);
            }
        });

        menuTop.setOnClickListener(v -> {
            // Empty body.
        });

        ivMore.setOnClickListener(v -> {
            initMoreBookInfoView();
            if (firstMenu.getVisibility() == View.VISIBLE) {
                AnimationHelper.closePreview(myMainView);
            }
            AnimationHelper.closeBottomMenu(menuSetting, false);
            AnimationHelper.closeBottomMenu(firstMenu, false);
            AnimationHelper.openBottomMenu(menuMore);
        });

        // 搜索
        bookSearch.setOnClickListener(v -> {
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(menuMore);
            readerController.runAction(ActionCode.SEARCH);
        });

        // 分享
        bookShare.setOnClickListener(v -> {
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(menuMore);
            readerController.runAction(ActionCode.SHARE_BOOK);
        });

        bookMark.setOnClickListener(v -> {
            // 添加书签
            if (readerController.getTextView().hasBookMark()) {
                List<Bookmark> bookMarks = readerController.getTextView().getBookMarks();
                for (Bookmark bookmark : bookMarks) {
                    getCollection().deleteBookmark(bookmark);
                }
            } else {
                getCollection().saveBookmark(readerController.createBookmark(20, Bookmark.Type.BookMark));
            }
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(menuMore);
        });

        // 上一页
        previousPage.setOnClickListener(v ->
                readerController.runAction(ActionCode.TURN_PAGE_BACK));

        // 下一页
        nextPage.setOnClickListener(v ->
                readerController.runAction(ActionCode.TURN_PAGE_FORWARD));

        bookProgress.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    final int page = progress + 1;
                    gotoPage(page);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }

            private void gotoPage(int page) {
                FBView textView = readerController.getTextView();
                if (page == 1) {
                    textView.gotoHome();
                } else {
                    textView.gotoPage(page);
                }
                readerController.getViewWidget().reset("gotoPage");
                readerController.getViewWidget().repaint("gotoPage");
            }
        });

        // 亮度设置
        lightProgress.setProgress(myMainView.getScreenBrightness());
        lightProgress.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                myMainView.setScreenBrightness(progress);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

        openSlideMenu.setOnClickListener(v -> {
            initSideMenuFragment();
            openSlideMenu();
        });

        slideMenu.setOnClickListener(v -> {
            // Empty body.
        });

        // 返回
        viewBackground.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                closeSlideMenu();
            }
            return true;
        });

        // 设置菜单
        showSetMenu.setOnClickListener(v -> {
            if (menuSetting.getVisibility() == View.VISIBLE) {
                AnimationHelper.closeBottomMenu(menuSetting);
            } else {
                updatePageDirectionUI();
                // 主题
                if (!readerController.isActionVisible(ActionCode.SWITCH_THEME_WHITE_PROFILE)) {
                    radioGroup.check(R.id.color_white);
                }
                if (!readerController.isActionVisible(ActionCode.SWITCH_THEME_YELLOW_PROFILE)) {
                    radioGroup.check(R.id.color_yellow);
                }
                if (!readerController.isActionVisible(ActionCode.SWITCH_THEME_GREEN_PROFILE)) {
                    radioGroup.check(R.id.color_green);
                }
                if (!readerController.isActionVisible(ActionCode.SWITCH_THEME_BLACK_PROFILE)) {
                    radioGroup.check(R.id.color_black);
                }
                AnimationHelper.closeBottomMenu(firstMenu, false);
                AnimationHelper.openBottomMenu(menuSetting);
                AnimationHelper.closePreview(myMainView);
            }
        });

        // 字体大小
        fontSmall.setOnClickListener(v ->
                readerController.runAction(ActionCode.DECREASE_FONT));
        fontBig.setOnClickListener(v ->
                readerController.runAction(ActionCode.INCREASE_FONT));

        radioGroup.setOnCheckedChangeListener((group, checkedId) -> {
            switch (checkedId) {
                case R.id.color_white:
                    readerController.runAction(ActionCode.SWITCH_THEME_WHITE_PROFILE);
                    SkinCompatManager.getInstance().restoreDefaultTheme();
                    break;
                case R.id.color_yellow:
                    readerController.runAction(ActionCode.SWITCH_THEME_YELLOW_PROFILE);
                    SkinCompatManager.getInstance().loadSkin(ColorProfile.THEME_YELLOW, SkinCompatManager.SKIN_LOADER_STRATEGY_BUILD_IN);
                    break;
                case R.id.color_green:
                    readerController.runAction(ActionCode.SWITCH_THEME_GREEN_PROFILE);
                    SkinCompatManager.getInstance().loadSkin(ColorProfile.THEME_GREEN, SkinCompatManager.SKIN_LOADER_STRATEGY_BUILD_IN);
                    break;
                case R.id.color_black:
                    readerController.runAction(ActionCode.SWITCH_THEME_BLACK_PROFILE);
                    SkinCompatManager.getInstance().loadSkin(ColorProfile.THEME_BLACK, SkinCompatManager.SKIN_LOADER_STRATEGY_BUILD_IN);
                    break;
                default:
                    break;
            }
        });

        gotoTTS.setOnClickListener(v -> {
            ttsPlayer.addPlayCallback((currentPosition, duration) ->
                    runOnUiThread(() -> {
                        tvPosition.setText(TimeUtils.millis2Time(currentPosition));
                        tvDuration.setText(TimeUtils.millis2Time(duration));
                        audioProgress.setMax(duration);
                        audioProgress.setProgress(currentPosition);
                    }));
            ttsPlayer.process();
            AnimationHelper.closeBottomMenu(firstMenu);
            AnimationHelper.closeBottomMenu(menuTop);
            AnimationHelper.closePreview(myMainView);
            menuPlayer.setVisibility(View.VISIBLE);
            TTSPlayer.getInstance().setPlaying(true);
            ivPlayer.setImageResource(R.drawable.reader_player_pause_icon);
            Toast.makeText(FBReader.this, "语音合成中", Toast.LENGTH_SHORT).show();
        });

        // 播放栏
        menuPlayer.setOnClickListener(v -> {
            if (TTSPlayer.getInstance().isPlaying()) {
                ivPlayer.setImageResource(R.drawable.reader_player_start_icon);
                ttsPlayer.pause();
            } else {
                ivPlayer.setImageResource(R.drawable.reader_player_pause_icon);
                ttsPlayer.start();
            }
            TTSPlayer.getInstance().setPlaying(!TTSPlayer.getInstance().isPlaying());
        });

        // 跳转播放器页面
        menuPlayer.setOnClickListener(v -> {
            Intent intent = new Intent(FBReader.this, TTSPlayerActivity.class);
            startActivity(intent);
        });

        // 关闭播放栏
        ivClose.setOnClickListener(v -> {
            ttsPlayer.stop();
            readerController.getTextView().clearHighlighting();
            menuPlayer.setVisibility(View.GONE);
        });

        // 上下滚动
        scrollV.setOnClickListener(v -> {
            readerController.PageTurningOptions.Horizontal.setValue(false);
            updatePageDirectionUI();
        });

        // 水平
        scrollH.setOnClickListener(v -> {
            readerController.PageTurningOptions.Horizontal.setValue(true);
            updatePageDirectionUI();
        });

        // 字体选择
        fontChoice.setOnClickListener(v -> {

        });
    }

    private BookCollectionShadow getCollection() {
        return (BookCollectionShadow) readerController.Collection;
    }

    /**
     * 初始化点击more后的图书信息
     */
    private void initMoreBookInfoView() {
        final Book book = readerController.getCurrentBook();
        if (book == null) {
            return;
        }
        if (readerController.getTextView().hasBookMark()) {
            ivBookMarkState.setImageResource(R.drawable.reader_mark_marked_icon);
            tvBookMarkState.setText("删除书签");
        } else {
            ivBookMarkState.setImageResource(R.drawable.reader_mark_icon);
            tvBookMarkState.setText("添加书签");
        }
        tvBookName.setText(book.getTitle());
        tvAuthor.setText(book.authorsString(""));
        final PluginCollection pluginCollection =
                PluginCollection.Instance(Paths.systemInfo(this));
        final ZLImage image = CoverUtil.getCover(book, pluginCollection);

        if (image == null) {
            return;
        }

        if (image instanceof ZLImageProxy) {
            ((ZLImageProxy) image).startSynchronization(myImageSynchronizer, () ->
                    runOnUiThread(() ->
                            setCover(coverView, image)));
        } else {
            setCover(coverView, image);
        }
    }

    /**
     * 初始化侧边栏Fragment
     */
    private void initSideMenuFragment() {
        if (isLoad) {
            ((BookTOCFragment) fragments.get(0)).initTree();
            return;
        }
        isLoad = true;
        fragments.add(new BookTOCFragment());
        fragments.add(new BookMarkFragment());
        fragments.add(new BookNoteFragment());
        final String[] titles = new String[]{"目录", "书签", "笔记"};
        viewPager.setAdapter(new FragmentPagerAdapter(getSupportFragmentManager()) {
            @Override
            public Fragment getItem(int i) {
                return fragments.get(i);
            }

            @Override
            public int getCount() {
                return fragments.size();
            }

            @Override
            public CharSequence getPageTitle(int position) {
                return titles[position];
            }
        });
        tabLayout.setupWithViewPager(viewPager);
    }

    /**
     * 关闭侧边栏
     */
    private void openSlideMenu() {
        // 关闭侧边栏（侧边栏位移，侧边栏蒙层背景淡入淡出，阅读器视图位移）
        AnimationHelper.openSlideMenu(slideMenu, viewBackground, readerView);
        // 关闭底部菜单
        AnimationHelper.closeBottomMenu(firstMenu);
        // 阅读器内容预览关闭
        AnimationHelper.closePreview(myMainView);
        // 关闭-->顶部菜单
        AnimationHelper.closeTopMenu(menuTop);
    }

    /**
     * 关闭侧边栏菜单
     */
    public void closeSlideMenu() {
        AnimationHelper.closeSlideMenu(slideMenu, viewBackground, readerView);
    }

    /**
     * 更新页面方向设置的UI
     */
    private void updatePageDirectionUI() {
        if (readerController.PageTurningOptions.Horizontal.getValue()) {
            scrollH.setBackgroundResource(R.drawable.reader_button_border_checked);
            scrollV.setBackgroundResource(R.drawable.reader_button_border);
        } else {
            scrollV.setBackgroundResource(R.drawable.reader_button_border_checked);
            scrollH.setBackgroundResource(R.drawable.reader_button_border);
        }
    }

    /**
     * 设置封面
     */
    private void setCover(ImageView coverView, ZLImage image) {
        final ZLAndroidImageData data =
                ((ZLAndroidImageManager) ZLAndroidImageManager.Instance()).getImageData(image);
        if (data == null) {
            return;
        }

        final DisplayMetrics metrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(metrics);

        final Bitmap coverBitmap = data.getBitmap((int) getResources().getDisplayMetrics().density * 56,
                (int) getResources().getDisplayMetrics().density * 74);
        if (coverBitmap == null) {
            return;
        }

        coverView.setImageBitmap(coverBitmap);
    }

    @Override
    protected void onStart() {
        super.onStart();

        getCollection().bindToService(this, () -> {
            new Thread() {
                public void run() {
                    getPostponedInitAction().run();
                }
            }.start();
            Timber.v("渲染流程, onStart -> view.repaint");
            readerController.getViewWidget().repaint("onStart");
        });

        initPluginActions();

        final ZLAndroidLibrary zLibrary = getZLibrary();

        Config.Instance().runOnConnect(() -> {
            final boolean showStatusBar = zLibrary.ShowStatusBarOption.getValue();
            if (showStatusBar != myShowStatusBarFlag) {
                finish();
                startActivity(new Intent(FBReader.this, FBReader.class));
            }
            zLibrary.ShowStatusBarOption.saveSpecialValue();
            readerController.ViewOptions.ColorProfileName.saveSpecialValue();
            SetScreenOrientationAction.setOrientation(FBReader.this, zLibrary.getOrientationOption().getValue());
        });

        ((PopupPanel) readerController.getPopupById(TextSearchPopup.ID)).setPanelInfo(this, myRootView);
        ((NavigationPopup) readerController.getPopupById(NavigationPopup.ID)).setPanelInfo(this, myRootView);
        ((PopupPanel) readerController.getPopupById(SelectionPopup.ID)).setPanelInfo(this, myRootView);
    }

    private Runnable getPostponedInitAction() {
        return () -> runOnUiThread(() -> {
            new TipRunner().start();
            DictionaryUtil.init(FBReader.this, null);
            final Intent intent = getIntent();
            if (intent != null && FBReaderIntents.Action.PLUGIN.equals(intent.getAction())) {
                new RunPluginAction(FBReader.this, readerController, intent.getData()).run();
            }
        });
    }

    private void initPluginActions() {
        synchronized (myPluginActions) {
            int index = 0;
            while (index < myPluginActions.size()) {
                readerController.removeAction(PLUGIN_ACTION_PREFIX + index++);
            }
            myPluginActions.clear();
        }

        sendOrderedBroadcast(
                new Intent(PluginApi.ACTION_REGISTER),
                null,
                myPluginInfoReceiver,
                null,
                RESULT_OK,
                null,
                null
        );
    }

    @Override
    protected void onStop() {
        ApiServerImplementation.sendEvent(this, ApiListener.EVENT_READ_MODE_CLOSED);
        // TODO: 2019/5/9 移除后状态恢复有问题
        // PopupPanel.removeAllWindows(myReaderController, this);
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        // 通知flutter清除当前显示的图书页面, 避免用户切换图书时，有机会看到上一本图书的内容
        invokeFlutterMethod(FlutterCommand.TEAR_DOWN, null, null);
        flutterFragment.detachFromFlutterEngine();
        readerView.removeAllViews();
        flutterBridge.tearDown();
        // 注销bind service
        getCollection().unbind();
        unbindService(DataConnection);
//        readerController.onCleared();
        super.onDestroy();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        return (myMainView != null && myMainView.onKeyDown(keyCode, event)) || super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
            default:
                super.onActivityResult(requestCode, resultCode, data);
                break;
            case REQUEST_PREFERENCES:
                if (resultCode != RESULT_DO_NOTHING && data != null) {
                    final Book book = FBReaderIntents.getBookExtra(data, readerController.Collection);
                    if (book != null) {
                        getCollection().bindToService(this, new Runnable() {
                            public void run() {
                                onPreferencesUpdate(book);
                            }
                        });
                    }
                }
                break;
            case REQUEST_CANCEL_MENU:
                runCancelAction(data);
                break;
        }
    }

    public void hideDictionarySelection() {
        readerController.getTextView().hideOutline();
        readerController.getTextView().removeHighlightings(DictionaryHighlighting.class);
        readerController.getViewWidget().reset("hideDictionarySelection");
        readerController.getViewWidget().repaint("hideDictionarySelection");
    }

    private void onPreferencesUpdate(Book book) {
        AndroidFontUtil.clearFontCache();
        readerController.onBookUpdated(book);
    }

    private void runCancelAction(Intent intent) {
        final CancelMenuHelper.ActionType type;
        try {
            type = CancelMenuHelper.ActionType.valueOf(
                    intent.getStringExtra(FBReaderIntents.Key.TYPE)
            );
        } catch (Exception e) {
            // invalid (or null) type value
            return;
        }
        Bookmark bookmark = null;
        if (type == CancelMenuHelper.ActionType.returnTo) {
            bookmark = FBReaderIntents.getBookmarkExtra(intent);
            if (bookmark == null) {
                return;
            }
        }
        readerController.runCancelAction(type, bookmark);
    }

    @Override
    public void onLowMemory() {
        readerController.onWindowClosing();
        super.onLowMemory();
    }

    @Override
    protected void onPause() {
        SyncOperations.quickSync(this, readerController.SyncOptions);

        IsPaused = true;
        try {
            unregisterReceiver(mySyncUpdateReceiver);
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
        }

        try {
            unregisterReceiver(myBatteryInfoReceiver);
        } catch (IllegalArgumentException e) {
            // do nothing, this exception means that myBatteryInfoReceiver was not registered
        }

        readerController.stopTimer();
        if (getZLibrary().DisableButtonLightsOption.getValue()) {
            setButtonLight(true);
        }
        readerController.onWindowClosing();

        super.onPause();
    }

    @Override
    protected void onNewIntent(final Intent intent) {
        final String action = intent.getAction();
        final Uri data = intent.getData();

        if ((intent.getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) {
            super.onNewIntent(intent);
        } else if (Intent.ACTION_VIEW.equals(action)
                && data != null && "fbreader-action".equals(data.getScheme())) {
            readerController.runAction(data.getEncodedSchemeSpecificPart(), data.getFragment());
        } else if (Intent.ACTION_VIEW.equals(action) || FBReaderIntents.Action.VIEW.equals(action)) {
            myOpenBookIntent = intent;
            if (readerController.bookModel == null && readerController.externalBook != null) {
                final BookCollectionShadow collection = getCollection();
                final Book b = FBReaderIntents.getBookExtra(intent, collection);
                if (!collection.sameBook(b, readerController.externalBook)) {
                    try {
                        final ExternalFormatPlugin plugin =
                                (ExternalFormatPlugin) BookUtil.getPlugin(
                                        PluginCollection.Instance(Paths.systemInfo(this)),
                                        readerController.externalBook
                                );
                        startActivity(PluginUtil.createIntent(plugin, FBReaderIntents.Action.PLUGIN_KILL));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        } else if (FBReaderIntents.Action.PLUGIN.equals(action)) {
            new RunPluginAction(this, readerController, data).run();
        } else if (Intent.ACTION_SEARCH.equals(action)) {
            final String pattern = intent.getStringExtra(SearchManager.QUERY);
            final Runnable runnable = () -> {
                final TextSearchPopup popup = (TextSearchPopup) readerController.getPopupById(TextSearchPopup.ID);
                popup.initPosition();
                readerController.MiscOptions.TextSearchPattern.setValue(pattern);
                if (readerController.getTextView().search(pattern, true, false, false, false) != 0) {
                    runOnUiThread(() -> readerController.showPopup(popup.getId()));
                } else {
                    runOnUiThread(() -> {
                        UIMessageUtil.showErrorMessage(FBReader.this, "textNotFound");
                        popup.StartPosition = null;
                    });
                }
            };
            UIUtil.wait("search", runnable, this);
        } else if (FBReaderIntents.Action.CLOSE.equals(intent.getAction())) {
            myCancelIntent = intent;
            myOpenBookIntent = null;
        } else if (FBReaderIntents.Action.PLUGIN_CRASH.equals(intent.getAction())) {
            final Book book = FBReaderIntents.getBookExtra(intent, readerController.Collection);
            readerController.externalBook = null;
            myOpenBookIntent = null;
            getCollection().bindToService(this, () -> {
                final BookCollectionShadow collection = getCollection();
                Book b = collection.getRecentBook(0);
                if (collection.sameBook(b, book)) {
                    b = collection.getRecentBook(1);
                }
                readerController.openBook(b, null, null, myNotifier, "onNewIntent");
            });
        } else {
            super.onNewIntent(intent);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();

        // 恢复按钮的播放状态
        if (TTSPlayer.getInstance().isPlaying()) {
            ivPlayer.setImageResource(R.drawable.reader_player_pause_icon);
        } else {
            ivPlayer.setImageResource(R.drawable.reader_player_start_icon);
        }

        myStartTimer = true;
        Config.Instance().runOnConnect(() -> {
            SyncOperations.enableSync(FBReader.this, readerController.SyncOptions);
            // 设置亮度
            final int brightnessLevel =
                    getZLibrary().ScreenBrightnessLevelOption.getValue();
            if (brightnessLevel != 0) {
                if (DebugHelper.ENABLE_SET_SCREEN_BRIGHTNESS) {
                    getViewWidget("onResume.brightnessLevel").setScreenBrightness(brightnessLevel);
                }
            } else {
                setScreenBrightnessAuto();
            }
            if (getZLibrary().DisableButtonLightsOption.getValue()) {
                setButtonLight(false);
            }

            getCollection().bindToService(FBReader.this, () -> {
                // 监听阅读设置改变
                final BookModel model = readerController.bookModel;
                if (model == null || model.book() == null) {
                    return;
                }
                onPreferencesUpdate(readerController.Collection.getBookById(model.book().getId()));
            });
        });

        // 监听电量变化
        registerReceiver(myBatteryInfoReceiver, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        IsPaused = false;
        myResumeTimestamp = System.currentTimeMillis();
        if (OnResumeAction != null) {
            final Runnable action = OnResumeAction;
            OnResumeAction = null;
            action.run();
        }
        // 监听同步
        registerReceiver(mySyncUpdateReceiver, new IntentFilter(FBReaderIntents.Event.SYNC_UPDATED));

        if (DebugHelper.ENABLE_SET_ORIENTATION) {
            SetScreenOrientationAction.setOrientation(this, getZLibrary().getOrientationOption().getValue());
        }
        if (myCancelIntent != null) {
            final Intent intent = myCancelIntent;
            myCancelIntent = null;
            getCollection().bindToService(this, () -> runCancelAction(intent));
            return;
        } else if (myOpenBookIntent != null) {
            final Intent intent = myOpenBookIntent;
            myOpenBookIntent = null;
            getCollection().bindToService(this, () ->
                    openBook(intent, null, true));
        } else if (readerController.getCurrentServerBook(null) != null) {
            getCollection().bindToService(this, () ->
                    readerController.useSyncInfo(true, myNotifier));
        } else if (readerController.bookModel == null && readerController.externalBook != null) {
            getCollection().bindToService(this, () ->
                    readerController.openBook(readerController.externalBook, null, null, myNotifier, "onResume"));
        } else {
            getCollection().bindToService(this, () ->
                    readerController.useSyncInfo(true, myNotifier));
        }

        PopupPanel.restoreVisibilities(readerController);
        ApiServerImplementation.sendEvent(this, ApiListener.EVENT_READ_MODE_OPENED);
    }

    private synchronized void openBook(Intent intent, final Runnable action, boolean force) {
        Timber.i("打开图书流程[onResume], %s", intent);
        if (!force && myBook != null) {
            return;
        }

        myBook = FBReaderIntents.getBookExtra(intent, readerController.Collection);
        final Bookmark bookmark = FBReaderIntents.getBookmarkExtra(intent);
        if (myBook == null) {
            final Uri data = intent.getData();
            if (data != null) {
                myBook = createBookForFile(ZLFile.createFileByPath(data.getPath()));
            }
        }
        if (myBook != null) {
            Timber.i("打开图书流程[onResume], 当前图书对象 = %s", myBook);
            ZLFile file = BookUtil.fileByBook(myBook);
            if (!file.exists()) {
                if (file.getPhysicalFile() != null) {
                    file = file.getPhysicalFile();
                }
                UIMessageUtil.showErrorMessage(this, "fileNotFound", file.getPath());
                myBook = null;
            } else {
                NotificationUtil.drop(this, myBook);
            }
        }
        Config.Instance().runOnConnect(() -> {
            readerController.openBook(myBook, bookmark, action, myNotifier, "Config.Instance().runOnConnect");
            AndroidFontUtil.clearFontCache();
        });
    }

    private Book createBookForFile(ZLFile file) {
        if (file == null) {
            return null;
        }
        Book book = readerController.Collection.getBookByFile(file.getPath());
        if (book != null) {
            return book;
        }
        if (file.isArchive()) {
            for (ZLFile child : file.children()) {
                book = readerController.Collection.getBookByFile(child.getPath());
                if (book != null) {
                    return book;
                }
            }
        }
        return null;
    }

    private void setButtonLight(boolean enabled) {
        setButtonLightInternal(enabled);
    }

    @TargetApi(Build.VERSION_CODES.FROYO)
    private void setButtonLightInternal(boolean enabled) {
        final WindowManager.LayoutParams attrs = getWindow().getAttributes();
        attrs.buttonBrightness = enabled ? -1.0f : 0.0f;
        getWindow().setAttributes(attrs);
    }

    public void showSelectionPanel() {
        final ZLTextView view = readerController.getTextView();
        // 显示弹框
        readerController.showPopup(SelectionPopup.ID);
        Timber.v("选择弹窗, 坐标: startY = %s, endY = %s", view.getSelectionStartY(), view.getSelectionEndY());
        // 位置移动
        ((SelectionPopup) readerController.getPopupById(SelectionPopup.ID)).move(view.getSelectionStartY(), view.getSelectionEndY());
    }

    public void hideSelectionPanel() {
        final FBReaderApp.PopupPanel popup = readerController.getActivePopup();
        if (popup != null && popup.getId() == SelectionPopup.ID) {
            readerController.hideActivePopup();
        }
    }

    public void navigate() {
        ((NavigationPopup) readerController.getPopupById(NavigationPopup.ID)).runNavigation();
    }

    private Menu addSubmenu(Menu menu, String id) {
        return menu.addSubMenu(ZLResource.resource("menu").getResource(id).getValue());
    }

    private void addMenuItem(Menu menu, String actionId, Integer iconId, String name) {
        if (name == null) {
            name = ZLResource.resource("menu").getResource(actionId).getValue();
        }
        final MenuItem menuItem = menu.add(name);
        if (iconId != null) {
            menuItem.setIcon(iconId);
        }
        menuItem.setOnMenuItemClickListener(myMenuListener);
        myMenuItemMap.put(menuItem, actionId);
    }

    private void addMenuItem(Menu menu, String actionId, String name) {
        addMenuItem(menu, actionId, null, name);
    }

    private void addMenuItem(Menu menu, String actionId, int iconId) {
        addMenuItem(menu, actionId, iconId, null);
    }

    private void addMenuItem(Menu menu, String actionId) {
        addMenuItem(menu, actionId, null, null);
    }

    private void fillMenu(Menu menu, List<MenuNode> nodes) {
        for (MenuNode n : nodes) {
            if (n instanceof MenuNode.Item) {
                final Integer iconId = ((MenuNode.Item) n).IconId;
                if (iconId != null) {
                    addMenuItem(menu, n.Code, iconId);
                } else {
                    addMenuItem(menu, n.Code);
                }
            } else /* if (n instanceof MenuNode.Submenu) */ {
                final Menu submenu = addSubmenu(menu, n.Code);
                fillMenu(submenu, ((MenuNode.Submenu) n).Children);
            }
        }
    }

    private void setupMenu(Menu menu) {
        final String menuLanguage = ZLResource.getLanguageOption().getValue();
        if (menuLanguage.equals(myMenuLanguage)) {
            return;
        }
        myMenuLanguage = menuLanguage;

        menu.clear();
        fillMenu(menu, MenuData.topLevelNodes());
        synchronized (myPluginActions) {
            int index = 0;
            for (PluginApi.ActionInfo info : myPluginActions) {
                if (info instanceof PluginApi.MenuActionInfo) {
                    addMenuItem(
                            menu,
                            PLUGIN_ACTION_PREFIX + index++,
                            ((PluginApi.MenuActionInfo) info).MenuItemName
                    );
                }
            }
        }

        refresh();
    }

    protected void onPluginNotFound(final Book book) {
        final BookCollectionShadow collection = getCollection();
        collection.bindToService(this, new Runnable() {
            public void run() {
                final Book recent = collection.getRecentBook(0);
                if (recent != null && !collection.sameBook(recent, book)) {
                    readerController.openBook(recent, null, null, null, "onPluginNotFound");
                } else {
                    readerController.openHelpBook();
                }
            }
        });
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        return (myMainView != null && myMainView.onKeyUp(keyCode, event)) || super.onKeyUp(keyCode, event);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        switchWakeLock(hasFocus &&
                getZLibrary().BatteryLevelToTurnScreenOffOption.getValue() <
                        readerController.getBatteryLevel()
        );
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);

        setupMenu(menu);

        return true;
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        setStatusBarVisibility(true);
        setupMenu(menu);

        return super.onPrepareOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        setStatusBarVisibility(false);
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onOptionsMenuClosed(Menu menu) {
        super.onOptionsMenuClosed(menu);
        setStatusBarVisibility(false);
    }

    @Override
    public boolean onSearchRequested() {
        final FBReaderApp.PopupPanel popup = readerController.getActivePopup();
        readerController.hideActivePopup();
        if (DeviceType.Instance().hasStandardSearchDialog()) {
            final SearchManager manager = (SearchManager) getSystemService(SEARCH_SERVICE);
            manager.setOnCancelListener(() -> {
                if (popup != null) {
                    readerController.showPopup(popup.getId());
                }
                manager.setOnCancelListener(null);
            });
            startSearch(readerController.MiscOptions.TextSearchPattern.getValue(), true, null, false);
        } else {
            SearchDialogUtil.showDialog(
                    this, FBReader.class, readerController.MiscOptions.TextSearchPattern.getValue(), di -> {
                        if (popup != null) {
                            readerController.showPopup(popup.getId());
                        }
                    }
            );
        }
        return true;
    }

    private void setStatusBarVisibility(boolean visible) {
        if (DeviceType.Instance() != DeviceType.KINDLE_FIRE_1ST_GENERATION && !myShowStatusBarFlag) {
            if (visible) {
                getWindow().addFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
            } else {
                getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
            }
        }
    }

    private void switchWakeLock(boolean on) {
        if (on) {
            if (myWakeLock == null) {
                myWakeLockToCreate = true;
            }
        } else {
            if (myWakeLock != null) {
                synchronized (this) {
                    if (myWakeLock != null) {
                        myWakeLock.release();
                        myWakeLock = null;
                    }
                }
            }
        }
    }

    @SuppressLint("InvalidWakeLockTag")
    public final void createWakeLock() {
        if (myWakeLockToCreate) {
            synchronized (this) {
                if (myWakeLockToCreate) {
                    myWakeLockToCreate = false;
                    myWakeLock = ((PowerManager) getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK, "FBReader");
                    myWakeLock.acquire();
                }
            }
        }
        if (myStartTimer) {
            readerController.startTimer();
            myStartTimer = false;
        }
    }

    @Override
    public void setWindowTitle(final String title) {
        runOnUiThread(() -> setTitle(title));
    }

    @Override
    public void showErrorMessage(String key) {
        UIMessageUtil.showErrorMessage(this, key);
    }

    @Override
    public void showErrorMessage(String key, String parameter) {
        UIMessageUtil.showErrorMessage(this, key, parameter);
    }

    @Override
    public FBReaderApp.SynchronousExecutor createExecutor(String key) {
        return UIUtil.createExecutor(this, key);
    }

    @Override
    public void processException(Exception exception) {
        exception.printStackTrace();

        final Intent intent = new Intent(
                FBReaderIntents.Action.ERROR,
                new Uri.Builder().scheme(exception.getClass().getSimpleName()).build()
        );
        intent.setPackage(FBReaderIntents.DEFAULT_PACKAGE);
        intent.putExtra(ErrorKeys.MESSAGE, exception.getMessage());
        final StringWriter stackTrace = new StringWriter();
        exception.printStackTrace(new PrintWriter(stackTrace));
        intent.putExtra(ErrorKeys.STACKTRACE, stackTrace.toString());
		/*
		if (exception instanceof BookReadingException) {
			final ZLFile file = ((BookReadingException)exception).File;
			if (file != null) {
				intent.putExtra("file", file.getPath());
			}
		}
		*/
        try {
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            // ignore
            e.printStackTrace();
        }
    }

    @Override
    public void refresh() {
        runOnUiThread(() -> {
            for (Map.Entry<MenuItem, String> entry : myMenuItemMap.entrySet()) {
                final String actionId = entry.getValue();
                final MenuItem menuItem = entry.getKey();
                menuItem.setVisible(readerController.isActionVisible(actionId) && readerController.isActionEnabled(actionId));
                switch (readerController.isActionChecked(actionId)) {
                    case TRUE:
                        menuItem.setCheckable(true);
                        menuItem.setChecked(true);
                        break;
                    case FALSE:
                        menuItem.setCheckable(true);
                        menuItem.setChecked(false);
                        break;
                    case UNDEFINED:
                        menuItem.setCheckable(false);
                        break;
                }
            }
        });
    }

    @Override
    public ZLViewWidget getViewWidget(String from) {
//        Timber.v("渲染流程, getViewWidget, %s", from);
        return myMainView;
    }

    @Override
    public void close() {
        finish();
    }

    @Override
    public int getBatteryLevel() {
        return myBatteryLevel;
    }

    private void setBatteryLevel(int percent) {
        myBatteryLevel = percent;
    }

    public void outlineRegion(ZLTextRegion.Soul soul) {
        readerController.getTextView().outlineRegion(soul);
        readerController.getViewWidget().repaint("outlineRegion");
    }

    /**
     * 显示菜单
     */
    public void openMenu() {
        if (firstMenu.getVisibility() == View.VISIBLE) { // 第一菜单 -- > 隐藏之
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(firstMenu);
            AnimationHelper.closePreview(myMainView);
        } else if (menuSetting.getVisibility() == View.VISIBLE) { // 设置菜单 -- > 隐藏之
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(menuSetting);
        } else if (menuMore.getVisibility() == View.VISIBLE) { // 更多菜单 --> 隐藏之
            AnimationHelper.closeTopMenu(menuTop);
            AnimationHelper.closeBottomMenu(menuMore);
        } else { // 没菜单显示 --> 显示一级菜单
            initBookInfoView();
            AnimationHelper.openTopMenu(menuTop);
            AnimationHelper.openBottomMenu(firstMenu);
            // 阅读器内容预览关闭
            AnimationHelper.openPreview(myMainView);

            // 主题状态（当前为夜间主题，字面为日常模式,否则反之）
            if (readerController.isActionVisible(ActionCode.SWITCH_THEME_BLACK_PROFILE)) {
                quickThemeChangeText.setText("夜间模式");
                quickThemeChangeImg.setImageResource(R.drawable.ic_book_night);
            } else {
                quickThemeChangeText.setText("日常模式");
                quickThemeChangeImg.setImageResource(R.drawable.ic_book_day);
            }

            // 设置阅读进度
            final FBView textView = readerController.getTextView();
            ZLTextView.PagePosition pagePosition = textView.pagePosition();
            if (bookProgress.getMax() != pagePosition.Total - 1 || bookProgress.getProgress() != pagePosition.Current - 1) {
                bookProgress.setMax(pagePosition.Total - 1);
                bookProgress.setProgress(pagePosition.Current - 1);
            }
        }
    }

    /**
     * 初始化书籍信息
     */
    private void initBookInfoView() {
        Book book = readerController.getCurrentBook();
        if (book == null) {
            return;
        }
        String title = book.getTitle();
        tvTitle.setText(title);
    }

    public FBReaderApp getReaderController() {
        return readerController;
    }

    @Override
    public void invokeFlutterMethod(@NonNull String method, @Nullable Object arguments, @Nullable MethodChannel.Result callback) {
        if (!DebugHelper.ENABLE_FLUTTER) return;
        Objects.requireNonNull(flutterBridge, "flutterBridge is null!");
        flutterBridge.invokeMethod(method, arguments, callback);
    }

    /** 小提示 */
    private class TipRunner extends Thread {

        TipRunner() {
            setPriority(MIN_PRIORITY);
        }

        public void run() {
            final TipsManager manager = new TipsManager(Paths.systemInfo(FBReader.this));
            switch (manager.requiredAction()) {
                case Initialize:
                    startActivity(new Intent(
                            TipsActivity.INITIALIZE_ACTION, null, FBReader.this, TipsActivity.class
                    ));
                    break;
                case Show:
                    startActivity(new Intent(
                            TipsActivity.SHOW_TIP_ACTION, null, FBReader.this, TipsActivity.class
                    ));
                    break;
                case Download:
                    manager.startDownloading();
                    break;
                case None:
                    break;
            }
        }
    }
}