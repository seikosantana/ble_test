import 'dart:async';
import 'dart:convert';

import 'package:ble_test/access_point.dart';
import 'package:ble_test/helper.dart';
import 'package:ble_test/psk_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ble_test/pair_result_dialog.dart';

// Service for device connection info
const String INFO_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914d";
const String INFO_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a7";

// Service for user input SSID and PSK
const String CRED_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914c";
const String CRED_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// Service for available AP SSID, RSSI
const String DATA_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String DATA_CHARACTERISTIC_UUID = "d75b6b0c-5be7-434f-9653-4d0ebadfe578";

class ApChooseDialog extends StatefulWidget {
  final BluetoothDevice device;
  final Stream<List<int>> stream;

  const ApChooseDialog({required this.stream, required this.device, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ApChooseDialogState();
}

class _ApChooseDialogState extends State<ApChooseDialog> {
  StreamSubscription<List<int>>? subscription;
  StreamSubscription<List<int>>? deviceNetworkInfoSubscription;
  Stream<List<int>>? deviceNetworkInfoStream;
  String? value, deviceNetworkInfoValue;

  @override
  void initState() {
    super.initState();
    subscription = widget.stream.listen((bytes) {
      setState(() {
        value = utf8.decode(bytes);
      });
      print(value);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    deviceNetworkInfoSubscription?.cancel();
    super.dispose();
  }

  List<Widget> scanningIndicator(String ssid) {
    return [
      const ListTile(
        title: Text("Connecting device to ssid", textAlign: TextAlign.center),
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

  List<Widget> buildList(String? value) {
    if (value == null) {
      return const [
        Center(
          child: CircularProgressIndicator(),
        )
      ];
    } else {
      if (value.isValidJson()) {
        return AccessPoint.fromDeviceJson(value)
            .map((e) => SimpleDialogOption(
                  child: Text("${e.ssid} ${e.rssi}"),
                  onPressed: () async {
                    String? password = await showDialog(
                        context: context,
                        builder: (context) =>
                            PskRequestDialog(ssid: e.ssid)) as String?;
                    List<BluetoothService> services =
                        await widget.device.discoverServices();
                    BluetoothService userInputCredService = services.firstWhere(
                        (element) =>
                            element.uuid.toString() == CRED_SERVICE_UUID);
                    BluetoothCharacteristic userInputCharacteristic =
                        userInputCredService.characteristics.firstWhere(
                            (element) =>
                                element.uuid.toString() ==
                                CRED_CHARACTERISTIC_UUID);

                    // Listen for network information before send credential
                    BluetoothCharacteristic deviceNetworkInfoService = services
                        .firstWhere((service) =>
                            service.uuid.toString() == INFO_SERVICE_UUID)
                        .characteristics
                        .firstWhere((element) =>
                            element.uuid.toString() ==
                            INFO_CHARACTERISTIC_UUID);
                    await deviceNetworkInfoService.setNotifyValue(true);
                    deviceNetworkInfoStream =
                        deviceNetworkInfoService.onValueChangedStream;

                    deviceNetworkInfoSubscription =
                        deviceNetworkInfoStream!.listen((bytes) {
                      setState(() {
                        deviceNetworkInfoValue = utf8.decode(bytes);
                      });                      
                      print(deviceNetworkInfoValue);
                      Map<String, dynamic> json =
                          jsonDecode(deviceNetworkInfoValue!);
                      deviceNetworkInfoSubscription?.cancel();
                      showDialog(
                          context: context,
                          builder: (context) => PairResultDialog(
                              status: json["status"], ssid: e.ssid));
                    });                    

                    String value =
                        jsonEncode({"ssid": e.ssid, "psk": password});

                    await userInputCharacteristic.write(utf8.encode(value));                    
                  },
                ))
            .toList();
      } else {
        return [
          const ListTile(
            title: Text("Unable to scan for APs"),
            subtitle: Text("Please try again"),
          )
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        title: const Text(
          "Select WiFi Access Point",
        ),
        children: value == null
            ? const [
                Center(
                  child: CircularProgressIndicator(),
                )
              ]
            : buildList(value));
  }
}
