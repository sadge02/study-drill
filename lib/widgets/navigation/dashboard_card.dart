import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/constants/navigation/widget/navigation_widget_constants.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NavigationWidgetConstants.dashboardHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          GeneralConstants.largeCircularRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: NavigationWidgetConstants.dashboardShadowOpacity,
            ),
            blurRadius: NavigationWidgetConstants.dashboardBlurRadius,
            offset: const Offset(
              NavigationWidgetConstants.dashboarXOffset,
              NavigationWidgetConstants.dashboarYOffset,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            GeneralConstants.largeCircularRadius,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GeneralConstants.largePadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// DASHBOARD TITLE
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: GeneralConstants.mediumFontSize,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(
                        height: GeneralConstants.smallSmallSpacing,
                      ),

                      /// DASHBOARD SUBTITLE
                      Text(
                        subtitle,
                        style: GoogleFonts.lexend(
                          fontSize: GeneralConstants.smallFontSize,
                          fontWeight: FontWeight.w300,
                          color: textColor.withValues(
                            alpha: NavigationWidgetConstants.dashboardOpacity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: textColor,
                  size: GeneralConstants.mediumIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
