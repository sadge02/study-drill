import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';

class StudyDrillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyDrillAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize =>
      const Size.fromHeight(GeneralConstants.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: GeneralConstants.backgroundColor,
      elevation: GeneralConstants.appBarElevation,
      toolbarHeight: GeneralConstants.appBarHeight,
      iconTheme: const IconThemeData(color: GeneralConstants.primaryColor),
      centerTitle: true,
      leading: IconButton(onPressed: () => {}, icon: const Icon(Icons.menu)),
      actions: actions,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.lexend(
          fontSize: Utils.isMobile(context)
              ? GeneralConstants.mediumTitleSize
              : GeneralConstants.largeTitleSize,
          fontWeight: FontWeight.w200,
          color: GeneralConstants.primaryColor,
        ),
      ),
    );
  }
}
