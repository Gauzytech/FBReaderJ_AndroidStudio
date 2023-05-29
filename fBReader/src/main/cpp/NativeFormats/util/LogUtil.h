//
// Created by FengCheng Ding on 1/10/22.
//

#ifndef FBREADERJ_ANDROIDSTUDIO_LOGUTIL_H
#define FBREADERJ_ANDROIDSTUDIO_LOGUTIL_H


#include <string>
#include <xmlwf/xmltchar.h>

class LogUtil {

public:

//    template <typename T>
//    static std::string toString(T value);

    static void print(const std::string &message, const std::string &value);

    static void print(const std::string &tag, const std::string &message, const std::string &value);

    static void LOGI(const char* tag, const std::string &message, const std::string &value);
};


#endif //FBREADERJ_ANDROIDSTUDIO_LOGUTIL_H
