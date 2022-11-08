import 'dart:convert';
import 'package:ble_test/wifi_auth.dart';



class AccessPoint {
  final String ssid;
  final int rssi;
  final WiFiAuthRequirement wiFiAuth;

  AccessPoint({required this.ssid, required this.rssi, required this.wiFiAuth});

  static List<AccessPoint> fromDeviceJson(String jsonString) {
    Map<String, dynamic> decoded = jsonDecode(jsonString);
    List<AccessPoint> result = [];
    for (var element in decoded.keys) {
      result.add(AccessPoint(
        ssid: element,
        rssi: decoded[element][1],
        wiFiAuth: decoded[element][0] == 0
            ? WiFiAuthRequirement.Open
            : WiFiAuthRequirement.Password,
      ));
    }
    return result;
  }
}
