import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/test/test_model.dart';
import '../../models/user/user_model.dart';
import '../../service/test/test_service.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/test/screens/test_detail_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'test_create_edit_screen.dart';
import 'test_screen.dart';

// Screen with details of a test
class TestDetailScreen extends StatefulWidget {
  const TestDetailScreen({super.key, required this.testId});

  final String testId;

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen>
    with SingleTickerProviderStateMixin {
  final TestService _testService = TestService();
  final UserService _userService = UserService();

  late TabController _tabController;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TestDetailScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleDelete(TestModel test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          TestDetailScreenConstants.deleteConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          TestDetailScreenConstants.deleteConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              TestDetailScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              TestDetailScreenConstants.confirmDeleteLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _testService.deleteTest(test.id);
    if (!mounted) return;

    _showSnackBar(
      const CustomSnackBar.success(
        message: TestDetailScreenConstants.deleteSuccessMessage,
      ),
    );
    Navigator.pop(context);
  }

  void _navigateToEdit(TestModel test) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => TestCreateEditScreen(test: test)),
    );
  }

  void _navigateToTest(TestModel test) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => TestScreen(test: test)),
    );
  }

  void _showSnackBar(Widget snackBar) {
    showTopSnackBar(
      Overlay.of(context),
      displayDuration: const Duration(
        milliseconds: GeneralConstants.notificationDurationMs,
      ),
      snackBarPosition: SnackBarPosition.bottom,
      snackBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TestModel?>(
      stream: _testService.streamTestById(widget.testId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: const Center(
              child: CircularProgressIndicator(
                color: GeneralConstants.primaryColor,
              ),
            ),
          );
        }

        final test = snapshot.data;
        if (test == null) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: Center(
              child: Text(
                'Test not found.',
                style: GoogleFonts.lexend(
                  color: GeneralConstants.primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: GeneralConstants.backgroundColor,
          appBar: _buildAppBar(test),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(test),
                    _buildQuestionsTab(test),
                    _buildStatisticsTab(test),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(TestModel? test) {
    return AppBar(
      backgroundColor: GeneralConstants.backgroundColor,
      toolbarHeight: GeneralConstants.appBarHeight,
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
        test?.title ?? TestDetailScreenConstants.appBarTitle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lexend(
          fontSize: Utils.isMobile(context)
              ? GeneralConstants.smallTitleSize
              : GeneralConstants.mediumTitleSize,
          fontWeight: FontWeight.w200,
          color: GeneralConstants.primaryColor,
        ),
      ),
      actions: test != null ? _buildAppBarActions(test) : null,
    );
  }

  List<Widget> _buildAppBarActions(TestModel test) {
    final bool isAuthor = test.authorId == _currentUserId;

    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: GeneralConstants.primaryColor),
        offset: const Offset(0, GeneralConstants.appBarHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _navigateToEdit(test);
            case 'delete':
              _handleDelete(test);
          }
        },
        itemBuilder: (_) {
          final items = <PopupMenuEntry<String>>[];

          if (isAuthor) {
            items.add(
              _buildPopupItem(
                'edit',
                Icons.edit_outlined,
                TestDetailScreenConstants.editTestLabel,
                GeneralConstants.primaryColor,
              ),
            );
            items.add(
              _buildPopupItem(
                'delete',
                Icons.delete_outline,
                TestDetailScreenConstants.deleteTestLabel,
                GeneralConstants.failureColor,
              ),
            );
          }

          return items;
        },
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w300,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GeneralConstants.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: GeneralConstants.secondaryColor,
        unselectedLabelColor: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.mediumOpacity,
        ),
        indicatorColor: GeneralConstants.secondaryColor,
        labelStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w300,
        ),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: TestDetailScreenConstants.overviewTab),
          Tab(text: TestDetailScreenConstants.questionsTab),
          Tab(text: TestDetailScreenConstants.statisticsTab),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(TestModel test) {
    final myAttempts = test.attemptsForUser(_currentUserId);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow(test, myAttempts),
          _buildSpacing(height: TestDetailScreenConstants.sectionSpacing),
          _buildStartButton(test),
          _buildSpacing(height: TestDetailScreenConstants.sectionSpacing),
          _buildInfoSection(
            TestDetailScreenConstants.descriptionLabel,
            Icons.description_outlined,
            child: Text(
              test.description.isEmpty
                  ? TestDetailScreenConstants.noDescriptionLabel
                  : test.description,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: test.description.isEmpty
                    ? GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      )
                    : GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            TestDetailScreenConstants.tagsLabel,
            Icons.tag,
            child: test.tags.isEmpty
                ? Text(
                    TestDetailScreenConstants.noTagsLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: TestDetailScreenConstants.tagChipSpacing,
                    runSpacing: TestDetailScreenConstants.tagChipSpacing,
                    children: test.tags.map(_buildTagChip).toList(),
                  ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            TestDetailScreenConstants.timeLimitLabel,
            Icons.timer_outlined,
            child: Text(
              test.isTimed
                  ? _formatTimeLimit(test.timeLimit!)
                  : TestDetailScreenConstants.noTimeLimitLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: test.isTimed
                    ? GeneralConstants.primaryColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
              ),
            ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            TestDetailScreenConstants.createdLabel,
            Icons.calendar_today_outlined,
            child: Text(
              _formatDate(test.createdAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            TestDetailScreenConstants.updatedLabel,
            Icons.update_outlined,
            child: Text(
              _formatDate(test.updatedAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildStatRow(TestModel test, List<TestAttempt> myAttempts) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            test.questionCount.toString(),
            TestDetailScreenConstants.questionsCountLabel,
            Icons.quiz_outlined,
          ),
        ),
        const SizedBox(width: TestDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            test.attemptCount.toString(),
            TestDetailScreenConstants.attemptsCountLabel,
            Icons.people_outline,
          ),
        ),
        const SizedBox(width: TestDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            '${test.averageAccuracy.toStringAsFixed(0)}%',
            TestDetailScreenConstants.avgAccuracyLabel,
            Icons.analytics_outlined,
          ),
        ),
        const SizedBox(width: TestDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            myAttempts.length.toString(),
            TestDetailScreenConstants.yourAttemptsLabel,
            Icons.person_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.secondaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TestDetailScreenConstants.cardBorderRadius,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: GeneralConstants.smallIconSize,
            color: GeneralConstants.secondaryColor,
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: TestDetailScreenConstants.statFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.primaryColor,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: TestDetailScreenConstants.statLabelFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.smallOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(TestModel test) {
    return SizedBox(
      width: double.infinity,
      height: TestDetailScreenConstants.startButtonHeight,
      child: ElevatedButton.icon(
        onPressed: test.questions.isNotEmpty
            ? () => _navigateToTest(test)
            : null,
        icon: const Icon(
          Icons.play_arrow_rounded,
          color: GeneralConstants.backgroundColor,
        ),
        label: Text(
          TestDetailScreenConstants.startTestLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w400,
            color: GeneralConstants.backgroundColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: GeneralConstants.secondaryColor,
          disabledBackgroundColor: GeneralConstants.primaryColor.withValues(
            alpha: 0.2,
          ),
          elevation: GeneralConstants.buttonElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GeneralConstants.mediumCircularRadius,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: TestDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: GeneralConstants.smallSmallIconSize,
                color: GeneralConstants.secondaryColor,
              ),
              const SizedBox(width: GeneralConstants.tinySpacing),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: TestDetailScreenConstants.sectionHeaderFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          child,
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TestDetailScreenConstants.badgeHorizontalPadding,
        vertical: TestDetailScreenConstants.badgeVerticalPadding,
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
          fontSize: TestDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.secondaryColor,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTIONS TAB
  // ---------------------------------------------------------------------------

  Widget _buildQuestionsTab(TestModel test) {
    if (test.questions.isEmpty) {
      return _buildEmptyState(TestDetailScreenConstants.noQuestionsMessage);
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      itemCount: test.questions.length,
      separatorBuilder: (_, __) =>
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
      itemBuilder: (context, index) =>
          _buildQuestionPreviewCard(test.questions[index], index),
    );
  }

  Widget _buildQuestionPreviewCard(TestQuestion question, int index) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: TestDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: TestDetailScreenConstants.questionNumberSize,
                height: TestDetailScreenConstants.questionNumberSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GeneralConstants.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: GeneralConstants.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: GeneralConstants.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: GoogleFonts.lexend(
                        fontSize: GeneralConstants.smallFontSize,
                        fontWeight: FontWeight.w500,
                        color: GeneralConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: GeneralConstants.tinySpacing),
                    _buildQuestionTypeBadge(question.questionType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          ...question.answers.map((a) => _buildAnswerPreview(a)),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeBadge(QuestionType type) {
    final String label;
    final Color color;

    switch (type) {
      case QuestionType.singleChoice:
        label = TestDetailScreenConstants.singleChoiceLabel;
        color = GeneralConstants.secondaryColor;
      case QuestionType.multipleChoice:
        label = TestDetailScreenConstants.multipleChoiceLabel;
        color = GeneralConstants.tertiaryColor;
      case QuestionType.trueFalse:
        label = TestDetailScreenConstants.trueFalseLabel;
        color = GeneralConstants.successColor;
      case QuestionType.fillInTheBlank:
        label = TestDetailScreenConstants.fillInBlankLabel;
        color = Colors.orange;
      case QuestionType.ordering:
        label = TestDetailScreenConstants.orderingLabel;
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TestDetailScreenConstants.badgeHorizontalPadding,
        vertical: TestDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: TestDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAnswerPreview(TestAnswerOption answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            answer.isCorrect
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 16,
            color: answer.isCorrect
                ? GeneralConstants.successColor
                : GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.largeOpacity,
                  ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Text(
              answer.answerText,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize - 1,
                fontWeight: answer.isCorrect
                    ? FontWeight.w500
                    : FontWeight.w300,
                color: answer.isCorrect
                    ? GeneralConstants.primaryColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.smallOpacity,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATISTICS TAB
  // ---------------------------------------------------------------------------

  Widget _buildStatisticsTab(TestModel test) {
    if (test.attempts.isEmpty) {
      return _buildEmptyState(TestDetailScreenConstants.noAttemptsMessage);
    }

    final myAttempts = test.attemptsForUser(_currentUserId);
    final allAttemptsSorted = List<TestAttempt>.from(test.attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final uniqueUserIds = test.attempts.map((a) => a.userId).toSet().toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderboard(test, uniqueUserIds),
          _buildSpacing(height: TestDetailScreenConstants.sectionSpacing),
          if (myAttempts.isNotEmpty) ...[
            _buildSectionLabel(TestDetailScreenConstants.myAttemptsLabel),
            _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
            ...myAttempts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(
                  bottom: TestDetailScreenConstants.fieldSpacing,
                ),
                child: _buildAttemptCard(a, test.questionCount),
              ),
            ),
            _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          ],
          _buildSectionLabel(TestDetailScreenConstants.allAttemptsLabel),
          _buildSpacing(height: TestDetailScreenConstants.fieldSpacing),
          ...allAttemptsSorted.map(
            (a) => Padding(
              padding: const EdgeInsets.only(
                bottom: TestDetailScreenConstants.fieldSpacing,
              ),
              child: _buildAttemptCardWithUser(a, test.questionCount),
            ),
          ),
          _buildSpacing(height: TestDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(TestModel test, List<String> uniqueUserIds) {
    return FutureBuilder<List<UserModel>>(
      future: _userService.getUsersByIds(uniqueUserIds),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final userMap = {for (final u in users) u.id: u};

        final leaderboardEntries = <_LeaderboardEntry>[];
        for (final userId in uniqueUserIds) {
          final userAttempts = test.attemptsForUser(userId);
          if (userAttempts.isEmpty) continue;
          final bestAttempt = userAttempts.reduce(
            (a, b) => a.answerAccuracy >= b.answerAccuracy ? a : b,
          );
          leaderboardEntries.add(
            _LeaderboardEntry(
              userId: userId,
              username: userMap[userId]?.username ?? 'Unknown',
              profilePic: userMap[userId]?.profilePic ?? '',
              bestAccuracy: bestAttempt.answerAccuracy,
              attemptCount: userAttempts.length,
            ),
          );
        }

        leaderboardEntries.sort(
          (a, b) => b.bestAccuracy.compareTo(a.bestAccuracy),
        );

        return Container(
          padding: const EdgeInsets.all(GeneralConstants.smallPadding),
          decoration: BoxDecoration(
            color: GeneralConstants.backgroundColor,
            borderRadius: BorderRadius.circular(
              TestDetailScreenConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: GeneralConstants.primaryColor.withValues(
                alpha: TestDetailScreenConstants.cardBorderOpacity,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.leaderboard_outlined,
                    size: GeneralConstants.smallSmallIconSize,
                    color: GeneralConstants.secondaryColor,
                  ),
                  const SizedBox(width: GeneralConstants.tinySpacing),
                  Text(
                    'Leaderboard',
                    style: GoogleFonts.lexend(
                      fontSize: TestDetailScreenConstants.sectionHeaderFontSize,
                      fontWeight: FontWeight.w500,
                      color: GeneralConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GeneralConstants.smallSpacing),
              ...leaderboardEntries.asMap().entries.map((entry) {
                final rank = entry.key;
                final e = entry.value;
                return _buildLeaderboardRow(rank, e);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardRow(int rank, _LeaderboardEntry entry) {
    Color? medalColor;
    if (rank == 0) medalColor = const Color(0xFFFFD700);
    if (rank == 1) medalColor = const Color(0xFFC0C0C0);
    if (rank == 2) medalColor = const Color(0xFFCD7F32);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medalColor != null
                ? Icon(Icons.emoji_events, color: medalColor, size: 20)
                : Text(
                    '${rank + 1}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w500,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          CircleAvatar(
            radius: 14,
            backgroundColor: GeneralConstants.tertiaryColor,
            backgroundImage: entry.profilePic.isNotEmpty
                ? NetworkImage(entry.profilePic)
                : null,
            child: entry.profilePic.isEmpty
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      color: GeneralConstants.backgroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Text(
              entry.username,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: entry.userId == _currentUserId
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          Text(
            '${entry.attemptCount}x',
            style: GoogleFonts.lexend(
              fontSize: TestDetailScreenConstants.badgeFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.mediumOpacity,
              ),
            ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          _buildAccuracyBadge(entry.bestAccuracy),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(TestAttempt attempt, int totalQuestions) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: TestDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(attempt.completedAt),
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: GeneralConstants.tinySpacing),
                Row(
                  children: [
                    Text(
                      '${attempt.correct} ${TestDetailScreenConstants.correctLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: TestDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      '${attempt.incorrect} ${TestDetailScreenConstants.incorrectLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: TestDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.failureColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      '${attempt.total}/$totalQuestions',
                      style: GoogleFonts.lexend(
                        fontSize: TestDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.primaryColor.withValues(
                          alpha: GeneralConstants.mediumOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildAccuracyBadge(attempt.answerAccuracy),
        ],
      ),
    );
  }

  Widget _buildAttemptCardWithUser(TestAttempt attempt, int totalQuestions) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(attempt.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final username = user?.username ?? 'Unknown';
        final profilePic = user?.profilePic ?? '';

        return Container(
          padding: const EdgeInsets.all(GeneralConstants.smallPadding),
          decoration: BoxDecoration(
            color: GeneralConstants.backgroundColor,
            borderRadius: BorderRadius.circular(
              TestDetailScreenConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: GeneralConstants.primaryColor.withValues(
                alpha: TestDetailScreenConstants.cardBorderOpacity,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: GeneralConstants.tertiaryColor,
                backgroundImage: profilePic.isNotEmpty
                    ? NetworkImage(profilePic)
                    : null,
                child: profilePic.isEmpty
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: GeneralConstants.backgroundColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: GeneralConstants.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                        fontSize: GeneralConstants.smallFontSize,
                        fontWeight: FontWeight.w500,
                        color: GeneralConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: GeneralConstants.tinySpacing),
                    Row(
                      children: [
                        Text(
                          '${attempt.correct}/${attempt.total}',
                          style: GoogleFonts.lexend(
                            fontSize: TestDetailScreenConstants.badgeFontSize,
                            fontWeight: FontWeight.w300,
                            color: GeneralConstants.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: GeneralConstants.smallSpacing),
                        Text(
                          _formatDate(attempt.completedAt),
                          style: GoogleFonts.lexend(
                            fontSize: TestDetailScreenConstants.badgeFontSize,
                            fontWeight: FontWeight.w300,
                            color: GeneralConstants.primaryColor.withValues(
                              alpha: GeneralConstants.mediumOpacity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildAccuracyBadge(attempt.answerAccuracy),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.lexend(
        fontSize: TestDetailScreenConstants.sectionHeaderFontSize,
        fontWeight: FontWeight.w500,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED
  // ---------------------------------------------------------------------------

  Widget _buildAccuracyBadge(double accuracy) {
    final Color color;
    if (accuracy >= 80) {
      color = GeneralConstants.successColor;
    } else if (accuracy >= 50) {
      color = GeneralConstants.tertiaryColor;
    } else {
      color = GeneralConstants.failureColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TestDetailScreenConstants.badgeHorizontalPadding,
        vertical: TestDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        '${accuracy.toStringAsFixed(0)}%',
        style: GoogleFonts.lexend(
          fontSize: TestDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTimeLimit(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (remaining == 0) return '${minutes}m';
    return '${minutes}m ${remaining}s';
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}

class _LeaderboardEntry {
  final String userId;
  final String username;
  final String profilePic;
  final double bestAccuracy;
  final int attemptCount;

  const _LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.bestAccuracy,
    required this.attemptCount,
  });
}
