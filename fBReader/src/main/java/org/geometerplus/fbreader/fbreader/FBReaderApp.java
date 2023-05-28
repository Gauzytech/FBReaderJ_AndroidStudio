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

package org.geometerplus.fbreader.fbreader;

import static org.geometerplus.zlibrary.ui.android.view.bookrender.FlutterCommand.CMD_INIT_RENDER;

import android.graphics.Bitmap;

import java.util.*;

import org.fbreader.util.ComparisonUtil;

import org.geometerplus.DebugHelper;
import org.geometerplus.zlibrary.core.application.*;
import org.geometerplus.zlibrary.core.drm.FileEncryptionInfo;
import org.geometerplus.zlibrary.core.drm.EncryptionMethod;
import org.geometerplus.zlibrary.core.util.*;

import org.geometerplus.zlibrary.core.view.ZLViewEnums;
import org.geometerplus.zlibrary.text.hyphenation.ZLTextHyphenator;
import org.geometerplus.zlibrary.text.model.ZLTextModel;
import org.geometerplus.zlibrary.text.view.*;

import org.geometerplus.fbreader.book.*;
import org.geometerplus.fbreader.bookmodel.*;
import org.geometerplus.fbreader.fbreader.options.*;
import org.geometerplus.fbreader.formats.*;
import org.geometerplus.fbreader.network.sync.SyncData;
import org.geometerplus.fbreader.util.*;
import org.geometerplus.zlibrary.ui.android.view.bookrender.ContentProcessor;
import org.geometerplus.zlibrary.ui.android.view.bookrender.ContentProcessorImpl;

import timber.log.Timber;

/**
 * 阅读界面管理类, readerController
 */
public final class FBReaderApp extends ZLApplication {

    public final MiscOptions MiscOptions = new MiscOptions();
    public final ImageOptions ImageOptions = new ImageOptions();
    public final ViewOptions ViewOptions = new ViewOptions();
    public final PageTurningOptions PageTurningOptions = new PageTurningOptions();
    public final SyncOptions SyncOptions = new SyncOptions();
    // 管理所有图书内容绘制数据的类
    public final FBView bookTextView;
    // 管理所有图书显示界面脚注绘制数据的类
    public final FBView footnoteView;
    public final IBookCollection<Book> Collection;
    private final ZLKeyBindings myBindings = new ZLKeyBindings();
    private final SyncData mySyncData = new SyncData();
    private final SaverThread mySaverThread = new SaverThread();
    public volatile BookModel bookModel;
    public volatile Book externalBook;
    private ExternalFileOpener myExternalFileOpener;
    private String myFootnoteModelId;
    private ZLTextPosition myJumpEndPosition;
    private Date myJumpTimeStamp;
    // 保存的阅读进度position
    private volatile ZLTextPosition myStoredPosition;
    private volatile Book myStoredPositionBook;

    // 内容渲染presenter
    public ContentProcessor contentProcessor;

    public FBReaderApp(SystemInfo systemInfo, final IBookCollection<Book> collection) {
        super(systemInfo);

        Collection = collection;

        collection.addListener(new IBookCollection.Listener<Book>() {
            public void onBookEvent(BookEvent event, Book book) {
                switch (event) {
                    case BookMarkUpdated:
                        if (bookModel != null && (book == null || collection.sameBook(book, bookModel.book()))) {
                            if (bookTextView.getModel() != null) {
                                setBookMarkHighlighting(bookTextView, null);
                            }
                        }
                        break;
                    case BookNoteStyleChanged:
                    case BookNoteUpdated:
                        if (bookModel != null && (book == null || collection.sameBook(book, bookModel.book()))) {
                            if (bookTextView.getModel() != null) {
                                setBookNoteHighlighting(bookTextView, null);
                            }
                            if (footnoteView.getModel() != null && myFootnoteModelId != null) {
                                setBookNoteHighlighting(footnoteView, myFootnoteModelId);
                            }
                        }
                        break;
                    case Updated:
                        onBookUpdated(book);
                        break;
                }
            }

            public void onBuildEvent(IBookCollection.Status status) {
            }
        });

        addAction(ActionCode.INCREASE_FONT, new ChangeFontSizeAction(this, +2));
        addAction(ActionCode.DECREASE_FONT, new ChangeFontSizeAction(this, -2));

        addAction(ActionCode.FIND_NEXT, new FindNextAction(this));
        addAction(ActionCode.FIND_PREVIOUS, new FindPreviousAction(this));
        addAction(ActionCode.CLEAR_FIND_RESULTS, new ClearFindResultsAction(this));

        addAction(ActionCode.SELECTION_CLEAR, new SelectionClearAction(this));

        addAction(ActionCode.TURN_PAGE_FORWARD, new TurnPageAction(this, true));
        addAction(ActionCode.TURN_PAGE_BACK, new TurnPageAction(this, false));

        addAction(ActionCode.MOVE_CURSOR_UP, new MoveCursorAction(this, FBView.Direction.up));
        addAction(ActionCode.MOVE_CURSOR_DOWN, new MoveCursorAction(this, FBView.Direction.down));
        addAction(ActionCode.MOVE_CURSOR_LEFT, new MoveCursorAction(this, FBView.Direction.rightToLeft));
        addAction(ActionCode.MOVE_CURSOR_RIGHT, new MoveCursorAction(this, FBView.Direction.leftToRight));

        addAction(ActionCode.VOLUME_KEY_SCROLL_FORWARD, new VolumeKeyTurnPageAction(this, true));
        addAction(ActionCode.VOLUME_KEY_SCROLL_BACK, new VolumeKeyTurnPageAction(this, false));

        addAction(ActionCode.EXIT, new ExitAction(this));

        bookTextView = new FBView(this);
        footnoteView = new FBView(this);

        setView(bookTextView, "constructor");

        // 内容渲染presenter
        contentProcessor = new ContentProcessorImpl(this, systemInfo);
    }

    public void setExternalFileOpener(ExternalFileOpener o) {
        myExternalFileOpener = o;
    }

    public Book getCurrentBook() {
        final BookModel m = bookModel;
        return m != null ? m.book() : externalBook;
    }

    public void openHelpBook() {
        openBook(Collection.getBookByFile(BookUtil.getHelpFile().getPath()), null, null, null, "openHelpBook");
    }

    public Book getCurrentServerBook(Notifier notifier) {
        final SyncData.ServerBookInfo info = mySyncData.getServerBookInfo();
        if (info == null) {
            return null;
        }
        Timber.i("ceshi123, 获得图书基本信息: " + info);
        for (String hash : info.Hashes) {
            final Book book = Collection.getBookByHash(hash);
            if (book != null) {
                Timber.i("ceshi123, 获得图书解析信息: " + book);
                return book;
            }
        }
        if (notifier != null) {
            notifier.showMissingBookNotification(info);
        }
        return null;
    }

    /**
     * 打开图书
     */
    public void openBook(Book book, final Bookmark bookmark, Runnable postAction, Notifier notifier, String from) {
        Timber.i("打开图书:渲染流程, %s, Thread = %s, from = %s", book, Thread.currentThread().getName(), from);
        if (bookModel != null) {
            if (book == null || bookmark == null && Collection.sameBook(book, bookModel.book())) {
                return;
            }
        }

        if (book == null) {
            book = getCurrentServerBook(notifier);
            if (book == null) {
                book = Collection.getRecentBook(0);
            }
            if (book == null || !BookUtil.fileByBook(book).exists()) {
                book = Collection.getBookByFile(BookUtil.getHelpFile().getPath());
            }
            if (book == null) {
                return;
            }
        }
        final Book bookToOpen = book;
        bookToOpen.addNewLabel(Book.READ_LABEL);
        Collection.saveBook(bookToOpen);

        // executor.execute会显示一个loadingDialog
        final SynchronousExecutor executor = createExecutor("loadingBook");
        executor.execute(new Runnable() {
            public void run() {
                Timber.d("打开图书, 开始打开图书, 当前线程 = %s",
                        Thread.currentThread().getName());
                openBookInternal(bookToOpen, bookmark, false);
            }
        }, postAction);
    }

    private void reloadBook() {
        final Book book = getCurrentBook();
        if (book != null) {
            final SynchronousExecutor executor = createExecutor("loadingBook");
            executor.execute(new Runnable() {
                public void run() {
                    openBookInternal(book, null, true);
                }
            }, null);
        }
    }

    public ZLKeyBindings keyBindings() {
        return myBindings;
    }

    public void onWindowClosing() {
        storePosition();
    }

    @Override
    public void onCleared() {
        contentProcessor = null;
    }

    public void storePosition() {
        final Book bk = bookModel != null ? bookModel.book() : null;
        if (bk != null && bk == myStoredPositionBook && myStoredPosition != null && bookTextView != null) {
            final ZLTextPosition position = new ZLTextFixedPosition(bookTextView.getStartCursor());
            if (!myStoredPosition.equals(position)) {
                myStoredPosition = position;
                savePosition();
            }
        }
    }

    /**
     * 存储进度
     */
    private void savePosition() {
        final RationalNumber progress = bookTextView.getProgress();
        synchronized (mySaverThread) {
            if (!mySaverThread.isAlive()) {
                mySaverThread.start();
            }
            mySaverThread.add(new PositionSaver(myStoredPositionBook, myStoredPosition, progress));
        }
    }

    public AutoTextSnippet getFootnoteData(String id) {
        if (bookModel == null) {
            return null;
        }
        final BookModel.Label label = bookModel.getLabel(id);
        if (label == null) {
            return null;
        }
        final ZLTextModel model;
        if (label.modelId() != null) {
            model = bookModel.getFootnoteModel(label.modelId());
        } else {
            model = bookModel.getTextModel();
        }
        if (model == null) {
            return null;
        }
        final ZLTextWordCursor cursor =
                new ZLTextWordCursor(new ZLTextParagraphCursor(model, label.paragraphIndex()));
        final AutoTextSnippet longSnippet = new AutoTextSnippet(cursor, 140);
        if (longSnippet.IsEndOfText) {
            return longSnippet;
        } else {
            return new AutoTextSnippet(cursor, 100);
        }
    }

    public void tryOpenFootnote(String id) {
        if (bookModel != null) {
            myJumpEndPosition = null;
            myJumpTimeStamp = null;
            final BookModel.Label label = bookModel.getLabel(id);
            if (label != null) {
                if (label.modelId() == null) {
                    if (getTextView() == bookTextView) {
                        addInvisibleBookmark();
                        myJumpEndPosition = new ZLTextFixedPosition(label.paragraphIndex(), 0, 0);
                        myJumpTimeStamp = new Date();
                    }
                    bookTextView.gotoPosition(label.paragraphIndex(), 0, 0);
                    setView(bookTextView, "tryOpenFootnote");
                } else {
                    setFootnoteModel(label.modelId());
                    setView(footnoteView, "tryOpenFootnote");
                    footnoteView.gotoPosition(label.paragraphIndex(), 0, 0);
                }
                getViewWidget().repaint("tryOpenFootnote");
                storePosition();
            }
        }
    }

    public FBView getTextView() {
        Timber.v("渲染流程, getTextView -> getCurrentView");
        return (FBView) getCurrentView();
    }

    public void addInvisibleBookmark() {
        if (bookModel.book() != null && getTextView() == bookTextView) {
            updateInvisibleBookmarksList(createBookmark(30, false, Bookmark.Type.BookOther));
        }
    }

    private void setFootnoteModel(String modelId) {
        final ZLTextModel model = bookModel.getFootnoteModel(modelId);
        footnoteView.setTextModel(model);
        if (model != null) {
            myFootnoteModelId = modelId;
            setBookNoteHighlighting(footnoteView, modelId);
        }
    }

    private synchronized void updateInvisibleBookmarksList(Bookmark b) {
        if (bookModel != null && bookModel.book() != null && b != null) {
            for (Bookmark bm : invisibleBookmarks()) {
                if (b.equals(bm)) {
                    Collection.deleteBookmark(bm);
                }
            }
            Collection.saveBookmark(b);
            final List<Bookmark> bookmarks = invisibleBookmarks();
            for (int i = 3; i < bookmarks.size(); ++i) {
                Collection.deleteBookmark(bookmarks.get(i));
            }
        }
    }

    public Bookmark createBookmark(int maxChars, boolean visible, Bookmark.Type markType) {
        final FBView view = getTextView();
        final ZLTextWordCursor cursor = view.getStartCursor();

        if (cursor.isNull()) {
            return null;
        }

        return new Bookmark(
                Collection,
                bookModel.book(),
                view.getModel().getId(),
                new AutoTextSnippet(cursor, maxChars),
                visible,
                markType
        );
    }

    /**
     * 设置笔记高亮
     *
     * @param view    ZLTextView
     * @param modelId modelId
     */
    private void setBookNoteHighlighting(ZLTextView view, String modelId) {
        boolean hasBookNote = false;
        view.removeHighlightings(BookmarkHighlighting.class);
        for (BookmarkQuery query = new BookmarkQuery(bookModel.book(), Bookmark.Type.BookNote.ordinal(), 20); ; query = query.next()) {
            final List<Bookmark> bookmarks = Collection.bookmarks(query);
            if (bookmarks.isEmpty()) {
                break;
            }
            hasBookNote = true;
            for (Bookmark b : bookmarks) {
                if (b.getEnd() == null) {
                    BookmarkUtil.findEnd(b, view);
                }
                if (ComparisonUtil.equal(modelId, b.ModelId)) {
                    view.addHighlighting(new BookmarkHighlighting(view, Collection, b));
                }
            }
        }
        if (!hasBookNote) {
            view.repaint("setBookNoteHighlighting");
        }
    }

    private List<Bookmark> invisibleBookmarks() {
        final List<Bookmark> bookmarks = Collection.bookmarks(
                new BookmarkQuery(bookModel.book(), Bookmark.Type.BookOther.ordinal(), false, 10)
        );
        Collections.sort(bookmarks, new Bookmark.ByTimeComparator());
        return bookmarks;
    }

    public Bookmark createBookmark(int maxChars, Bookmark.Type markType) {
        final FBView view = getTextView();
        final ZLTextWordCursor cursor = view.getStartCursor();

        if (cursor.isNull()) {
            return null;
        }

        return new Bookmark(
                Collection,
                bookModel.book(),
                view.getModel().getId(),
                new AutoTextSnippet(cursor, maxChars),
                true,
                markType
        );
    }

    public void clearTextCaches() {
        bookTextView.clearCaches();
        footnoteView.clearCaches();
    }

    public Bookmark addSelectionBookmark() {
        final FBView fbView = getTextView();
        final TextSnippet snippet = fbView.getSelectedSnippet();
        if (snippet == null) {
            return null;
        }

        final Bookmark bookmark = new Bookmark(
                Collection,
                bookModel.book(),
                fbView.getModel().getId(),
                snippet,
                true,
                Bookmark.Type.BookNote
        );
        Collection.saveBookmark(bookmark);
        fbView.clearSelection();

        System.out.println(" 书签类型 1 ==> " + bookmark.MarkType);

        return bookmark;
    }

    /**
     * 设置标签高亮
     *
     * @param view    ZLTextView
     * @param modelId modelId
     */
    private void setBookMarkHighlighting(ZLTextView view, String modelId) {
        boolean hasBookMark = false;
        view.removeMarkHighlight(BookmarkHighlighting.class);
        for (BookmarkQuery query = new BookmarkQuery(bookModel.book(), Bookmark.Type.BookMark.ordinal(), 20); ; query = query.next()) {
            final List<Bookmark> bookmarks = Collection.bookmarks(query);
            if (bookmarks.isEmpty()) {
                break;
            }
            hasBookMark = true;
            for (Bookmark b : bookmarks) {
                if (b.getEnd() == null) {
                    BookmarkUtil.findEnd(b, view);
                }
                if (ComparisonUtil.equal(modelId, b.ModelId)) {
                    view.addBookMark(new BookmarkHighlighting(view, Collection, b));
                }
            }
        }
        if (!hasBookMark) {
            view.repaint("setBookMarkHighlighting");
        }
    }

    /**
     * 打开书, 解析epub文件
     *
     * @param book     图书对象
     * @param bookmark 书签
     * @param force    强制
     */
    private synchronized void openBookInternal(final Book book, Bookmark bookmark, boolean force) {
        Timber.v("打开图书:渲染流程, ------------------openBookInternal 图书渲染入口------------------");
        if (!force && bookModel != null && Collection.sameBook(book, bookModel.book())) {
            if (bookmark != null) {
                gotoBookmark(bookmark, false);
            }
            return;
        }

        hideActivePopup();
        storePosition();

        bookTextView.setTextModel(null);
        footnoteView.setTextModel(null);
        clearTextCaches();
        bookModel = null;
        externalBook = null;
        // 清理内存 避免OOM
        System.gc();
        System.gc();

        // 通过cpp层获得所有native plugin
        final PluginCollection pluginCollection = PluginCollection.Instance(SystemInfo);
        final FormatPlugin plugin;
        try {
            plugin = BookUtil.getPlugin(pluginCollection, book);
        } catch (BookReadingException e) {
            processException(e);
            return;
        }
        Timber.v("打开图书:渲染流程, 成功获得图书解析plugin: %s", plugin.name());
        // ExternalFormatPlugin: pdf, djvu, comic plugin
        if (plugin instanceof ExternalFormatPlugin) {
            externalBook = book;
            final Bookmark bm;
            if (bookmark != null) {
                bm = bookmark;
            } else {
                ZLTextPosition pos = getStoredPosition(book);
                if (pos == null) {
                    pos = new ZLTextFixedPosition(0, 0, 0);
                }
                bm = new Bookmark(Collection, book, "", new EmptyTextSnippet(pos), false, Bookmark.Type.BookMark);
            }
            myExternalFileOpener.openFile((ExternalFormatPlugin) plugin, book, bm);
            return;
        }

        // BuiltinFormatPlugin:
        // 1. FB2NativePlugin,
        // 2. OEBNativePlugin
        try {
            // 开始解析图书, 将所有图书内容存入bookModel中
            // bookModel.myBookTextModel里保存了所有章节渲染信息
            bookModel = BookModel.createModel(book, plugin);
            Timber.v("打开图书:渲染流程, 解析成功！--------------------------接下来将开始渲染流程----------------------");
            // 保存图书基本信息
            Collection.saveBook(book);
            // 这一步干啥的????
            ZLTextHyphenator.Instance().load(book.getLanguage());
            // todo FLUTTER 将fbView赋值给ReaderWidget
            if (DebugHelper.ENABLE_FLUTTER) {
                // 获得第一个paragraph的对象, 并使用moveStartCursor()将对象设为当前page
                bookTextView.setTextModel(bookModel.getTextModel());

                Timber.v("flutter内容绘制流程, 请求%s", CMD_INIT_RENDER);
                invokeFlutterMethod(CMD_INIT_RENDER, null, null);

            } else {
                // 获得第一个paragraph的对象, 并使用moveStartCursor()将对象设为当前page
                bookTextView.setTextModel(bookModel.getTextModel());
                // 阅读进度跳转 todo
                gotoStoredPosition();
                // 书签
                setBookMarkHighlighting(bookTextView, null);
                // 笔记
                setBookNoteHighlighting(bookTextView, null);
                if (bookmark == null) {
                    setView(bookTextView, "openBookInternal");
                } else {
                    gotoBookmark(bookmark, false);
                }

                // 将图书添加到"最近阅读"
                Collection.addToRecentlyOpened(book);

                // 将author append到书名title后面
                final StringBuilder title = new StringBuilder(book.getTitle());
                if (!book.authors().isEmpty()) {
                    boolean first = true;
                    for (Author a : book.authors()) {
                        title.append(first ? " (" : ", ");
                        title.append(a.DisplayName);
                        first = false;
                    }
                    title.append(")");
                }
                setTitle(title.toString());
            }
        } catch (BookReadingException e) {
            processException(e);
        }

        getViewWidget().reset("openBookInternal");
        // 触发ZLAndroidWidget类的onDraw方法, 显示图书
        getViewWidget().repaint("openBookInternal");

        // 如果是不支持的DRM解析格式, 显示错误信息
        for (FileEncryptionInfo info : plugin.readEncryptionInfos(book)) {
            if (info != null && !EncryptionMethod.isSupported(info.Method)) {
                showErrorMessage("unsupportedEncryptionMethod", book.getPath());
                break;
            }
        }
    }

    public boolean jumpBack() {
        try {
            if (getTextView() != bookTextView) {
                showBookTextView();
                return true;
            }

            if (myJumpEndPosition == null || myJumpTimeStamp == null) {
                return false;
            }
            // more than 2 minutes ago
            if (myJumpTimeStamp.getTime() + 2 * 60 * 1000 < new Date().getTime()) {
                return false;
            }
            if (!myJumpEndPosition.equals(bookTextView.getStartCursor())) {
                return false;
            }

            final List<Bookmark> bookmarks = invisibleBookmarks();
            if (bookmarks.isEmpty()) {
                return false;
            }
            final Bookmark b = bookmarks.get(0);
            Collection.deleteBookmark(b);
            gotoBookmark(b, true);
            return true;
        } finally {
            myJumpEndPosition = null;
            myJumpTimeStamp = null;
        }
    }

    public void showBookTextView() {
        setView(bookTextView, "showBookTextView");
    }

    private void gotoBookmark(Bookmark bookmark, boolean exactly) {
        final String modelId = bookmark.ModelId;
        if (modelId == null) {
            addInvisibleBookmark();
            if (exactly) {
                bookTextView.gotoPosition(bookmark);
            } else {
                bookTextView.gotoHighlighting(
                        new BookmarkHighlighting(bookTextView, Collection, bookmark)
                );
            }
            setView(bookTextView, "gotoBookmark");
        } else {
            setFootnoteModel(modelId);
            if (exactly) {
                footnoteView.gotoPosition(bookmark);
            } else {
                footnoteView.gotoHighlighting(
                        new BookmarkHighlighting(footnoteView, Collection, bookmark)
                );
            }
            setView(footnoteView, "gotoBookmark");
        }
        getViewWidget().repaint("gotoBookmark");
        storePosition();
    }

    public void useSyncInfo(boolean openOtherBook, Notifier notifier) {
        if (openOtherBook && SyncOptions.ChangeCurrentBook.getValue()) {
            final Book fromServer = getCurrentServerBook(notifier);
            if (fromServer != null && !Collection.sameBook(fromServer, Collection.getRecentBook(0))) {
                openBook(fromServer, null, null, notifier, "useSyncInfo");
                return;
            }
        }

        if (myStoredPositionBook != null &&
                mySyncData.hasPosition(Collection.getHash(myStoredPositionBook, true))) {
            gotoStoredPosition();
            storePosition();
        }
    }

    private ZLTextFixedPosition getStoredPosition(Book book) {
        final ZLTextFixedPosition.WithTimestamp fromServer =
                mySyncData.getAndCleanPosition(Collection.getHash(book, true));
        // 从数据库获得阅读进度
        // paragraphIndex, elementIndex, charIndex, timeStamp
        final ZLTextFixedPosition.WithTimestamp local =
                Collection.getStoredPosition(book.getId());
        Timber.v("渲染流程, 获取阅读进度: server = %s, local = %s", fromServer, local);

        // 通过对比timeStamp返回latest position
        if (local == null) {
            return fromServer != null ? fromServer : new ZLTextFixedPosition(0, 0, 0);
        } else if (fromServer == null) {
            return local;
        } else {
            return fromServer.Timestamp >= local.Timestamp ? fromServer : local;
        }
    }


    private void gotoStoredPosition() {
        myStoredPositionBook = bookModel != null ? bookModel.book() : null;
        if (myStoredPositionBook == null) {
            return;
        }
        myStoredPosition = getStoredPosition(myStoredPositionBook);
        bookTextView.gotoPosition(myStoredPosition);
        savePosition();
    }

    public boolean hasCancelActions() {
        return new CancelMenuHelper().getActionsList(Collection).size() > 1;
    }

    public void runCancelAction(CancelMenuHelper.ActionType type, Bookmark bookmark) {
        switch (type) {
            case library:
                runAction(ActionCode.SHOW_LIBRARY);
                break;
            case networkLibrary:
                runAction(ActionCode.SHOW_NETWORK_LIBRARY);
                break;
            case previousBook:
                openBook(Collection.getRecentBook(1), null, null, null, "runCancelAction");
                break;
            case returnTo:
                Collection.deleteBookmark(bookmark);
                gotoBookmark(bookmark, true);
                break;
            case close:
                closeWindow();
                break;
        }
    }

    public void addInvisibleBookmark(ZLTextWordCursor cursor) {
        if (cursor == null) {
            return;
        }

        cursor = new ZLTextWordCursor(cursor);
        if (cursor.isNull()) {
            return;
        }

        final ZLTextView textView = getTextView();
        final ZLTextModel textModel;
        final Book book;
        final AutoTextSnippet snippet;
        // textView.model will not be changed inside synchronised block
        synchronized (textView) {
            textModel = textView.getModel();
            final BookModel model = bookModel;
            book = model != null ? model.book() : null;
            if (book == null || textView != bookTextView || textModel == null) {
                return;
            }
            snippet = new AutoTextSnippet(cursor, 30);
        }

        updateInvisibleBookmarksList(new Bookmark(
                Collection, book, textModel.getId(), snippet, false, Bookmark.Type.BookOther
        ));
    }

    /**
     * @return 获取当前目录树
     */
    public TOCTree getCurrentTOCElement() {
        final ZLTextWordCursor cursor = bookTextView.getStartCursor();
        if (bookModel == null || cursor == null) {
            return null;
        }

        int index = cursor.getParagraphIndex();
        if (cursor.isEndOfParagraph()) {
            ++index;
        }
        TOCTree treeToSelect = null;
        for (TOCTree tree : bookModel.tocTree()) {
            final TOCTree.Reference reference = tree.getReference();
            if (reference == null) {
                continue;
            }
            if (reference.ParagraphIndex > index) {
                break;
            }
            treeToSelect = tree;
        }
        return treeToSelect;
    }

    public void onBookUpdated(Book book) {
        if (!DebugHelper.ENABLE_ON_BOOK_UPDATED) return;
        if (bookModel == null || bookModel.book() == null || !Collection.sameBook(bookModel.book(), book)) {
            return;
        }

        final String newEncoding = book.getEncodingNoDetection();
        final String oldEncoding = bookModel.book().getEncodingNoDetection();

        bookModel.book().updateFrom(book);

        if (newEncoding != null && !newEncoding.equals(oldEncoding)) {
            reloadBook();
        } else {
            ZLTextHyphenator.Instance().load(bookModel.book().getLanguage());
            clearTextCaches();
            getViewWidget().repaint("onBookUpdated");
        }
    }

    public void cachePageBitmap(ZLViewEnums.PageIndex pageIndex) {
        Objects.requireNonNull(getViewWidget()).cacheBitmap(pageIndex);
    }

    public interface ExternalFileOpener {
        void openFile(ExternalFormatPlugin plugin, Book book, Bookmark bookmark);
    }

    public interface Notifier {
        void showMissingBookNotification(SyncData.ServerBookInfo info);
    }

    /**
     * 进度存储
     */
    private class PositionSaver implements Runnable {

        private final Book myBook;
        private final ZLTextPosition myPosition;
        private final RationalNumber myProgress;

        PositionSaver(Book book, ZLTextPosition position, RationalNumber progress) {
            myBook = book;
            myPosition = position;
            myProgress = progress;
        }

        public void run() {
            Collection.storePosition(myBook.getId(), myPosition);
            myBook.setProgress(myProgress);
            Collection.saveBook(myBook);
        }
    }

    /**
     * 存储线程（500毫秒定时）
     */
    private class SaverThread extends Thread {

        /**
         * 任务列表
         */
        private final List<Runnable> myTasks = Collections.synchronizedList(new LinkedList<>());

        SaverThread() {
            setPriority(MIN_PRIORITY);
        }

        /**
         * 添加任务
         *
         * @param task Runnable
         */
        void add(Runnable task) {
            myTasks.add(task);
        }

        public void run() {
            while (true) {
                synchronized (myTasks) {
                    while (!myTasks.isEmpty()) {
                        myTasks.remove(0).run();
                    }
                }
                try {
                    sleep(500);
                } catch (InterruptedException e) {
                    // Empty
                }
            }
        }
    }
}
