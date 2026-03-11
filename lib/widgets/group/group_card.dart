import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group/group_model.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/group/screens/group_list_screen_constants.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final GroupModel group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            GroupListScreenConstants.cardBorderRadius,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GeneralConstants.smallPadding),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      color: GeneralConstants.backgroundColor,
      borderRadius: BorderRadius.circular(
        GroupListScreenConstants.cardBorderRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: GroupListScreenConstants.cardBorderOpacity,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: GroupListScreenConstants.cardShadowOpacity,
          ),
          blurRadius: GroupListScreenConstants.cardBlurRadius,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (group.description.isNotEmpty) ...[
          const SizedBox(height: GeneralConstants.tinySpacing),
          _buildDescription(),
        ],
        if (group.tags.isNotEmpty) ...[
          const SizedBox(height: GeneralConstants.smallSpacing),
          _buildTags(),
        ],
        const SizedBox(height: GeneralConstants.smallSpacing),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            group.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.mediumFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        _buildVisibilityBadge(),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      group.description,
      overflow: TextOverflow.ellipsis,
      maxLines: GroupListScreenConstants.descriptionMaxLines,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        fontWeight: FontWeight.w300,
        color: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.smallOpacity,
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: GroupListScreenConstants.tagChipSpacing,
      runSpacing: GroupListScreenConstants.tagChipSpacing,
      children: group.tags.map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GroupListScreenConstants.visibilityBadgeHorizontalPadding,
        vertical: GroupListScreenConstants.visibilityBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.tertiaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.lexend(
          fontSize: GroupListScreenConstants.visibilityBadgeFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.secondaryColor,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        const Icon(
          Icons.people_outline,
          size: GeneralConstants.smallSmallIconSize,
          color: GeneralConstants.secondaryColor,
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Text(
          '${group.memberCount} ${GroupListScreenConstants.membersLabel}',
          style: GoogleFonts.lexend(
            fontSize: GroupListScreenConstants.visibilityBadgeFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.secondaryColor,
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        const Icon(
          Icons.library_books_outlined,
          size: GeneralConstants.smallSmallIconSize,
          color: GeneralConstants.secondaryColor,
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Text(
          '${group.totalContentCount} ${GroupListScreenConstants.itemsLabel}',
          style: GoogleFonts.lexend(
            fontSize: GroupListScreenConstants.visibilityBadgeFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityBadge() {
    final String label;
    final Color color;

    if (group.isPublic) {
      label = GroupListScreenConstants.visibilityPublic;
      color = GeneralConstants.successColor;
    } else if (group.isFriendsOnly) {
      label = GroupListScreenConstants.visibilityFriends;
      color = GeneralConstants.tertiaryColor;
    } else {
      label = GroupListScreenConstants.visibilityPrivate;
      color = GeneralConstants.failureColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GroupListScreenConstants.visibilityBadgeHorizontalPadding,
        vertical: GroupListScreenConstants.visibilityBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: GroupListScreenConstants.visibilityBadgeFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
