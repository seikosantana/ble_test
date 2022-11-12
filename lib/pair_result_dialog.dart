import 'package:flutter/material.dart';

class PairResultDialog extends StatefulWidget {
  final int status;
  final String ssid;
  const PairResultDialog({required this.status, required this.ssid, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PairResultState();
}

class _PairResultState extends State<PairResultDialog> {
  static int wifiConnected = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.status == wifiConnected
          ? const Text("Pairing Succeed")
          : const Text("Pairing Failed"),
      content: widget.status == wifiConnected
          ? Text("Device connected to ${widget.ssid}")
          : const Text("Device cannot connect to WiFi, please try again."),
      actions: [
        TextButton(
          onPressed: () {
            widget.status == wifiConnected
            ? Navigator.of(context).popUntil((route) => route.isFirst)
            : Navigator.pop(context);
          },
          child: const Text("OKAY"),
        )
      ],
    );
  }
}
