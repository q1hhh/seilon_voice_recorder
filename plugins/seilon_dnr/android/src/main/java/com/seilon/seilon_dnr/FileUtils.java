package com.seilon.seilon_dnr;

import android.content.ContentValues;
import android.content.Context;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * 文件工具类
 * 处理音频文件的保存和访问
 */
public class FileUtils {
    private static final String TAG = "FileUtils";

    /**
     * 保存音频数据到Downloads目录
     * @param context 上下文
     * @param audioData 16位PCM音频数据
     * @param fileName 文件名
     * @return 保存的文件路径，失败返回null
     */
    public static String saveAudioToDownloads(Context context, short[] audioData, String fileName) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ 使用MediaStore API
                return saveAudioUsingMediaStore(context, audioData, fileName);
            } else {
                // Android 9及以下直接写入Downloads目录
                return saveAudioToFile(audioData, fileName);
            }
        } catch (Exception e) {
            Log.e(TAG, "保存音频文件失败", e);
            return null;
        }
    }

    /**
     * 使用MediaStore API保存音频文件 (Android 10+)
     */
    private static String saveAudioUsingMediaStore(Context context, short[] audioData, String fileName) {
        try {
            // 创建WAV文件数据
            byte[] wavData = createWavFile(audioData);

            ContentValues values = new ContentValues();
            values.put(MediaStore.Audio.Media.DISPLAY_NAME, fileName);
            values.put(MediaStore.Audio.Media.MIME_TYPE, "audio/wav");
            values.put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
            values.put(MediaStore.Audio.Media.IS_PENDING, 1);

            Uri uri = context.getContentResolver().insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                Log.e(TAG, "无法创建MediaStore条目");
                return null;
            }

            // 写入文件数据
            try (OutputStream out = context.getContentResolver().openOutputStream(uri)) {
                if (out == null) {
                    Log.e(TAG, "无法获取输出流");
                    return null;
                }
                out.write(wavData);
            }

            // 完成写入
            values.clear();
            values.put(MediaStore.Audio.Media.IS_PENDING, 0);
            context.getContentResolver().update(uri, values, null, null);

            // 获取实际文件路径
            String realPath = getRealPathFromUri(context, uri);
            Log.i(TAG, "使用MediaStore保存文件成功: " + realPath);
            return realPath != null ? realPath : uri.toString();

        } catch (Exception e) {
            Log.e(TAG, "使用MediaStore保存文件失败", e);
            return null;
        }
    }

    /**
     * 直接保存到Downloads目录 (Android 9及以下)
     */
    private static String saveAudioToFile(short[] audioData, String fileName) {
        try {
            File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs();
            }

            File outputFile = new File(downloadsDir, fileName);

            // 创建WAV文件数据
            byte[] wavData = createWavFile(audioData);

            // 写入文件
            try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                fos.write(wavData);
            }

            Log.i(TAG, "直接保存文件成功: " + outputFile.getAbsolutePath());
            return outputFile.getAbsolutePath();

        } catch (Exception e) {
            Log.e(TAG, "直接保存文件失败", e);
            return null;
        }
    }

    /**
     * 创建WAV文件数据
     * @param audioData 16位PCM音频数据
     * @return WAV格式的字节数组
     */
    private static byte[] createWavFile(short[] audioData) {
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
     * 从Uri获取真实文件路径
     */
    private static String getRealPathFromUri(Context context, Uri uri) {
        try {
            String[] projection = {MediaStore.Audio.Media.DATA};
            try (android.database.Cursor cursor = context.getContentResolver().query(uri, projection, null, null, null)) {
                if (cursor != null && cursor.moveToFirst()) {
                    int columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA);
                    return cursor.getString(columnIndex);
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "无法获取真实路径", e);
        }
        return null;
    }

    /**
     * 刷新媒体库，让文件可以在文件管理器中看到
     */
    public static void refreshMediaLibrary(Context context, String filePath) {
        try {
            MediaScannerConnection.scanFile(context, new String[]{filePath}, null, null);
            Log.i(TAG, "已刷新媒体库: " + filePath);
        } catch (Exception e) {
            Log.w(TAG, "刷新媒体库失败", e);
        }
    }
}