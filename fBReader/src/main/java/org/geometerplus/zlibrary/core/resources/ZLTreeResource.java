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

package org.geometerplus.zlibrary.core.resources;

import java.util.*;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import org.geometerplus.zlibrary.core.filesystem.*;
import org.geometerplus.zlibrary.core.language.Language;
import org.geometerplus.zlibrary.core.util.XmlUtil;

/**
 * App自带资源解析类: assets/resources下的xml格式的资源文件集体
 */
final class ZLTreeResource extends ZLResource {
	private static interface Condition {
		abstract boolean accepts(int number);
	}

	private static class ValueCondition implements Condition {
		private final int myValue;

		ValueCondition(int value) {
			myValue = value;
		}

		@Override
		public boolean accepts(int number) {
			return myValue == number;
		}
	}

	private static class RangeCondition implements Condition {
		private final int myMin;
		private final int myMax;

		RangeCondition(int min, int max) {
			myMin = min;
			myMax = max;
		}

		@Override
		public boolean accepts(int number) {
			return myMin <= number && number <= myMax;
		}
	}

	private static class ModRangeCondition implements Condition {
		private final int myMin;
		private final int myMax;
		private final int myBase;

		ModRangeCondition(int min, int max, int base) {
			myMin = min;
			myMax = max;
			myBase = base;
		}

		@Override
		public boolean accepts(int number) {
			number = number % myBase;
			return myMin <= number && number <= myMax;
		}
	}

	private static class ModCondition implements Condition {
		private final int myMod;
		private final int myBase;

		ModCondition(int mod, int base) {
			myMod = mod;
			myBase = base;
		}

		@Override
		public boolean accepts(int number) {
			return number % myBase == myMod;
		}
	}

	static private Condition parseCondition(String description) {
		final String[] parts = description.split(" ");
		try {
			if ("range".equals(parts[0])) {
				return new RangeCondition(Integer.parseInt(parts[1]), Integer.parseInt(parts[2]));
			} else if ("mod".equals(parts[0])) {
				return new ModCondition(Integer.parseInt(parts[1]), Integer.parseInt(parts[2]));
			} else if ("modrange".equals(parts[0])) {
				return new ModRangeCondition(Integer.parseInt(parts[1]), Integer.parseInt(parts[2]), Integer.parseInt(parts[3]));
			} else if ("value".equals(parts[0])) {
				return new ValueCondition(Integer.parseInt(parts[1]));
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	static volatile ZLTreeResource ourRoot;
	private static final Object ourLock = new Object();

	private static long ourTimeStamp = 0;
	private static String ourLanguage = null;
	private static String ourCountry = null;

	private boolean myHasValue;
	private	String myValue;
	private HashMap<String,ZLTreeResource> myChildren;
	private LinkedHashMap<Condition,String> myConditionalValues;

	/**
	 * 设置ourLanguag和our'Country两个属性
	 * 设置assets/resourses/application这个资源文件夹中默认文件uk.xml
	 */
	static void buildTree() {
		synchronized (ourLock) {
			if (ourRoot == null) {
				ourRoot = new ZLTreeResource("", null);
				ourLanguage = "en";
				ourCountry = "UK";
				loadData();
			}
		}
	}

	private static void setInterfaceLanguage() {
		final String custom = getLanguageOption().getValue();
		final String language;
		final String country;
		if (Language.SYSTEM_CODE.equals(custom)) {
			final Locale locale = Locale.getDefault();
			// 获取手机默认语言设置
			language = locale.getLanguage();
			// 获取手机默认区域设置
			country = locale.getCountry();
		} else {
			final int index = custom.indexOf('_');
			if (index == -1) {
				language = custom;
				country = null;
			} else {
				language = custom.substring(0, index);
				country = custom.substring(index + 1);
			}
		}
		if ((language != null && !language.equals(ourLanguage)) ||
			(country != null && !country.equals(ourCountry))) {
			ourLanguage = language;
			ourCountry = country;
			// 根据语言和区域设置设置去解析资源文件
			loadData();
		}
	}

	/**
	 * 根据手机语言解析app资源文件
	 */
	private static void updateLanguage() {
		final long timeStamp = System.currentTimeMillis();
		if (timeStamp > ourTimeStamp + 1000) {
			synchronized (ourLock) {
				if (timeStamp > ourTimeStamp + 1000) {
					ourTimeStamp = timeStamp;
					setInterfaceLanguage();
				}
			}
		}
	}

	/**
	 * 读取assets/resources下的xml格式的资源文件集体
	 */
	private static void loadData(ResourceTreeReader reader, String fileName) {
		reader.readDocument(ourRoot, ZLResourceFile.createResourceFile("resources/zlibrary/" + fileName));
		reader.readDocument(ourRoot, ZLResourceFile.createResourceFile("resources/application/" + fileName));
		reader.readDocument(ourRoot, ZLResourceFile.createResourceFile("resources/lang.xml"));
		reader.readDocument(ourRoot, ZLResourceFile.createResourceFile("resources/application/neutral.xml"));
	}

	private static void loadData() {
		ResourceTreeReader reader = new ResourceTreeReader();
		loadData(reader, ourLanguage + ".xml");
		loadData(reader, ourLanguage + "_" + ourCountry + ".xml");
	}

	private	ZLTreeResource(String name, String value) {
		super(name);
		setValue(value);
	}

	private void setValue(String value) {
		myHasValue = value != null;
		myValue = value;
	}

	@Override
	public boolean hasValue() {
		return myHasValue;
	}

	@Override
	public String getValue() {
		updateLanguage();
		return myHasValue ? myValue : ZLMissingResource.Value;
	}

	@Override
	public String getValue(int number) {
		updateLanguage();
		if (myConditionalValues != null) {
			for (Map.Entry<Condition,String> entry: myConditionalValues.entrySet()) {
				if (entry.getKey().accepts(number)) {
					return entry.getValue();
				}
			}
		}
		return myHasValue ? myValue : ZLMissingResource.Value;
	}

	/**
	 * 这个方法其实就是一层一层找每个节点的子节点有没有想要的节点。
	 * 其实，如果节点的名字都不重复的话，这里直接使用递归也是可以的
	 */
	@Override
	public ZLResource getResource(String key) {
		final HashMap<String,ZLTreeResource> children = myChildren;
		if (children != null) {
			ZLTreeResource child = children.get(key);
			if (child != null) {
				return child;
			}
		}
		return ZLMissingResource.Instance;
	}

	private static class ResourceTreeReader extends DefaultHandler {
		private static final String NODE = "node";
		private final ArrayList<ZLTreeResource> myStack = new ArrayList<ZLTreeResource>();

		public void readDocument(ZLTreeResource root, ZLFile file) {
			myStack.clear();
			myStack.add(root);
			XmlUtil.parseQuietly(file, this);
		}

		/**
		 eg: <node name="waitMessage">
				 <node name="translating" value="Translation in progress…" toBeTranslated="true"/>
				 <node name="tryConnect" value="Trying to connect. Please wait…" toBeTranslated="true"/>
				 <node name="downloadingBook" value="正下載 %s"/>
				 <node name="search" value="搜尋中，請稍候 …"/>
				 <node name="loadInfo" value="Loading information. Please wait…" toBeTranslated="true"/>
				 <node name="loadingBook" value="打開書藉中，請稍候…"/>
				 <node name="loadingBookList" value="打開書庫中，請稍候…"/>
		     </node>

		 代码读取到waitMessage节点开始标签右边的“>”时候，会触发ResourceTreeReader类中的startElementHandler方法
		 */
		@Override
		public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
			final ArrayList<ZLTreeResource> stack = myStack;
			if (!stack.isEmpty() && (NODE.equals(localName))) {
				// name代表waitMessage节点的name属性
				final String name = attributes.getValue("name");
				final String condition = attributes.getValue("condition");
				final String value = attributes.getValue("value");
				// peek代表根节点
				final ZLTreeResource peek = stack.get(stack.size() - 1);
				if (name != null) {
					ZLTreeResource node;
					HashMap<String,ZLTreeResource> children = peek.myChildren;
					if (children == null) {
						node = null;
						children = new HashMap<String,ZLTreeResource>();
						// 给"根节点"加入一个空的子节点
						peek.myChildren = children;
					} else {
						node = children.get(name);
					}
					if (node == null) {
						// 代表waitMessage的节点
						node = new ZLTreeResource(name, value);
						// 相当于waitMessage节点代替了空的子节点，成为了根节点的子节点了
						children.put(name, node);
					} else {
						if (value != null) {
							node.setValue(value);
							node.myConditionalValues = null;
						}
					}
					// 将代表waitMessage节点的node加入了myStack变量所指向ArrayList里面
					stack.add(node);
				} else if (condition != null && value != null) {
					final Condition compiled = parseCondition(condition);
					if (compiled != null) {
						if (peek.myConditionalValues == null) {
							peek.myConditionalValues = new LinkedHashMap<Condition,String>();
						}
						peek.myConditionalValues.put(compiled, value);
					}
					stack.add(peek);
				}
			}
		}

		/**
		 * 程序会读到代表translating节点结束标签里的“/”，于是ResourceTreeReader类中的endElementHandler方法被调用
		 */
		@Override
		public void endElement(String uri, String localName, String qName) throws SAXException {
			final ArrayList<ZLTreeResource> stack = myStack;
			if (!stack.isEmpty() && (NODE.equals(localName))) {
				stack.remove(stack.size() - 1);
			}
		}
	}
}
