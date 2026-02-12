import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/constants/navigation/widget/navigation_widget_constants.dart';

class DashboardButton extends StatelessWidget {
  const DashboardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NavigationWidgetConstants.dashboardButtonHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: NavigationWidgetConstants.dashboardButtonOpacity,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: NavigationWidgetConstants.dashboarButtonShadowOpacity,
            ),
            blurRadius: NavigationWidgetConstants.dashboarButtonBlurRadius,
            offset: const Offset(
              NavigationWidgetConstants.dashboarButtonXOffset,
              NavigationWidgetConstants.dashboarButtonYOffset,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// BUTTON ICON
              Icon(
                icon,
                color: GeneralConstants.primaryColor,
                size: GeneralConstants.smallIconSize,
              ),

              const SizedBox(width: GeneralConstants.smallSmallSpacing),

              /// BUTTON TEXT
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
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
