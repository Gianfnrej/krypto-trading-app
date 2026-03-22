import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bonus scannen")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue == "BONUS") {
              var box = Hive.box('tradingBox');
              double balance = box.get('guthaben', defaultValue: 10000.0);
              box.put('guthaben', balance + 1000.0);

              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}