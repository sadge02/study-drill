import 'package:flutter/cupertino.dart';

class Utils {
  static double getWidth(BuildContext context) {
    return MediaQuery.widthOf(context);
  }

  static bool isMobile(BuildContext context) {
    return getWidth(context) < 550;
  }

  static bool isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }
}
