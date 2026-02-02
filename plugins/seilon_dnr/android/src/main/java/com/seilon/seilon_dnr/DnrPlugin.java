// DnrPlugin.java
package com.seilon.seilon_dnr;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class DnrPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private static final String TAG = "DnrPlugin";
  private static final String CHANNEL = "dnr_plugin";
  private static final String EVENT_CHANNEL = "dnr_plugin/progress";

  private MethodChannel channel;
  private EventChannel eventChannel;
  private EventChannel.EventSink eventSink;
  private Context context;
  private DnrManager dnrManager;
  private ExecutorService executorService;
  private Future<?> currentProcessingTask;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
    channel.setMethodCallHandler(this);

    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_CHANNEL);
    eventChannel.setStreamHandler(this);

    dnrManager = new DnrManager();
    executorService = Executors.newSingleThreadExecutor();

    Log.i(TAG, "DNR Plugin attached to engine");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "initialize":
        handleInitialize(call, result);
        break;
      case "isInitialized":
        result.success(dnrManager.isInitialized());
        break;
      case "getVersion":
        handleGetVersion(result);
        break;
      case "getBufferSizes":
        handleGetBufferSizes(result);
        break;
      case "setNoiseReductionLevel":
        handleSetNoiseReductionLevel(call, result);
        break;
      case "processAudioFile":
        handleProcessAudioFile(call, result);
        break;
      case "processAudioData":
        handleProcessAudioData(call, result);
        break;
      case "processPcmFrame":
        handleProcessPcmFrame(call, result);
        break;
      case "processPcmFrames":
        handleProcessPcmFrames(call, result);
        break;
      case "cancelProcessing":
        handleCancelProcessing(result);
        break;
      case "dispose":
        handleDispose(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private void handleInitialize(MethodCall call, Result result) {
    Integer sampleRate = call.argument("sampleRate");
    if (sampleRate == null) {
      result.error("INVALID_ARGUMENT", "Sample rate is required", null);
      return;
    }

    try {
      int status = dnrManager.initialize(sampleRate);
      result.success(status);
    } catch (Exception e) {
      Log.e(TAG, "Failed to initialize DNR", e);
      result.error("INITIALIZATION_FAILED", e.getMessage(), null);
    }
  }

  private void handleGetVersion(Result result) {
    try {
      String version = dnrManager.getVersion();
      result.success(version);
    } catch (Exception e) {
      Log.e(TAG, "Failed to get version", e);
      result.error("GET_VERSION_FAILED", e.getMessage(), null);
    }
  }

  private void handleGetBufferSizes(Result result) {
    try {
      int[] bufferSizes = dnrManager.getBufferSizes();
      List<Integer> bufferSizesList = new ArrayList<>();
      bufferSizesList.add(bufferSizes[0]);
      bufferSizesList.add(bufferSizes[1]);
      result.success(bufferSizesList);
    } catch (Exception e) {
      Log.e(TAG, "Failed to get buffer sizes", e);
      result.error("GET_BUFFER_SIZES_FAILED", e.getMessage(), null);
    }
  }

  private void handleSetNoiseReductionLevel(MethodCall call, Result result) {
    Double dB = call.argument("dB");
    if (dB == null) {
      result.error("INVALID_ARGUMENT", "dB value is required", null);
      return;
    }

    try {
      dnrManager.setNoiseReductionLevel(dB.floatValue());
      result.success(null);
    } catch (Exception e) {
      Log.e(TAG, "Failed to set noise reduction level", e);
      result.error("SET_NOISE_REDUCTION_FAILED", e.getMessage(), null);
    }
  }

  private void handleProcessAudioFile(MethodCall call, Result result) {
    String filePath = call.argument("filePath");

    if (filePath == null) {
      result.error("INVALID_ARGUMENT", "File path is required", null);
      return;
    }

    Log.i(TAG, "Processing file: " + filePath);

    // 取消之前的处理任务
    if (currentProcessingTask != null && !currentProcessingTask.isDone()) {
      currentProcessingTask.cancel(true);
    }

    currentProcessingTask = executorService.submit(() -> {
      try {
        // 智能处理文件路径/URI
        Uri fileUri = parseFileUri(filePath);
        Log.i(TAG, "Parsed URI: " + fileUri.toString());

        // 创建线程安全的回调包装器
        AudioProcessor.ProcessCallback safeCallback = createProcessCallback(result);

        // 调用AudioProcessor处理音频
        AudioProcessor.processAudioFile(context, fileUri, dnrManager, safeCallback);

      } catch (Exception e) {
        Log.e(TAG, "Failed to process audio file", e);
        final String errorMessage = e.getMessage();
        // 异常也通过主线程Handler处理
        new Handler(Looper.getMainLooper()).post(() -> {
          try {
            if (eventSink != null) {
              eventSink.error("PROCESSING_EXCEPTION", errorMessage, null);
            }
            result.error("PROCESSING_FAILED", errorMessage, null);
          } catch (Exception handlerException) {
            Log.e(TAG, "Failed to send exception: " + handlerException.getMessage());
          }
        });
      }
    });
  }

  /**
   * 创建线程安全的处理回调
   */
  private AudioProcessor.ProcessCallback createProcessCallback(Result result) {
    return new AudioProcessor.ProcessCallback() {
      @Override
      public void onProgress(int percentage) {
        // 所有UI更新都通过主线程Handler处理
        new Handler(Looper.getMainLooper()).post(() -> {
          if (eventSink != null) {
            try {
              eventSink.success(percentage);
            } catch (Exception e) {
              Log.w(TAG, "Failed to send progress: " + e.getMessage());
            }
          }
        });
      }

      @Override
      public void onCompleteWithBytes(byte[] audioBytes) {
        // 结果返回也通过主线程Handler处理
        new Handler(Looper.getMainLooper()).post(() -> {
          try {
            if (eventSink != null) {
              eventSink.success(100);
            }
            result.success(audioBytes);
          } catch (Exception e) {
            Log.e(TAG, "Failed to send result: " + e.getMessage());
            result.error("RESULT_FAILED", e.getMessage(), null);
          }
        });
      }

      @Override
      public void onError(String error) {
        // 错误处理也通过主线程Handler处理
        new Handler(Looper.getMainLooper()).post(() -> {
          try {
            if (eventSink != null) {
              eventSink.error("PROCESSING_ERROR", error, null);
            }
            result.error("PROCESSING_FAILED", error, null);
          } catch (Exception e) {
            Log.e(TAG, "Failed to send error: " + e.getMessage());
          }
        });
      }
    };
  }

  /**
   * 智能解析文件路径为Uri
   */
  private Uri parseFileUri(String filePath) {
    if (filePath == null) {
      throw new IllegalArgumentException("File path cannot be null");
    }

    // 如果已经是Uri格式
    if (filePath.startsWith("content://") || filePath.startsWith("file://")) {
      return Uri.parse(filePath);
    }

    // 如果是绝对路径
    if (filePath.startsWith("/")) {
      return Uri.fromFile(new java.io.File(filePath));
    }

    // 默认作为文件路径处理
    return Uri.fromFile(new java.io.File(filePath));
  }

  private void handleProcessAudioData(MethodCall call, Result result) {
    @SuppressWarnings("unchecked")
    List<Integer> audioDataList = call.argument("audioData");

    if (audioDataList == null || audioDataList.size() != 256) {
      result.error("INVALID_ARGUMENT", "Audio data must be 256 samples", null);
      return;
    }

    try {
      // 转换为int数组
      int[] audioData = new int[256];
      for (int i = 0; i < 256; i++) {
        audioData[i] = audioDataList.get(i);
      }

      // 处理音频数据
      int status = dnrManager.processAudio(audioData);

      // 返回结果
      Map<String, Object> resultMap = new HashMap<>();
      resultMap.put("status", status);

      // 将处理后的数据转换回List
      List<Integer> processedDataList = new ArrayList<>();
      for (int value : audioData) {
        processedDataList.add(value);
      }
      resultMap.put("processedData", processedDataList);

      result.success(resultMap);
    } catch (Exception e) {
      Log.e(TAG, "Failed to process audio data", e);
      result.error("PROCESSING_FAILED", e.getMessage(), null);
    }
  }

  /**
   * 处理单个PCM帧（256个16位采样点）
   * Flutter调用：processPcmFrame({pcmData: List<int>})
   */
  private void handleProcessPcmFrame(MethodCall call, Result result) {
    @SuppressWarnings("unchecked")
    List<Integer> pcmDataList = call.argument("pcmData");

    if (pcmDataList == null) {
      result.error("INVALID_ARGUMENT", "PCM data is required", null);
      return;
    }

    if (pcmDataList.size() != 256) {
      result.error("INVALID_ARGUMENT",
              "PCM frame must contain exactly 256 samples, got " + pcmDataList.size(), null);
      return;
    }

    if (!dnrManager.isInitialized()) {
      result.error("NOT_INITIALIZED", "DNR is not initialized", null);
      return;
    }

    try {
      Log.d(TAG, "Processing PCM frame with " + pcmDataList.size() + " samples");

      // 将Flutter传来的List<int> (16位PCM)转换为short[]
      short[] pcmFrame = new short[256];
      for (int i = 0; i < 256; i++) {
        int sample = pcmDataList.get(i);
        // 确保值在16位范围内
        if (sample < -32768) sample = -32768;
        if (sample > 32767) sample = 32767;
        pcmFrame[i] = (short) sample;
      }

      // 转换为Q31格式进行DNR处理
      int[] q31Frame = new int[256];
      for (int i = 0; i < 256; i++) {
        q31Frame[i] = pcmFrame[i] << 16; // 16位PCM转Q31：左移16位
      }

      Log.d(TAG, "Calling DNR processAudio with Q31 frame");

      // DNR处理
      int status = dnrManager.processAudio(q31Frame);

      Log.d(TAG, "DNR processAudio returned status: " + status + " (" +
              DnrManager.DnrStatus.getStatusMessage(status) + ")");

      if (status != DnrManager.DnrStatus.NO_ERROR) {
        // 添加更详细的错误信息
        String detailError = "DNR processing failed with status: " + status +
                " (" + DnrManager.DnrStatus.getStatusMessage(status) + ")";
        Log.e(TAG, detailError);

        // 检查DNR是否真的初始化了
        if (!dnrManager.isInitialized()) {
          result.error("NOT_INITIALIZED", "DNR lost initialization state", null);
        } else {
          result.error("PROCESSING_FAILED", detailError, null);
        }
        return;
      }

      // 转换回16位PCM
      List<Integer> processedPcm = new ArrayList<>(256);
      for (int i = 0; i < 256; i++) {
        short sample = (short) (q31Frame[i] >> 16); // Q31转16位PCM：右移16位
        processedPcm.add((int) sample);
      }

      // 返回处理后的PCM数据
      Map<String, Object> resultMap = new HashMap<>();
      resultMap.put("status", status);
      resultMap.put("processedPcm", processedPcm);

      Log.d(TAG, "PCM frame processing completed successfully");
      result.success(resultMap);

    } catch (Exception e) {
      Log.e(TAG, "Exception in processing PCM frame", e);
      result.error("PROCESSING_FAILED", "Exception: " + e.getMessage(), null);
    }
  }

  /**
   * 批量处理多个PCM帧
   * Flutter调用：processPcmFrames({frames: List<List<int>>})
   */
  private void handleProcessPcmFrames(MethodCall call, Result result) {
    @SuppressWarnings("unchecked")
    List<List<Integer>> framesList = call.argument("frames");

    if (framesList == null || framesList.isEmpty()) {
      result.error("INVALID_ARGUMENT", "Frames list is required and cannot be empty", null);
      return;
    }

    if (!dnrManager.isInitialized()) {
      result.error("NOT_INITIALIZED", "DNR is not initialized", null);
      return;
    }

    // 在后台线程处理多帧数据
    executorService.submit(new ProcessFramesTask(framesList, result));
  }

  /**
   * 批量处理PCM帧的任务类，避免lambda表达式中使用外部变量的问题
   */
  private class ProcessFramesTask implements Runnable {
    private final List<List<Integer>> framesList;
    private final Result result;

    public ProcessFramesTask(List<List<Integer>> framesList, Result result) {
      this.framesList = framesList;
      this.result = result;
    }

    @Override
    public void run() {
      try {
        List<List<Integer>> processedFrames = new ArrayList<>();
        int totalFrames = framesList.size();

        for (int frameIndex = 0; frameIndex < framesList.size(); frameIndex++) {
          List<Integer> frameData = framesList.get(frameIndex);

          if (frameData == null || frameData.size() != 256) {
            final int currentFrameIndex = frameIndex;
            new Handler(Looper.getMainLooper()).post(() -> {
              result.error("INVALID_FRAME",
                      "Frame " + currentFrameIndex + " must contain exactly 256 samples", null);
            });
            return;
          }

          // 处理单帧
          try {
            // 转换为short[]
            short[] pcmFrame = new short[256];
            for (int i = 0; i < 256; i++) {
              int sample = frameData.get(i);
              if (sample < -32768) sample = -32768;
              if (sample > 32767) sample = 32767;
              pcmFrame[i] = (short) sample;
            }

            // 转换为Q31格式
            int[] q31Frame = new int[256];
            for (int i = 0; i < 256; i++) {
              q31Frame[i] = pcmFrame[i] << 16;
            }

            // DNR处理
            int status = dnrManager.processAudio(q31Frame);
            if (status != DnrManager.DnrStatus.NO_ERROR) {
              final String errorMessage = "DNR processing failed at frame " + frameIndex + ": " +
                      DnrManager.DnrStatus.getStatusMessage(status);
              new Handler(Looper.getMainLooper()).post(() -> {
                result.error("PROCESSING_FAILED", errorMessage, null);
              });
              return;
            }

            // 转换回16位PCM
            List<Integer> processedFrame = new ArrayList<>(256);
            for (int i = 0; i < 256; i++) {
              short sample = (short) (q31Frame[i] >> 16);
              processedFrame.add((int) sample);
            }
            processedFrames.add(processedFrame);

            // 发送进度更新
            final int progress = (int) ((frameIndex + 1) * 100.0 / totalFrames);
            new Handler(Looper.getMainLooper()).post(() -> {
              if (eventSink != null) {
                try {
                  eventSink.success(progress);
                } catch (Exception e) {
                  Log.w(TAG, "Failed to send progress: " + e.getMessage());
                }
              }
            });

          } catch (Exception e) {
            Log.e(TAG, "Failed to process frame " + frameIndex, e);
            final String errorMessage = "Failed to process frame " + frameIndex + ": " + e.getMessage();
            new Handler(Looper.getMainLooper()).post(() -> {
              result.error("FRAME_PROCESSING_FAILED", errorMessage, null);
            });
            return;
          }
        }

        // 返回结果
        new Handler(Looper.getMainLooper()).post(() -> {
          Map<String, Object> resultMap = new HashMap<>();
          resultMap.put("status", DnrManager.DnrStatus.NO_ERROR);
          resultMap.put("processedFrames", processedFrames);
          resultMap.put("totalFrames", totalFrames);
          result.success(resultMap);
        });

      } catch (Exception e) {
        Log.e(TAG, "Failed to process PCM frames", e);
        final String errorMessage = e.getMessage();
        new Handler(Looper.getMainLooper()).post(() -> {
          result.error("BATCH_PROCESSING_FAILED", errorMessage, null);
        });
      }
    }
  }

  private void handleCancelProcessing(Result result) {
    if (currentProcessingTask != null && !currentProcessingTask.isDone()) {
      currentProcessingTask.cancel(true);
      result.success(null);
    } else {
      result.success(null);
    }
  }

  private void handleDispose(Result result) {
    try {
      if (currentProcessingTask != null && !currentProcessingTask.isDone()) {
        currentProcessingTask.cancel(true);
      }

      if (executorService != null && !executorService.isShutdown()) {
        executorService.shutdown();
      }

      // DNR Manager会自动清理资源
      result.success(null);
    } catch (Exception e) {
      Log.e(TAG, "Failed to dispose resources", e);
      result.error("DISPOSE_FAILED", e.getMessage(), null);
    }
  }

  // EventChannel.StreamHandler 实现
  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    this.eventSink = events;
    Log.d(TAG, "Progress event listener attached");
  }

  @Override
  public void onCancel(Object arguments) {
    this.eventSink = null;
    Log.d(TAG, "Progress event listener cancelled");
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);

    if (currentProcessingTask != null && !currentProcessingTask.isDone()) {
      currentProcessingTask.cancel(true);
    }

    if (executorService != null && !executorService.isShutdown()) {
      executorService.shutdown();
    }

    Log.i(TAG, "DNR Plugin detached from engine");
  }
}