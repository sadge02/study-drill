import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/tutorial/screens/tutorial_screen_constants.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <_TutorialPage>[
    _TutorialPage(
      icon: Icons.school_outlined,
      iconColor: GeneralConstants.secondaryColor,
      title: TutorialScreenConstants.welcomeTitle,
      description: TutorialScreenConstants.welcomeDescription,
    ),
    _TutorialPage(
      icon: Icons.group_outlined,
      iconColor: GeneralConstants.tertiaryColor,
      title: TutorialScreenConstants.groupsTitle,
      description: TutorialScreenConstants.groupsDescription,
    ),
    _TutorialPage(
      icon: Icons.quiz_outlined,
      iconColor: Color(0xFF4CAF50),
      title: TutorialScreenConstants.testsTitle,
      description: TutorialScreenConstants.testsDescription,
    ),
    _TutorialPage(
      icon: Icons.style_outlined,
      iconColor: Color(0xFFFF9800),
      title: TutorialScreenConstants.flashcardsTitle,
      description: TutorialScreenConstants.flashcardsDescription,
    ),
    _TutorialPage(
      icon: Icons.link,
      iconColor: Color(0xFF9C27B0),
      title: TutorialScreenConstants.connectTitle,
      description: TutorialScreenConstants.connectDescription,
    ),
    _TutorialPage(
      icon: Icons.rocket_launch_outlined,
      iconColor: GeneralConstants.secondaryColor,
      title: TutorialScreenConstants.readyTitle,
      description: TutorialScreenConstants.readyDescription,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;
  bool get _isFirstPage => _currentPage == 0;

  void _goNext() {
    if (_isLastPage) {
      Navigator.pop(context);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(
        milliseconds: GeneralConstants.transitionDurationMs ~/ 2,
      ),
      curve: Curves.easeInOut,
    );
  }

  void _goPrev() {
    _pageController.previousPage(
      duration: const Duration(
        milliseconds: GeneralConstants.transitionDurationMs ~/ 2,
      ),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: GeneralConstants.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          TutorialScreenConstants.appBarTitle,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
        actions: [
          if (!_isLastPage)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                TutorialScreenConstants.skipLabel,
                style: GoogleFonts.lexend(
                  fontSize: GeneralConstants.smallFontSize,
                  fontWeight: FontWeight.w400,
                  color: GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.mediumOpacity,
                  ),
                ),
              ),
            ),
          const SizedBox(width: GeneralConstants.smallMargin),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _buildPage(_pages[i]),
            ),
          ),
          _buildDots(),
          SizedBox(height: TutorialScreenConstants.sectionSpacing),
          _buildButtons(),
          SizedBox(height: TutorialScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialPage page) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TutorialScreenConstants.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: TutorialScreenConstants.iconSize + 40,
                height: TutorialScreenConstants.iconSize + 40,
                decoration: BoxDecoration(
                  color: page.iconColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: TutorialScreenConstants.iconSize,
                  color: page.iconColor,
                ),
              ),
              SizedBox(height: TutorialScreenConstants.sectionSpacing),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: TutorialScreenConstants.titleFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.primaryColor,
                ),
              ),
              SizedBox(height: TutorialScreenConstants.sectionSpacing / 2),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: TutorialScreenConstants.descriptionFontSize,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                  color: GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.smallOpacity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: TutorialScreenConstants.dotSpacing / 2,
          ),
          width: _currentPage == i
              ? TutorialScreenConstants.dotSize * 2.5
              : TutorialScreenConstants.dotSize,
          height: TutorialScreenConstants.dotSize,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? GeneralConstants.secondaryColor
                : GeneralConstants.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(
              TutorialScreenConstants.dotSize / 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.mediumMargin,
      ),
      child: Row(
        children: [
          if (!_isFirstPage)
            Expanded(
              child: SizedBox(
                height: TutorialScreenConstants.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _goPrev,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: GeneralConstants.secondaryColor,
                  ),
                  label: Text(
                    TutorialScreenConstants.previousLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w500,
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
            )
          else
            const Spacer(),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: SizedBox(
              height: TutorialScreenConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _goNext,
                icon: Icon(
                  _isLastPage ? Icons.check : Icons.arrow_forward,
                  color: GeneralConstants.backgroundColor,
                ),
                label: Text(
                  _isLastPage
                      ? TutorialScreenConstants.doneLabel
                      : TutorialScreenConstants.nextLabel,
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
          ),
        ],
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
}
