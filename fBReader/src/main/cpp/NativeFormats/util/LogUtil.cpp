//
// Created by FengCheng Ding on 1/10/22.
//

#include "LogUtil.h"
#include <sstream>
#include <android/log.h>
#include <string>

//template<typename T>
//std::string LogUtil::toString(T value) {
//    std::ostringstream os;
//    os << value;
//    return os.str();
//}

void LogUtil::print(const std::string &message, const std::string &value) {
    __android_log_print(ANDROID_LOG_INFO, "cpp解析打印", message.c_str(), value.c_str());
}

