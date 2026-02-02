# android/src/main/cpp/CMakeLists.txt
cmake_minimum_required(VERSION 3.22.1)

# 设置项目名称
project("dnr")

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)

# 查找所需的库
find_library(log-lib log)
find_library(android-lib android)

# 设置头文件目录
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# 创建JNI库
add_library(
        dnr-jni
        SHARED
        dnr_jni.cpp
)

# 导入预编译的DNR库
add_library(dnr SHARED IMPORTED)

# 根据不同架构设置库路径
set_target_properties(dnr PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libdnr.so)

# 链接库
target_link_libraries(
        dnr-jni
        dnr
        ${log-lib}
        ${android-lib}
)

# 设置编译选项
target_compile_options(dnr-jni PRIVATE
        -Wall
        -Wextra
        -O2
        )