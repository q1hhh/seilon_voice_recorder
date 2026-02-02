import 'package:flutter/material.dart';
import 'package:dfu_realtek/dfu_realtek.dart';

main() {
  runApp(DfuPage());
}

class DfuPage extends StatefulWidget {
  const DfuPage({super.key});

  @override
  State<DfuPage> createState() => _DfuPageState();
}

class _DfuPageState extends State<DfuPage> {
  final dfu = DfuRealtek();
  double progress = 0.0;
  String status = 'waiting for upgrade';

  @override
  void initState() {
    super.initState();
    dfu.initialize(debug: true);
    dfu.progressStream.listen((info) {
      setState(() {
        progress = info / 100;
        status = "upgrading $info%";
      });
    });
    dfu.statusStream.listen((state) {
      switch (state) {
        case DfuStatus.success:
          setState(() => status = "success");
          break;
        case DfuStatus.failed:
          setState(() => status = "failed");
          break;
        case DfuStatus.aborted:
          setState(() => status = "aborted");
          break;
        default:
          break;
      }
    });
  }

  Future<void> startOta() async {
    await dfu.startOta(
      address: "AA:BB:CC:DD:EE:FF",
      filePath: "/storage/emulated/0/firmware.bin",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Realtek DFU upgrade")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: startOta,
              child: const Text("start OTA"),
            ),
          ],
        ),
      ),
    );
  }
}
