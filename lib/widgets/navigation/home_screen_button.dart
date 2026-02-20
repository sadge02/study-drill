import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/constants/navigation/widgets/home_screen_button_widget_constants.dart';

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
      height: HomeScreenButtonWidgetConstants.buttonHeight,
      decoration: _buildDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GeneralConstants.smallPadding,
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        GeneralConstants.mediumCircularRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: HomeScreenButtonWidgetConstants.buttonOpacity,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: HomeScreenButtonWidgetConstants.buttonShadowOpacity,
          ),
          blurRadius: HomeScreenButtonWidgetConstants.buttonBlurRadius,
          offset: const Offset(
            HomeScreenButtonWidgetConstants.buttonXOffset,
            HomeScreenButtonWidgetConstants.buttonYOffset,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: GeneralConstants.primaryColor,
          size: GeneralConstants.smallIconSize,
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
