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
        // remove empty device name
        scanResults = [];
        for (var element in results) {
          if (element.device.name.contains("IOTA")) {
            scanResults.add(element);
          }
        }
        // scanResults = results;
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

  Widget loadingIndicator(String title) {
    return AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: const SizedBox(
          height: 40,
          width: 40,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("CANCEL"),
          )
        ]);
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
                        showDialog(
                            context: context,
                            builder: (context) => loadingIndicator(
                                "Connecting to ${result.device.name}"));
                        await result.device.connect(autoConnect: false);
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
                              service.uuid.toString() == DATA_SERVICE_UUID)
                          .characteristics
                          .firstWhere((element) =>
                              element.uuid.toString() ==
                              DATA_CHARACTERISTIC_UUID);
                      await characteristic.setNotifyValue(true);
                      Stream<List<int>> stream =
                          characteristic.onValueChangedStream;

                      // dismiss loading indicator
                      if (mounted) {
                        Navigator.pop(context);
                        print("Connected");
                      }

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
