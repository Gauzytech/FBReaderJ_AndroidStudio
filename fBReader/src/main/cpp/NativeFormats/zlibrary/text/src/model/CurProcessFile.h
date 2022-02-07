//
// Created by FengCheng Ding on 2/6/22.
//

#ifndef FBREADERJ_ANDROIDSTUDIO_CURPROCESSFILE_H
#define FBREADERJ_ANDROIDSTUDIO_CURPROCESSFILE_H

#include <vector>

#include <ZLUnicodeUtil.h>

struct CurProcessFile {
    std::string fileName;
    int cacheFileCount;

    void clear() {
        fileName.clear();
        cacheFileCount = -1;
    }

    bool valid() {
        return fileName.empty();
    }
};

#endif //FBREADERJ_ANDROIDSTUDIO_CURPROCESSFILE_H
