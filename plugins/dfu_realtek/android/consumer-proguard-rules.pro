# 保留 Realtek 所有 SDK 类
-keep class com.realsil.sdk.** { *; }

# 防止 R8 报类缺失（如果未使用 SPP/USB 仍需添加避免扫描时报错）
-dontwarn com.realsil.sdk.bbpro.**
-dontwarn com.realsil.sdk.core.usb.**
