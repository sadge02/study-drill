import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/general_constants.dart';

import '../../utils/constants/navigation/widgets/home_screen_card_widget_constants.dart';

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
      height: HomeScreenCardWidgetConstants.cardHeight,
      decoration: _buildDecoration(),
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
                Expanded(child: _buildTextContent()),
                _buildIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(GeneralConstants.largeCircularRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(
            alpha: HomeScreenCardWidgetConstants.cardShadowOpacity,
          ),
          blurRadius: HomeScreenCardWidgetConstants.cardBlurRadius,
          offset: const Offset(
            HomeScreenCardWidgetConstants.cardXOffset,
            HomeScreenCardWidgetConstants.cardYOffset,
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: GeneralConstants.tinySpacing),
        Text(
          subtitle,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            fontWeight: FontWeight.w300,
            color: textColor.withValues(
              alpha: HomeScreenCardWidgetConstants.cardOpacity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Icon(icon, color: textColor, size: GeneralConstants.mediumIconSize);
  }
}
