import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user/user_model.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/user/screens/user_list_screen_constants.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            UserListScreenConstants.cardBorderRadius,
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
        UserListScreenConstants.cardBorderRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: UserListScreenConstants.cardBorderOpacity,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: UserListScreenConstants.cardShadowOpacity,
          ),
          blurRadius: UserListScreenConstants.cardBlurRadius,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: GeneralConstants.smallSpacing),
        Expanded(child: _buildInfo()),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: UserListScreenConstants.avatarRadius,
      backgroundColor: GeneralConstants.tertiaryColor,
      backgroundImage: user.profilePic.isNotEmpty
          ? NetworkImage(user.profilePic)
          : null,
      child: user.profilePic.isEmpty
          ? Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: GoogleFonts.lexend(
                color: GeneralConstants.backgroundColor,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.username,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            fontWeight: FontWeight.w500,
            color: GeneralConstants.primaryColor,
          ),
        ),
        if (user.description.isNotEmpty) ...[
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            user.description,
            overflow: TextOverflow.ellipsis,
            maxLines: UserListScreenConstants.descriptionMaxLines,
            style: GoogleFonts.lexend(
              fontSize: UserListScreenConstants.statFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.smallOpacity,
              ),
            ),
          ),
        ],
        const SizedBox(height: GeneralConstants.tinySpacing),
        _buildStats(),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        const Icon(
          Icons.folder_outlined,
          size: GeneralConstants.smallSmallIconSize,
          color: GeneralConstants.secondaryColor,
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Text(
          '${user.groupIds.length} ${UserListScreenConstants.groupsLabel}',
          style: GoogleFonts.lexend(
            fontSize: UserListScreenConstants.statFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.secondaryColor,
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        const Icon(
          Icons.people_outline,
          size: GeneralConstants.smallSmallIconSize,
          color: GeneralConstants.secondaryColor,
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Text(
          '${user.friendIds.length} ${UserListScreenConstants.friendsLabel}',
          style: GoogleFonts.lexend(
            fontSize: UserListScreenConstants.statFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.secondaryColor,
          ),
        ),
      ],
    );
  }
}
