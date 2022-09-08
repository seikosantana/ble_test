import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:ble_test/ap_choose_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PairDialog extends StatefulWidget {
  const PairDialog({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PairDialogState();
}

class _PairDialogState extends State<PairDialog> {
  List<ScanResult> scanResults = [];
  StreamSubscription<List<ScanResult>>? subscription;

  void initialize() async {
    bool isOn = await FlutterBluePlus.instance.isOn;
    if (!isOn) {
      bool successful = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            useSafeArea: true,
            barrierLabel: "Barrier",
            builder: (context) => AlertDialog(
              title: const Text("Bluetooth Required"),
              content: const Text(
                  "Pairing requires bluetooth to discover, initialize, and configure device for the first time."),
              actions: [
                TextButton(
                  onPressed: () async {
                    await AppSettings.openBluetoothSettings();
                  },
                  child: const Text("OPEN SETTINGS"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, false);
                  },
                  child: const Text("CANCEL"),
                )
              ],
            ),
          ) ??
          false;
      // FlutterBluePlus.instance.turnOn();
    } else {
      scan();
    }
  }

  void scan() async {
    FlutterBluePlus.instance.startScan(allowDuplicates: false);
    subscription =
        FlutterBluePlus.instance.scanResults.listen((List<ScanResult> results) {
      if (!mounted) return;
      setState(() {
        scanResults = results;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  BluetoothDevice? connectedDevice;

  @override
  void dispose() {
    FlutterBluePlus.instance.stopScan();
    subscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  List<Widget> scanningIndicator() {
    return [
      const ListTile(
        title:
            Text("Searching for nearby devices", textAlign: TextAlign.center),
        dense: true,
      ),
      const Center(
        child: CircularProgressIndicator(),
      ),
      const SizedBox(
        height: 20,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text(
        "Pair New Device",
        textAlign: TextAlign.center,
      ),
      children: scanResults.isEmpty
          ? scanningIndicator()
          : scanResults
              .map((ScanResult result) => SimpleDialogOption(
                    onPressed: () async {
                      try {
                        await result.device.connect(autoConnect: false);
                        print("Connected");
                      } catch (e) {
                        if ((e as PlatformException).code ==
                            "already_connected") {
                          print("Already conencted la bro");
                          result.device.disconnect();
                          await result.device.connect(autoConnect: false);
                          print("Connected");
                        }
                        print(e);
                      }
                      connectedDevice = result.device;
                      await connectedDevice?.requestMtu(512);
                      List<BluetoothService> services =
                          await result.device.discoverServices();
                      BluetoothCharacteristic characteristic = services
                          .firstWhere((service) =>
                              service.uuid.toString() ==
                              "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
                          .characteristics
                          .firstWhere((element) =>
                              element.uuid.toString() ==
                              "d75b6b0c-5be7-434f-9653-4d0ebadfe578");
                      await characteristic.setNotifyValue(true);
                      Stream<List<int>> stream =
                          characteristic.onValueChangedStream;

                      await showDialog(
                          context: context,
                          builder: (context) => ApChooseDialog(
                                stream: stream,
                                device: result.device,
                              ));
                    },
                    child: Text("${result.device.name} ${result.rssi}"),
                  ))
              .toList(),
    );
  }
}
