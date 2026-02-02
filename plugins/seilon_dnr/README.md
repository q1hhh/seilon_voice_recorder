# seilon_dnr

A Flutter plugin for Digital Noise Reduction (DNR) audio processing on Android and iOS platforms.

## Features

- **Digital Noise Reduction**: Advanced audio noise reduction algorithm
- **Real-time Processing**: Process audio data streams in real-time
- **File Processing**: Process audio files with progress tracking
- **Configurable Noise Reduction**: Adjustable noise reduction levels (-200dB to 0dB)
- **Cross-platform**: Supports both Android and iOS
- **Progress Monitoring**: Real-time progress updates during file processing
- **Resource Management**: Proper initialization and disposal of DNR resources

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  seilon_dnr: ^0.0.1
```

### Usage

#### Basic Setup

```dart
import 'package:seilon_dnr/seilon_dnr.dart';

// Initialize DNR with sample rate (typically 16000)
int status = await DnrPlugin.initialize(16000);
if (status == DnrPlugin.statusNoError) {
  print('DNR initialized successfully');
} else {
  print('Initialization failed: ${DnrPlugin.getStatusMessage(status)}');
}
```

#### Process Audio File

```dart
// Process an audio file
Uint8List processedAudio = await DnrPlugin.processAudioFile('/path/to/audio.wav');

// Listen to processing progress
DnrPlugin.progressStream.listen((progress) {
  print('Processing progress: $progress%');
});

// Save processed audio
String savedPath = await DnrPlugin.saveAudioData(processedAudio, 'processed_audio.wav');
```

#### Real-time Audio Processing

```dart
// Process audio data in real-time (Q31 format, 256 samples)
List<int> audioData = [/* your audio data */];
ProcessResult result = await DnrPlugin.processAudioData(audioData);

if (result.isSuccess) {
  print('Processed audio data: ${result.processedData}');
} else {
  print('Processing failed: ${result.statusMessage}');
}
```

#### Configure Noise Reduction

```dart
// Set noise reduction level (-200dB to 0dB)
// -200dB: Maximum noise reduction
// 0dB: No noise reduction
await DnrPlugin.setNoiseReductionLevel(-50.0);
```

#### Cleanup

```dart
// Dispose DNR resources when done
await DnrPlugin.dispose();
```

## API Reference

### DnrPlugin Class

#### Methods

- `initialize(int sampleRate)` - Initialize DNR with specified sample rate
- `isInitialized()` - Check if DNR is initialized
- `getVersion()` - Get DNR version information
- `getBufferSizes()` - Get buffer size information
- `setNoiseReductionLevel(double dB)` - Set noise reduction level (-200 to 0 dB)
- `processAudioFile(String filePath)` - Process audio file and return WAV data
- `processAudioData(List<int> audioData)` - Process real-time audio data
- `saveAudioData(Uint8List audioData, String fileName)` - Save audio data to file
- `cancelProcessing()` - Cancel ongoing audio processing
- `dispose()` - Release DNR resources

#### Properties

- `progressStream` - Stream for monitoring processing progress

#### Status Constants

- `statusNoError` - No error occurred
- `statusNotReady` - DNR not ready
- `statusInvalidParam` - Invalid parameter
- `statusInvalidLicense` - Invalid license
- `statusBufferOverflow` - Buffer overflow
- `statusBufferTooSmall` - Buffer too small

### ProcessResult Class

- `status` - Processing status code
- `processedData` - Processed audio data
- `isSuccess` - Whether processing was successful
- `statusMessage` - Human-readable status message

### DnrException Class

Custom exception thrown when DNR operations fail.

## Platform Support

- **Android**: API level 21+
- **iOS**: iOS 11.0+

## Requirements

- Flutter SDK: ^3.6.0
- Dart SDK: ^3.6.0

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues and Feedback

Please file issues and feature requests on the [GitHub repository](https://github.com/your-username/seilon_dnr).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

