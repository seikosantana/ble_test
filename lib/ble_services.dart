import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleServices {
  static BleServices? _instance;

  BleServices._singleton();

  static BleServices get instance => _instance ??= BleServices._singleton();
  List<ScanResult> results = [];

  void scan() {
    results = [];
    FlutterBluePlus.instance.startScan(allowDuplicates: false);
    FlutterBluePlus.instance.scanResults.listen((List<ScanResult> results) {
      this.results = results;
    });
  }

  void stopScan() {
    FlutterBluePlus.instance.stopScan();
  }
}
