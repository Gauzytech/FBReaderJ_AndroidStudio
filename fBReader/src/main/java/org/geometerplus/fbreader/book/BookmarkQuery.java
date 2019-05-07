package org.geometerplus.fbreader.book;

/**
 * 书签查询
 */
public final class BookmarkQuery {

	public final AbstractBook Book;
	/**
	 * 是否可见
	 */
	public final boolean Visible;
	/**
	 * 字符数限制
	 */
	public final int Limit;
	public final int Page;

	public BookmarkQuery(int limit) {
		this(null, limit);
	}

	public BookmarkQuery(AbstractBook book, int limit) {
		this(book, true, limit);
	}

	public BookmarkQuery(AbstractBook book, boolean visible, int limit) {
		this(book, visible, limit, 0);
	}

	BookmarkQuery(AbstractBook book, boolean visible, int limit, int page) {
		Book = book;
		Visible = visible;
		Limit = limit;
		Page = page;
	}

	public BookmarkQuery next() {
		return new BookmarkQuery(Book, Visible, Limit, Page + 1);
	}
}
