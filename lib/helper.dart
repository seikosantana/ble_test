import 'dart:convert';

extension StringValidators on String {
  bool isValidJson() {
    bool success = false;
    try {
      jsonDecode(this);
      success = true;
    } on FormatException catch (e) {
      success = false;
    }
    return success;
  }
}
