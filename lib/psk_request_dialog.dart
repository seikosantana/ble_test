import 'package:flutter/material.dart';

class PskRequestDialog extends StatefulWidget {
  final String ssid;

  const PskRequestDialog({super.key, required this.ssid});

  @override
  State<StatefulWidget> createState() => _PskRequestDialogState();
}

class _PskRequestDialogState extends State<PskRequestDialog> {
  String password = "";
  bool hidden = true;

  void onSubmit() {
    Navigator.pop(context, password);
  }

  void onCancel() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Connect to ${widget.ssid}"),
      content: TextField(
        obscureText: !hidden,
        decoration: InputDecoration(
          labelText: "WiFi Password",
          border: const OutlineInputBorder(),
          helperText: "Leave it blank for open WiFi",
          helperMaxLines: 2,
          suffixIcon: IconButton(
            icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                hidden = !hidden;
              });
            },
          ),
        ),
        onChanged: (String newValue) {
          setState(() {
            password = newValue;
          });
        },
      ),
      actions: [
        TextButton(
            onPressed: () {
              onCancel();
            },
            child: Text(
              "CANCEL",
              style: Theme.of(context)
                  .textTheme
                  .button
                  ?.copyWith(color: Colors.red),
            )),
        TextButton(
            onPressed: password.isEmpty || password.length >= 8
                ? () {
                    onSubmit();
                  }
                : null,
            child: const Text("SUBMIT")),
      ],
    );
  }
}
