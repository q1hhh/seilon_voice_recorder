package com.seilon.seilon_dnr;

import android.util.Log;

/**
 * DNR(Dynamic Noise Reduction) 管理器 - 增强版
 * 提供动态噪声降噪功能的Java接口，包含详细的调试信息和状态检查
 */
public class DnrManager {
    private static final String TAG = "DnrManager";

    // 加载native库
    static {
        try {
            System.loadLibrary("dnr-jni");
            Log.i(TAG, "DNR native library loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Failed to load DNR native library", e);
        }
    }

    // DNR状态枚举
    public static class DnrStatus {
        public static final int NO_ERROR = 0;
        public static final int NOT_READY = 1;
        public static final int INVALID_PARAM = 2;
        public static final int INVALID_LICENSE = 3;
        public static final int BUFFER_OVERFLOW = 4;
        public static final int BUFFER_TOO_SMALL = 5;

        public static String getStatusMessage(int status) {
            switch (status) {
                case NO_ERROR:
                    return "No error";
                case NOT_READY:
                    return "Not ready";
                case INVALID_PARAM:
                    return "Invalid parameter";
                case INVALID_LICENSE:
                    return "Invalid license";
                case BUFFER_OVERFLOW:
                    return "Buffer overflow";
                case BUFFER_TOO_SMALL:
                    return "Buffer too small";
                default:
                    return "Unknown error (" + status + ")";
            }
        }
    }

    private boolean isInitialized = false;
    private int lastSampleRate = -1;
    private int processedFrameCount = 0;

    /**
     * 初始化DNR
     * @param sampleRate 采样率（通常为16000）
     * @return DNR状态码
     */
    public int initialize(int sampleRate) {
        Log.i(TAG, "Initializing DNR with sample rate: " + sampleRate);

        // 参数验证
        if (sampleRate <= 0) {
            Log.e(TAG, "Invalid sample rate: " + sampleRate);
            return DnrStatus.INVALID_PARAM;
        }

        // 重置状态
        isInitialized = false;
        processedFrameCount = 0;

        try {
            int result = initDNR(sampleRate);
            Log.i(TAG, "Native initDNR returned: " + result + " (" +
                    DnrStatus.getStatusMessage(result) + ")");

            if (result == DnrStatus.NO_ERROR) {
                isInitialized = true;
                lastSampleRate = sampleRate;
                Log.i(TAG, "DNR initialized successfully");

                // 获取并打印缓冲区信息
                try {
                    int[] bufferSizes = getBufferSizes();
                    Log.i(TAG, "DNR buffer sizes: [" + bufferSizes[0] + ", " + bufferSizes[1] + "]");
                } catch (Exception e) {
                    Log.w(TAG, "Could not get buffer sizes: " + e.getMessage());
                }

                // 获取并打印版本信息
                try {
                    String version = getVersion();
                    Log.i(TAG, "DNR version: " + version);
                } catch (Exception e) {
                    Log.w(TAG, "Could not get version: " + e.getMessage());
                }

            } else {
                Log.e(TAG, "DNR initialization failed: " + DnrStatus.getStatusMessage(result));
            }

            return result;
        } catch (Exception e) {
            Log.e(TAG, "Exception during DNR initialization", e);
            return DnrStatus.NOT_READY;
        }
    }

    /**
     * 处理音频数据进行降噪
     * @param audioData Q31格式的音频数据，长度必须为256个样本点
     * @return DNR状态码
     */
    public int processAudio(int[] audioData) {
        if (!isInitialized) {
            Log.e(TAG, "DNR not initialized - cannot process audio");
            return DnrStatus.NOT_READY;
        }

        if (audioData == null) {
            Log.e(TAG, "Audio data is null");
            return DnrStatus.INVALID_PARAM;
        }

        if (audioData.length != 256) {
            Log.e(TAG, "Invalid audio data length: expected 256 samples, got " + audioData.length);
            return DnrStatus.INVALID_PARAM;
        }

        // 检查数据有效性（Q31格式的范围检查）
        boolean hasValidData = false;
        int minValue = Integer.MAX_VALUE;
        int maxValue = Integer.MIN_VALUE;

        for (int i = 0; i < audioData.length; i++) {
            int sample = audioData[i];
            if (sample != 0) {
                hasValidData = true;
            }
            minValue = Math.min(minValue, sample);
            maxValue = Math.max(maxValue, sample);
        }

        if (!hasValidData) {
            Log.w(TAG, "Audio data contains all zeros");
        }

        Log.d(TAG, "Processing audio frame " + processedFrameCount +
                ", data range: [" + minValue + ", " + maxValue + "], hasValidData: " + hasValidData);

        try {
            int result = processDNR(audioData);

            if (result == DnrStatus.NO_ERROR) {
                processedFrameCount++;

                // 每100帧打印一次统计信息
                if (processedFrameCount % 100 == 0) {
                    Log.d(TAG, "Successfully processed " + processedFrameCount + " frames");
                }
            } else {
                Log.e(TAG, "DNR processing failed for frame " + processedFrameCount +
                        ": " + DnrStatus.getStatusMessage(result));

                // 检查是否需要重新初始化
                if (result == DnrStatus.NOT_READY) {
                    Log.w(TAG, "DNR appears to have lost initialization, marking as uninitialized");
                    isInitialized = false;
                }
            }

            return result;
        } catch (Exception e) {
            Log.e(TAG, "Exception during DNR processing", e);
            return DnrStatus.NOT_READY;
        }
    }

    /**
     * 获取DNR版本信息
     * @return 版本字符串
     */
    public String getVersion() {
        try {
            String version = getDNRVersion();
            Log.d(TAG, "Retrieved DNR version: " + version);
            return version;
        } catch (Exception e) {
            Log.e(TAG, "Failed to get DNR version", e);
            return "Unknown";
        }
    }

    /**
     * 获取DNR缓冲区大小信息
     * @return 包含两个元素的数组：[buffer1_size, buffer2_size]
     */
    public int[] getBufferSizes() {
        try {
            int[] sizes = getBufferSizesNative();
            Log.d(TAG, "Retrieved buffer sizes: [" + sizes[0] + ", " + sizes[1] + "]");
            return sizes;
        } catch (Exception e) {
            Log.e(TAG, "Failed to get buffer sizes", e);
            return new int[]{0, 0};
        }
    }

    /**
     * 设置降噪深度
     * @param dB 降噪深度，范围 -200 到 0 dB
     *           -200: 最大降噪
     *           0: 无降噪
     */
    public void setNoiseReductionLevel(float dB) {
        if (dB < -200.0f || dB > 0.0f) {
            Log.w(TAG, "dB value should be between -200 and 0, got: " + dB +
                    ", clamping to valid range");
            dB = Math.max(-200.0f, Math.min(0.0f, dB));
        }

        try {
            setNoisyMixFactor(dB);
            Log.i(TAG, "Noise reduction level set to: " + dB + " dB");
        } catch (Exception e) {
            Log.e(TAG, "Failed to set noise reduction level", e);
        }
    }

    /**
     * 检查DNR是否已初始化
     * @return true如果已初始化
     */
    public boolean isInitialized() {
        return isInitialized;
    }

    /**
     * 获取最后使用的采样率
     * @return 采样率，如果未初始化则返回-1
     */
    public int getLastSampleRate() {
        return lastSampleRate;
    }

    /**
     * 获取已处理的帧数统计
     * @return 已处理的帧数
     */
    public int getProcessedFrameCount() {
        return processedFrameCount;
    }

    /**
     * 重置统计信息
     */
    public void resetStats() {
        processedFrameCount = 0;
        Log.d(TAG, "Statistics reset");
    }

    /**
     * 获取详细的状态信息
     * @return 状态信息字符串
     */
    public String getStatusInfo() {
        StringBuilder sb = new StringBuilder();
        sb.append("DNR Status:\n");
        sb.append("  Initialized: ").append(isInitialized).append("\n");
        sb.append("  Sample Rate: ").append(lastSampleRate).append("\n");
        sb.append("  Processed Frames: ").append(processedFrameCount).append("\n");

        if (isInitialized) {
            try {
                sb.append("  Version: ").append(getVersion()).append("\n");
                int[] bufferSizes = getBufferSizes();
                sb.append("  Buffer Sizes: [").append(bufferSizes[0])
                        .append(", ").append(bufferSizes[1]).append("]\n");
            } catch (Exception e) {
                sb.append("  Error getting native info: ").append(e.getMessage()).append("\n");
            }
        }

        return sb.toString();
    }

    // Native方法声明
    private native int initDNR(int sampleRate);
    private native int processDNR(int[] audioData);
    private native String getDNRVersion();
    private native int[] getBufferSizesNative();
    private native void setNoisyMixFactor(float dB);
}