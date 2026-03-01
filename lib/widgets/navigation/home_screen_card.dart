import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/core/general_constants.dart';

import '../../utils/constants/navigation/widgets/home_screen_card_widget_constants.dart';

/// A customizable card widget for the home screen dashboard.
///
/// [HomeScreenCard] displays a card with an icon, title, and subtitle.
/// The card is fully customizable with colors, text styling, and tap handling.
class HomeScreenCard extends StatelessWidget {
  const HomeScreenCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  /// The main title text displayed at the top of the card.
  final String title;

  /// The subtitle text displayed below the title with reduced opacity.
  final String subtitle;

  /// The icon displayed on the right side of the card.
  final IconData icon;

  /// The background color of the card.
  final Color color;

  /// The color used for the title, subtitle, and icon text.
  final Color textColor;

  /// Callback triggered when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreenCard: Building card - $title');
    return Container(
      height: HomeScreenCardWidgetConstants.cardHeight,
      decoration: _buildDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            GeneralConstants.largeCircularRadius,
          ),
          onTap: () {
            debugPrint('HomeScreenCard: Tapped - $title');
            onTap();
          },
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

  /// Builds the decoration (background, border radius, and shadow) for the card.
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

  /// Builds the text content (title and subtitle) section of the card.
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTitle(),
        const SizedBox(height: GeneralConstants.tinySpacing),
        _buildSubtitle(),
      ],
    );
  }

  /// Builds the title text widget.
  Widget _buildTitle() {
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      maxLines: HomeScreenCardWidgetConstants.titleMaxLines,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.mediumFontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  /// Builds the subtitle text widget with reduced opacity.
  Widget _buildSubtitle() {
    return Text(
      subtitle,
      overflow: TextOverflow.ellipsis,
      maxLines: HomeScreenCardWidgetConstants.subtitleMaxLines,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        fontWeight: FontWeight.w300,
        color: textColor.withValues(
          alpha: HomeScreenCardWidgetConstants.cardOpacity,
        ),
      ),
    );
  }

  /// Builds the icon widget displayed on the right side of the card.
  Widget _buildIcon() {
    return Icon(icon, color: textColor, size: GeneralConstants.mediumIconSize);
  }
}
