import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/error/screens/initialization_error_screen_constants.dart';
import 'package:study_drill/utils/constants/general_constants.dart';

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.lexendTextTheme()),
      home: Scaffold(
        backgroundColor: GeneralConstants.backgroundColor,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.largePadding,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInitializationErrorIcon(),
            const SizedBox(height: GeneralConstants.mediumSpacing),
            _buildErrorTitle(),
            const SizedBox(height: GeneralConstants.smallSpacing),
            _buildErrorMessage(),
            const SizedBox(height: GeneralConstants.largeSpacing),
            _buildRestartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializationErrorIcon() {
    return const Icon(
      Icons.cloud_off_rounded,
      color: GeneralConstants.primaryColor,
      size: GeneralConstants.largeIconSize,
    );
  }

  Widget _buildErrorTitle() {
    return Text(
      InitializationErrorScreenConstants.errorTitle,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.largeFontSize,
        fontWeight: FontWeight.bold,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      InitializationErrorScreenConstants.errorMessage,
      textAlign: TextAlign.center,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.mediumFontSize,
        color: GeneralConstants.secondaryColor,
      ),
    );
  }

  Widget _buildRestartButton() {
    return ElevatedButton.icon(
      onPressed: onRestart,
      style: ElevatedButton.styleFrom(
        backgroundColor: GeneralConstants.primaryColor,
        foregroundColor: GeneralConstants.backgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.largePadding,
          vertical: GeneralConstants.mediumPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
        ),
        elevation: GeneralConstants.buttonElevation,
      ),
      icon: const Icon(
        Icons.refresh_rounded,
        size: GeneralConstants.smallIconSize,
      ),
      label: Text(
        InitializationErrorScreenConstants.restartButtonText,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.mediumFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
