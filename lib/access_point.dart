class AccessPoint {
  final String ssid;
  final int rssi;

  AccessPoint({required this.ssid, required this.rssi});

  factory AccessPoint.fromJson(Map<String, dynamic> object) {
    return AccessPoint(ssid: object["ssid"], rssi: object["rssi"]);
  }

  static List<AccessPoint> fromJsonList(List<dynamic> json) {
    return json.map<AccessPoint>((e) => AccessPoint.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {"ssid": ssid, "rssi": rssi};
  }
}
