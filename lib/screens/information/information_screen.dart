import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/constants/information/screens/information_screen_constants.dart';

import '../../utils/utils.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: GeneralConstants.appBarElevation,
        toolbarHeight: GeneralConstants.appBarHeight,
        centerTitle: true,
        title: Text(
          InformationScreenConstants.appBarTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: Utils.isMobile(context)
                ? GeneralConstants.mediumTitleSize
                : GeneralConstants.largeTitleSize,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: make information screen

            /// INFORMATION ICON
            const Icon(
              Icons.info_outline_rounded,
              size: GeneralConstants.largeIconSize,
              color: GeneralConstants.primaryColor,
            ),

            const SizedBox(height: GeneralConstants.mediumSpacing),

            /// INFORMATION TEXT
            Text(
              '${GeneralConstants.name} Information',
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.mediumFontSize,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
