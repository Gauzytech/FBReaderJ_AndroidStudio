/*
 * Copyright (C) 2011-2015 FBReader.ORG Limited <contact@fbreader.org>
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

#include <vector>

#include <AndroidUtil.h>
#include <JniEnvelope.h>

#include "fbreader/src/formats/FormatPlugin.h"

extern "C"
JNIEXPORT jobjectArray JNICALL Java_org_geometerplus_fbreader_formats_PluginCollection_nativePlugins(JNIEnv* env, jobject thiz, jobject systemInfo) {
	// 获得所有plugin: FB2Plugin, HtmlPlugin, TxtPlugin, MobipocketPlugin, OEBPlugin, RtfPlugin, DocPlugin
	// plugins是个vector
	const std::vector<shared_ptr<FormatPlugin> > plugins = PluginCollection::Instance().plugins();
	const std::size_t size = plugins.size();
	jclass cls = AndroidUtil::Class_NativeFormatPlugin.j();
	// 创建java数组
	// TODO: memory leak?
	jobjectArray javaPlugins = env->NewObjectArray(size, cls, 0);

	// 遍历所有plugin, 把所有plugin对象加入到javaPlugins数组中
	for (std::size_t i = 0; i < size; ++i) {
		// 获得plugin对应的fileType
		jstring fileTypeJStr = AndroidUtil::createJavaString(env, plugins[i]->supportedFileType());
		// 使用java层面NativeFormatPlugin.create()创建plugin对象
		jobject pluginJObj = AndroidUtil::StaticMethod_NativeFormatPlugin_create->call(systemInfo, fileTypeJStr);
		// 将plugin对象加入javaPlugin数组中
		env->SetObjectArrayElement(javaPlugins, i, pluginJObj);
		// 删除引用
		env->DeleteLocalRef(pluginJObj);
		env->DeleteLocalRef(fileTypeJStr);
	}
	// 返回java plugin数组
	return javaPlugins;
}

extern "C"
JNIEXPORT void JNICALL Java_org_geometerplus_fbreader_formats_PluginCollection_free(JNIEnv* env, jobject thiz) {
	PluginCollection::deleteInstance();
}
