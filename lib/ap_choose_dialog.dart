import 'dart:async';
import 'dart:convert';

import 'package:ble_test/access_point.dart';
import 'package:ble_test/helper.dart';
import 'package:ble_test/psk_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  String? value;

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
    super.dispose();
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
        return AccessPoint.fromJsonList(jsonDecode(value))
            .map((e) => SimpleDialogOption(
                  child: Text(e.ssid),
                  onPressed: () async {
                    String? password = await showDialog(
                        context: context,
                        builder: (context) =>
                            PskRequestDialog(ssid: e.ssid)) as String?;
                    List<BluetoothService> services =
                        await widget.device.discoverServices();
                    BluetoothService userInputCredService = services.firstWhere(
                        (element) =>
                            element.uuid.toString() ==
                            "4fafc201-1fb5-459e-8fcc-c5c9c331914c");
                    BluetoothCharacteristic userInputCharacteristic =
                        userInputCredService.characteristics.firstWhere(
                            (element) =>
                                element.uuid.toString() ==
                                "beb5483e-36e1-4688-b7f5-ea07361b26a8");

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
