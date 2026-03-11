import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/error/screens/error_screen_constants.dart';
import '../home/home_screen.dart';

// Screen for when something goes wrong
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          ErrorScreenConstants.appBarTitle,
          style: GoogleFonts.lexend(
            fontSize: ErrorScreenConstants.titleFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: ErrorScreenConstants.iconSize,
                color: GeneralConstants.failureColor.withValues(alpha: 0.6),
              ),
              SizedBox(height: ErrorScreenConstants.spacing),
              Text(
                message ?? ErrorScreenConstants.defaultErrorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: ErrorScreenConstants.messageFontSize,
                  fontWeight: FontWeight.w300,
                  color: GeneralConstants.primaryColor,
                ),
              ),
              SizedBox(height: ErrorScreenConstants.spacing * 2),
              if (onRetry != null)
                SizedBox(
                  width: ErrorScreenConstants.buttonWidth,
                  height: ErrorScreenConstants.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(
                      Icons.refresh,
                      color: GeneralConstants.backgroundColor,
                    ),
                    label: Text(
                      ErrorScreenConstants.retryLabel,
                      style: GoogleFonts.lexend(
                        fontSize: GeneralConstants.smallFontSize,
                        fontWeight: FontWeight.w500,
                        color: GeneralConstants.backgroundColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GeneralConstants.secondaryColor,
                      elevation: GeneralConstants.buttonElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GeneralConstants.mediumCircularRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              if (onRetry != null)
                SizedBox(height: ErrorScreenConstants.spacing),
              SizedBox(
                width: ErrorScreenConstants.buttonWidth,
                height: ErrorScreenConstants.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Navigator.canPop(context)
                        ? Icons.arrow_back
                        : Icons.home_outlined,
                    color: GeneralConstants.secondaryColor,
                  ),
                  label: Text(
                    Navigator.canPop(context)
                        ? ErrorScreenConstants.goBackLabel
                        : ErrorScreenConstants.goHomeLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w400,
                      color: GeneralConstants.secondaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: GeneralConstants.secondaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GeneralConstants.mediumCircularRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
