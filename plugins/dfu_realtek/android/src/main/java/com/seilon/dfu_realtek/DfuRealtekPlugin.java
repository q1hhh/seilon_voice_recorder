package com.seilon.dfu_realtek;

import android.content.Context;
import androidx.annotation.NonNull;

import com.realsil.sdk.core.RtkConfigure;
import com.realsil.sdk.core.RtkCore;
import com.realsil.sdk.core.logger.ZLogger;
import com.realsil.sdk.dfu.DfuConstants;
import com.realsil.sdk.dfu.RtkDfu;
import com.realsil.sdk.dfu.model.BinParameters;
import com.realsil.sdk.dfu.model.DfuConfig;
import com.realsil.sdk.dfu.model.DfuProgressInfo;
import com.realsil.sdk.dfu.model.OtaDeviceInfo;
import com.realsil.sdk.dfu.model.OtaModeInfo;
import com.realsil.sdk.dfu.utils.ConnectParams;
import com.realsil.sdk.dfu.utils.DfuAdapter;
import com.realsil.sdk.dfu.utils.GattDfuAdapter;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

public class DfuRealtekPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private MethodChannel channel;
    private Context context;
    private GattDfuAdapter dfuAdapter;
    private DfuConfig dfuConfig;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "dfu_realtek");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "initialize":
                boolean debug = call.argument("debug");
                RtkConfigure configure = new RtkConfigure.Builder()
                        .debugEnabled(debug)
                        .printLog(debug)
                        .logTag("OTA")
                        .globalLogLevel(ZLogger.INFO)
                        .build();

                RtkCore.initialize(context, configure);

                RtkDfu.initialize(context, debug);

                result.success(true);
                break;

            case "startOta":
                startOta(call, result);
                break;

            case "abort":
                if (dfuAdapter != null) {
                    dfuAdapter.abort();
                    dfuAdapter.close();
                }
                result.success(null);
                break;

            default:
                result.notImplemented();
        }
    }

    private void startOta(MethodCall call, MethodChannel.Result result) {
        String address = call.argument("address");
        String filePath = call.argument("filePath");
        int reconnectTimes = call.argument("reconnectTimes");

        dfuAdapter = GattDfuAdapter.getInstance(context);

        dfuAdapter.initialize(new DfuAdapter.DfuHelperCallback() {
            @Override
            public void onStateChanged(int state) {
                super.onStateChanged(state);
                switch (state) {
                    case DfuAdapter.STATE_INIT_OK:
                        connectRemote(address, reconnectTimes);
                        break;

                    case DfuAdapter.STATE_PREPARED:
                        DfuConfig deviceConfig = getDeviceConfig(address, filePath);
                        OtaDeviceInfo deviceInfo = getDeviceInfo();

                        if (deviceInfo != null) startOTA(deviceConfig, deviceInfo);
                        break;

                    case DfuAdapter.STATE_DISCONNECTED:
                    case DfuAdapter.STATE_CONNECT_FAILED:
                        break;
                }
            }

            @Override
            public void onError(int i, int i1) {
                super.onError(i, i1);
                channel.invokeMethod("onError", null);
            }

            @Override
            public void onProcessStateChanged(int state) {
                super.onProcessStateChanged(state);

                switch (state) {
                    case DfuConstants.PROGRESS_STARTED:
                        channel.invokeMethod("onOtaStart", null);
                        break;

                    case DfuConstants.PROGRESS_START_DFU_PROCESS:
                        channel.invokeMethod("onStartDfuProcess", null);
                        break;

                    case DfuConstants.PROGRESS_PENDING_ACTIVE_IMAGE:
                        channel.invokeMethod("onPendingActiveImage", null);
                        break;

                    case DfuConstants.PROGRESS_IMAGE_ACTIVE_SUCCESS:
                        channel.invokeMethod("onSuccess", null);
                        break;

                    default:
                        break;
                }
            }

            @Override
            public void onProgressChanged(DfuProgressInfo dfuProgressInfo) {
                super.onProgressChanged(dfuProgressInfo);

                if (dfuProgressInfo != null) {
                    int progress = dfuProgressInfo.getTotalProgress();
                    channel.invokeMethod("onProgress", progress);
                }
            }
        });
        result.success(true);
    }

    private void startOTA(DfuConfig dfuConfig, OtaDeviceInfo deviceInfo) {
        if (dfuConfig == null || deviceInfo == null) {
            return;
        }
        dfuAdapter.startOtaProcedure(dfuConfig, deviceInfo, true);
    }

    private void connectRemote(String address, int reconnectTimes) {
        ConnectParams.Builder connectParamBuilder = new ConnectParams.Builder()
                .address(address)
                .reconnectTimes(reconnectTimes)
                .batteryValueFormat(ConnectParams.BATTERY_VALUE_F1);

        dfuAdapter.connectDevice(connectParamBuilder.build());
    }

    private DfuConfig getDeviceConfig(String address, String binFilePath) {
        DfuConfig dfuConfig = new DfuConfig();
        dfuConfig.setChannelType(DfuConfig.CHANNEL_TYPE_GATT);
        dfuConfig.setAddress(address);

        dfuConfig.setVersionCheckEnabled(false);

        // 配置二进制文件参数
        dfuConfig.setBinParameters(
                new BinParameters.Builder().filePath(binFilePath).build()
        );
        dfuConfig.setFileSuffix("bin");

        // 获取工作模式
        if (dfuAdapter != null) {
            OtaModeInfo priorityWorkMode = dfuAdapter.getPriorityWorkMode(DfuConstants.OTA_MODE_SILENT_FUNCTION);
            if (priorityWorkMode != null) {
                dfuConfig.setOtaWorkMode(priorityWorkMode.getWorkmode());
            }
        }

        dfuConfig.setSectionSizeCheckEnabled(false);

        return dfuConfig;
    }

    private OtaDeviceInfo getDeviceInfo() {
        if (dfuAdapter == null) return null;
        return dfuAdapter.getOtaDeviceInfo();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }
}
