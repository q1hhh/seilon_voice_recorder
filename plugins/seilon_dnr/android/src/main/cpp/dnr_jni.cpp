#include <jni.h>
#include <android/log.h>
#include <cstring>

// DNR库的C接口声明
extern "C" {
#include "azp_dnr.h"
}

#define LOG_TAG "DNR_JNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// 全局变量存储DNR状态
static bool dnr_initialized = false;
static int8_t buffer1[21888] __attribute__((aligned(4)));
static int8_t buffer2[15728] __attribute__((aligned(4)));

extern "C"
JNIEXPORT jint JNICALL
Java_com_seilon_seilon_1dnr_DnrManager_initDNR(JNIEnv *env, jobject thiz, jint sample_rate) {
    LOGI("=== JNI initDNR called ===");
    LOGI("Initializing DNR with sample rate: %d", sample_rate);

    azp_dnr_pram_t pram = {
            .buffer1 = buffer1,
            .buffer2 = buffer2,
            .buffer1_size = sizeof(buffer1),
            .buffer2_size = sizeof(buffer2),
            .sample_rate = sample_rate
    };

    AZP_STATUS status = AI_DNR_init(&pram);

    if (status == errAZP_NoError) {
        dnr_initialized = true;
        LOGI("DNR initialized successfully");
    } else {
        dnr_initialized = false;
        LOGE("DNR initialization failed with status: %d", status);
    }

    return static_cast<jint>(status);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_seilon_seilon_1dnr_DnrManager_processDNR(JNIEnv *env, jobject thiz, jintArray audio_data) {
    if (!dnr_initialized) {
        LOGE("DNR not initialized");
        return errAZP_NotReady;
    }

    // 获取Java数组
    jint *audio = env->GetIntArrayElements(audio_data, nullptr);
    if (audio == nullptr) {
        LOGE("Failed to get array elements");
        return errAZP_InvalidParam;
    }

    jsize length = env->GetArrayLength(audio_data);
    LOGI("Processing DNR with %d samples", length);

    // 检查数据长度（应该是256个样本）
    if (length != 256) {
        LOGE("Invalid audio data length: %d, expected 256", length);
        env->ReleaseIntArrayElements(audio_data, audio, JNI_ABORT);
        return errAZP_InvalidParam;
    }

    // 处理音频数据
    AZP_STATUS status = AI_DNR_Processing(reinterpret_cast<int32_t*>(audio));

    // 释放数组（0表示将修改写回Java数组）
    env->ReleaseIntArrayElements(audio_data, audio, 0);

    if (status != errAZP_NoError) {
        LOGE("DNR processing failed with status: %d", status);
    } else {
        LOGI("DNR processing completed successfully");
    }

    return static_cast<jint>(status);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_seilon_seilon_1dnr_DnrManager_getDNRVersion(JNIEnv *env, jobject thiz) {
    LOGI("=== JNI getDNRVersion called ===");

    char *version = AI_DNR_Version();
    if (version != nullptr) {
        LOGI("DNR Version: %s", version);
        return env->NewStringUTF(version);
    }

    LOGI("DNR Version: Unknown (null returned)");
    return env->NewStringUTF("Unknown");
}

extern "C"
JNIEXPORT jintArray JNICALL
Java_com_seilon_seilon_1dnr_DnrManager_getBufferSizesNative(JNIEnv *env, jobject thiz) {
    LOGI("=== JNI getBufferSizesNative called ===");

    int32_t buf_size1, buf_size2;
    getBufferSize(&buf_size1, &buf_size2);

    LOGI("Buffer sizes: %d, %d", buf_size1, buf_size2);

    jintArray result = env->NewIntArray(2);
    if (result == nullptr) {
        LOGE("Failed to create int array");
        return nullptr;
    }

    jint sizes[2] = {buf_size1, buf_size2};
    env->SetIntArrayRegion(result, 0, 2, sizes);

    return result;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_seilon_seilon_1dnr_DnrManager_setNoisyMixFactor(JNIEnv *env, jobject thiz, jfloat db) {
LOGI("=== JNI setNoisyMixFactor called ===");
LOGI("Setting noisy mix factor to: %.2f dB", db);

setNoisy_mix_factor(static_cast<float>(db));

LOGI("Noisy mix factor set successfully");
}

// 添加一个测试方法来验证JNI是否正常工作
extern "C"
JNIEXPORT jstring JNICALL
        Java_com_seilon_seilon_1dnr_DnrManager_testJNI(JNIEnv *env, jobject thiz) {
LOGI("=== JNI testJNI called - JNI is working! ===");
return env->NewStringUTF("JNI Connection Success!");
}