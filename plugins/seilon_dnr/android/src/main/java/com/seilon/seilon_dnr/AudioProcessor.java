package com.seilon.seilon_dnr;

import android.content.Context;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaCodec;
import android.media.MediaMuxer;
import android.net.Uri;
import android.util.Log;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * 音频处理工具类
 * 支持音频文件解码、格式转换、DNR处理和保存
 * 新增PCM帧处理优化功能
 */
public class AudioProcessor {
    private static final String TAG = "AudioProcessor";

    // DNR要求的格式
    private static final int TARGET_SAMPLE_RATE = 16000;
    private static final int FRAME_SIZE = 256;
    private static final int BYTES_PER_SAMPLE = 2; // 16位PCM

    public interface ProcessCallback {
        void onProgress(int percentage);
        void onCompleteWithBytes(byte[] audioBytes);
        void onError(String error);
    }

    public interface ProgressCallback {
        void onProgress(int percentage);
    }

    /**
     * PCM帧处理结果回调
     */
    public interface PcmFrameCallback {
        void onFrameProcessed(short[] originalFrame, short[] processedFrame, int frameIndex);
        void onProgress(int processedFrames, int totalFrames);
        void onComplete(short[] allProcessedData);
        void onError(String error);
    }

    /**
     * 处理音频文件
     */
    public static void processAudioFile(Context context, Uri inputUri,
                                        DnrManager dnrManager, ProcessCallback callback) {
        new Thread(() -> {
            try {
                Log.i(TAG, "开始处理音频文件: " + inputUri.toString());

                // 1. 解码音频文件
                callback.onProgress(10);
                short[] audioData = decodeAudioFile(context, inputUri);
                if (audioData == null) {
                    callback.onError("无法解码音频文件");
                    return;
                }

                Log.i(TAG, "解码完成，样本数: " + audioData.length);

                // 2. 重采样到16KHz（如果需要）
                callback.onProgress(20);
                short[] resampledData = resampleTo16kHz(audioData);
                Log.i(TAG, "重采样完成，样本数: " + resampledData.length);

                // 3. DNR处理
                callback.onProgress(30);
                short[] processedData = processDNR(resampledData, dnrManager,
                        new ProgressCallback() {
                            @Override
                            public void onProgress(int percentage) {
                                callback.onProgress(30 + (int)(percentage * 0.65));
                            }
                        });

                if (processedData == null) {
                    callback.onError("DNR处理失败");
                    return;
                }

                // 4. 转换为WAV格式的byte[]并返回
                callback.onProgress(95);
                byte[] wavBytes = createWavBytes(processedData);

                Log.i(TAG, "音频处理完成，WAV数据大小: " + wavBytes.length + " 字节");

                callback.onProgress(100);
                callback.onCompleteWithBytes(wavBytes);

            } catch (Exception e) {
                Log.e(TAG, "处理音频文件失败", e);
                callback.onError("处理失败: " + e.getMessage());
            }
        }).start();
    }

    /**
     * 批量处理PCM帧（新增功能）
     * @param pcmFrames PCM帧数组，每个帧包含256个样本
     * @param dnrManager DNR管理器
     * @param callback 处理回调
     */
    public static void processPcmFrames(short[][] pcmFrames, DnrManager dnrManager,
                                        PcmFrameCallback callback) {
        new Thread(() -> {
            try {
                if (!dnrManager.isInitialized()) {
                    callback.onError("DNR未初始化");
                    return;
                }

                if (pcmFrames == null || pcmFrames.length == 0) {
                    callback.onError("PCM帧数据为空");
                    return;
                }

                Log.i(TAG, "开始批量处理PCM帧，总帧数: " + pcmFrames.length);

                short[][] processedFrames = new short[pcmFrames.length][FRAME_SIZE];
                int totalSamples = pcmFrames.length * FRAME_SIZE;
                short[] allProcessedData = new short[totalSamples];

                for (int frameIndex = 0; frameIndex < pcmFrames.length; frameIndex++) {
                    short[] originalFrame = pcmFrames[frameIndex];

                    // 验证帧大小
                    if (originalFrame.length != FRAME_SIZE) {
                        callback.onError("帧 " + frameIndex + " 大小不正确，期望 " + FRAME_SIZE +
                                "，实际 " + originalFrame.length);
                        return;
                    }

                    // 处理单个帧
                    short[] processedFrame = processSingleFrame(originalFrame, dnrManager);
                    if (processedFrame == null) {
                        callback.onError("处理帧 " + frameIndex + " 失败");
                        return;
                    }

                    processedFrames[frameIndex] = processedFrame;

                    // 复制到总数据数组
                    System.arraycopy(processedFrame, 0, allProcessedData,
                            frameIndex * FRAME_SIZE, FRAME_SIZE);

                    // 回调单帧处理完成
                    callback.onFrameProcessed(originalFrame, processedFrame, frameIndex);

                    // 回调进度
                    callback.onProgress(frameIndex + 1, pcmFrames.length);
                }

                Log.i(TAG, "批量PCM帧处理完成");
                callback.onComplete(allProcessedData);

            } catch (Exception e) {
                Log.e(TAG, "批量处理PCM帧失败", e);
                callback.onError("批量处理失败: " + e.getMessage());
            }
        }).start();
    }

    /**
     * 处理单个PCM帧（同步方法）
     * @param pcmFrame 包含256个样本的PCM帧
     * @param dnrManager DNR管理器
     * @return 处理后的PCM帧，失败返回null
     */
    public static short[] processSingleFrame(short[] pcmFrame, DnrManager dnrManager) {
        if (!dnrManager.isInitialized()) {
            Log.e(TAG, "DNR未初始化");
            return null;
        }

        if (pcmFrame == null || pcmFrame.length != FRAME_SIZE) {
            Log.e(TAG, "PCM帧大小不正确，期望 " + FRAME_SIZE +
                    "，实际 " + (pcmFrame != null ? pcmFrame.length : 0));
            return null;
        }

        try {
            // 转换为Q31格式
            int[] q31Frame = new int[FRAME_SIZE];
            for (int i = 0; i < FRAME_SIZE; i++) {
                q31Frame[i] = pcmFrame[i] << 16; // 16位PCM转Q31：左移16位
            }

            // DNR处理
            int result = dnrManager.processAudio(q31Frame);
            if (result != DnrManager.DnrStatus.NO_ERROR) {
                Log.e(TAG, "DNR处理失败，错误: " + DnrManager.DnrStatus.getStatusMessage(result));
                return null;
            }

            // 转换回16位PCM
            short[] processedFrame = new short[FRAME_SIZE];
            for (int i = 0; i < FRAME_SIZE; i++) {
                processedFrame[i] = (short)(q31Frame[i] >> 16); // Q31转16位PCM：右移16位
            }

            return processedFrame;

        } catch (Exception e) {
            Log.e(TAG, "处理PCM帧异常", e);
            return null;
        }
    }

    /**
     * 实时PCM流处理器
     */
    public static class RealtimeProcessor {
        private final DnrManager dnrManager;
        private final Object processLock = new Object();
        private volatile boolean isProcessing = false;

        public RealtimeProcessor(DnrManager dnrManager) {
            this.dnrManager = dnrManager;
        }

        /**
         * 开始实时处理
         */
        public void startProcessing() {
            synchronized (processLock) {
                isProcessing = true;
            }
        }

        /**
         * 停止实时处理
         */
        public void stopProcessing() {
            synchronized (processLock) {
                isProcessing = false;
            }
        }

        /**
         * 处理实时PCM帧
         * @param inputFrame 输入PCM帧
         * @return 处理后的PCM帧，如果处理失败或已停止返回null
         */
        public short[] processFrame(short[] inputFrame) {
            synchronized (processLock) {
                if (!isProcessing) {
                    return null;
                }
            }

            return processSingleFrame(inputFrame, dnrManager);
        }

        /**
         * 检查是否正在处理
         */
        public boolean isProcessing() {
            synchronized (processLock) {
                return isProcessing;
            }
        }
    }

    /**
     * PCM数据转换工具
     */
    public static class PcmConverter {

        /**
         * 将字节数组转换为short数组（16位PCM，小端序）
         */
        public static short[] bytesToShortArray(byte[] bytes) {
            if (bytes.length % 2 != 0) {
                throw new IllegalArgumentException("字节数组长度必须为偶数");
            }

            short[] shortArray = new short[bytes.length / 2];
            ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(shortArray);
            return shortArray;
        }

        /**
         * 将short数组转换为字节数组（16位PCM，小端序）
         */
        public static byte[] shortArrayToBytes(short[] shortArray) {
            byte[] bytes = new byte[shortArray.length * 2];
            ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().put(shortArray);
            return bytes;
        }

        /**
         * 将PCM数据分割为指定大小的帧
         */
        public static short[][] splitIntoFrames(short[] pcmData, int frameSize) {
            int numFrames = (int) Math.ceil((double) pcmData.length / frameSize);
            short[][] frames = new short[numFrames][frameSize];

            for (int i = 0; i < numFrames; i++) {
                int startIndex = i * frameSize;
                int endIndex = Math.min(startIndex + frameSize, pcmData.length);

                // 复制数据到帧
                System.arraycopy(pcmData, startIndex, frames[i], 0, endIndex - startIndex);

                // 如果最后一帧不足，用0填充
                if (endIndex - startIndex < frameSize) {
                    for (int j = endIndex - startIndex; j < frameSize; j++) {
                        frames[i][j] = 0;
                    }
                }
            }

            return frames;
        }

        /**
         * 将帧合并为完整的PCM数据
         */
        public static short[] mergeFrames(short[][] frames, int originalLength) {
            int totalLength = Math.min(frames.length * frames[0].length, originalLength);
            short[] merged = new short[totalLength];

            int destIndex = 0;
            for (int i = 0; i < frames.length && destIndex < totalLength; i++) {
                int copyLength = Math.min(frames[i].length, totalLength - destIndex);
                System.arraycopy(frames[i], 0, merged, destIndex, copyLength);
                destIndex += copyLength;
            }

            return merged;
        }

        /**
         * 计算PCM数据的RMS值
         */
        public static double calculateRMS(short[] pcmData) {
            if (pcmData.length == 0) return 0.0;

            long sum = 0;
            for (short sample : pcmData) {
                sum += (long) sample * sample;
            }

            return Math.sqrt((double) sum / pcmData.length);
        }

        /**
         * 检测静音
         */
        public static boolean isSilent(short[] pcmData, double threshold) {
            double rms = calculateRMS(pcmData);
            return rms < threshold;
        }
    }

    /**
     * 创建WAV格式的字节数据
     */
    private static byte[] createWavBytes(short[] audioData) {
        int sampleRate = 16000;
        int channels = 1;
        int bitsPerSample = 16;

        int dataLength = audioData.length * 2; // 每个样本2字节
        int fileLength = dataLength + 36;

        ByteBuffer buffer = ByteBuffer.allocate(fileLength + 8);
        buffer.order(ByteOrder.LITTLE_ENDIAN);

        // WAV文件头
        buffer.put("RIFF".getBytes()); // ChunkID
        buffer.putInt(fileLength); // ChunkSize
        buffer.put("WAVE".getBytes()); // Format

        // fmt subchunk
        buffer.put("fmt ".getBytes()); // Subchunk1ID
        buffer.putInt(16); // Subchunk1Size (PCM)
        buffer.putShort((short) 1); // AudioFormat (PCM)
        buffer.putShort((short) channels); // NumChannels
        buffer.putInt(sampleRate); // SampleRate
        buffer.putInt(sampleRate * channels * bitsPerSample / 8); // ByteRate
        buffer.putShort((short) (channels * bitsPerSample / 8)); // BlockAlign
        buffer.putShort((short) bitsPerSample); // BitsPerSample

        // data subchunk
        buffer.put("data".getBytes()); // Subchunk2ID
        buffer.putInt(dataLength); // Subchunk2Size

        // 音频数据
        for (short sample : audioData) {
            buffer.putShort(sample);
        }

        return buffer.array();
    }

    /**
     * 解码音频文件（支持WAV格式）
     * 修复文件路径处理问题
     */
    private static short[] decodeAudioFile(Context context, Uri uri) {
        try {
            Log.i(TAG, "解码文件: " + uri.toString());

            FileInputStream fis = null;

            // 判断URI类型并获取输入流
            if ("content".equals(uri.getScheme())) {
                // Content URI - 使用ContentResolver
                fis = (FileInputStream) context.getContentResolver().openInputStream(uri);
            } else if ("file".equals(uri.getScheme()) || uri.getScheme() == null) {
                // 文件路径 - 直接打开文件
                String filePath = uri.getPath();
                if (filePath == null) {
                    filePath = uri.toString();
                }

                // 如果路径不是以 / 开头，可能需要添加
                File file = new File(filePath);
                if (!file.exists()) {
                    Log.e(TAG, "文件不存在: " + filePath);
                    return null;
                }

                fis = new FileInputStream(file);
                Log.i(TAG, "成功打开文件: " + filePath);
            } else {
                Log.e(TAG, "不支持的URI方案: " + uri.getScheme());
                return null;
            }

            if (fis == null) {
                Log.e(TAG, "无法获取文件输入流");
                return null;
            }

            // 简单的WAV文件解析
            byte[] header = new byte[44];
            int headerBytesRead = fis.read(header);
            if (headerBytesRead != 44) {
                Log.e(TAG, "无法读取WAV头信息，只读取了 " + headerBytesRead + " 字节");
                fis.close();
                return null;
            }

            // 检查是否为WAV文件
            String chunkId = new String(header, 0, 4);
            String format = new String(header, 8, 4);

            if (!"RIFF".equals(chunkId) || !"WAVE".equals(format)) {
                Log.e(TAG, "不是有效的WAV文件，ChunkId: " + chunkId + ", Format: " + format);
                fis.close();
                return null;
            }

            // 解析WAV头信息
            int sampleRate = ByteBuffer.wrap(header, 24, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
            short channels = ByteBuffer.wrap(header, 22, 2).order(ByteOrder.LITTLE_ENDIAN).getShort();
            short bitsPerSample = ByteBuffer.wrap(header, 34, 2).order(ByteOrder.LITTLE_ENDIAN).getShort();

            Log.i(TAG, "WAV信息 - 采样率: " + sampleRate + ", 声道: " + channels + ", 位深: " + bitsPerSample);

            // 读取音频数据
            int dataSize = fis.available();
            Log.i(TAG, "音频数据大小: " + dataSize + " 字节");

            byte[] audioBytes = new byte[dataSize];
            int totalBytesRead = 0;
            int bytesRead;
            while (totalBytesRead < dataSize && (bytesRead = fis.read(audioBytes, totalBytesRead, dataSize - totalBytesRead)) != -1) {
                totalBytesRead += bytesRead;
            }
            fis.close();

            Log.i(TAG, "实际读取音频数据: " + totalBytesRead + " 字节");

            // 转换为16位PCM数据
            short[] audioData;
            if (bitsPerSample == 16) {
                audioData = new short[totalBytesRead / 2];
                ByteBuffer.wrap(audioBytes, 0, totalBytesRead).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(audioData);
            } else if (bitsPerSample == 8) {
                // 8位转16位
                audioData = new short[totalBytesRead];
                for (int i = 0; i < totalBytesRead; i++) {
                    audioData[i] = (short)((audioBytes[i] & 0xFF - 128) << 8);
                }
            } else {
                Log.e(TAG, "不支持的位深: " + bitsPerSample);
                return null;
            }

            // 如果是立体声，混合为单声道
            if (channels == 2) {
                short[] monoData = new short[audioData.length / 2];
                for (int i = 0; i < monoData.length; i++) {
                    monoData[i] = (short)((audioData[i * 2] + audioData[i * 2 + 1]) / 2);
                }
                audioData = monoData;
                Log.i(TAG, "立体声转换为单声道，最终样本数: " + audioData.length);
            }

            return audioData;

        } catch (Exception e) {
            Log.e(TAG, "解码音频文件失败", e);
            return null;
        }
    }

    /**
     * 重采样到16KHz（简单线性插值）
     */
    private static short[] resampleTo16kHz(short[] audioData) {
        // 假设原始采样率，这里需要从文件头读取
        // 为简化，假设输入已经是16KHz或进行简单处理
        return audioData;
    }

    /**
     * 使用DNR处理音频数据
     */
    private static short[] processDNR(short[] audioData, DnrManager dnrManager, ProgressCallback progressCallback) {
        if (!dnrManager.isInitialized()) {
            Log.e(TAG, "DNR未初始化");
            return null;
        }

        int totalFrames = audioData.length / FRAME_SIZE;
        short[] processedData = new short[audioData.length];

        Log.i(TAG, "开始DNR处理，总帧数: " + totalFrames);

        for (int frameIndex = 0; frameIndex < totalFrames; frameIndex++) {
            int startIndex = frameIndex * FRAME_SIZE;

            // 转换为Q31格式
            int[] q31Frame = new int[FRAME_SIZE];
            for (int i = 0; i < FRAME_SIZE; i++) {
                if (startIndex + i < audioData.length) {
                    // 16位PCM转Q31：左移16位
                    q31Frame[i] = audioData[startIndex + i] << 16;
                }
            }

            // DNR处理
            int result = dnrManager.processAudio(q31Frame);
            if (result != DnrManager.DnrStatus.NO_ERROR) {
                Log.e(TAG, "DNR处理失败，帧: " + frameIndex + ", 错误: " +
                        DnrManager.DnrStatus.getStatusMessage(result));
                return null;
            }

            // 转换回16位PCM
            for (int i = 0; i < FRAME_SIZE; i++) {
                if (startIndex + i < processedData.length) {
                    // Q31转16位PCM：右移16位
                    processedData[startIndex + i] = (short)(q31Frame[i] >> 16);
                }
            }

            // 更新进度
            if (progressCallback != null && frameIndex % 100 == 0) {
                double progress = (double)frameIndex / totalFrames;
                progressCallback.onProgress((int)(progress * 100));
            }
        }

        Log.i(TAG, "DNR处理完成");
        return processedData;
    }
}