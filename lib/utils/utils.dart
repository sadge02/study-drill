import 'package:flutter/cupertino.dart';
import 'package:study_drill/utils/constants/general_constants.dart';

class Utils {
  static double getWidth(BuildContext context) {
    return MediaQuery.widthOf(context);
  }

  static bool isMobile(BuildContext context) {
    return getWidth(context) < GeneralConstants.mobileThreshold;
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
