import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/test/test_model.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/test/screens/test_result_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'test_screen.dart';

class TestResultScreen extends StatefulWidget {
  const TestResultScreen({
    super.key,
    required this.test,
    required this.correctIds,
    required this.incorrectIds,
  });

  final TestModel test;
  final List<String> correctIds;
  final List<String> incorrectIds;

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _totalQuestions => widget.test.questionCount;
  int get _correctCount => widget.correctIds.length;
  int get _incorrectCount => widget.incorrectIds.length;
  int get _skippedCount => _totalQuestions - _correctCount - _incorrectCount;
  double get _accuracy =>
      _totalQuestions == 0 ? 0 : (_correctCount / _totalQuestions) * 100;

  List<TestQuestion> get _incorrectQuestions => widget.test.questions
      .where((q) => widget.incorrectIds.contains(q.id))
      .toList();

  List<TestQuestion> get _skippedQuestions => widget.test.questions
      .where(
        (q) =>
            !widget.correctIds.contains(q.id) &&
            !widget.incorrectIds.contains(q.id),
      )
      .toList();

  Color get _scoreColor {
    if (_accuracy >= 90) return GeneralConstants.successColor;
    if (_accuracy >= 70) return const Color(0xFF4CAF50);
    if (_accuracy >= 50) return GeneralConstants.tertiaryColor;
    return GeneralConstants.failureColor;
  }

  String get _performanceMessage {
    if (_accuracy == 100) return TestResultScreenConstants.perfectMessage;
    if (_accuracy >= 80) return TestResultScreenConstants.greatMessage;
    if (_accuracy >= 60) return TestResultScreenConstants.goodMessage;
    if (_accuracy >= 40) return TestResultScreenConstants.fairMessage;
    return TestResultScreenConstants.poorMessage;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TestResultScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _retryAll() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => TestScreen(test: widget.test)),
    );
  }

  void _retryIncorrect() {
    final incorrectAndSkipped = [..._incorrectQuestions, ..._skippedQuestions];
    if (incorrectAndSkipped.isEmpty) return;

    final retryTest = widget.test.copyWith(questions: incorrectAndSkipped);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => TestScreen(test: retryTest)),
    );
  }

  void _onDone() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onDone();
      },
      child: Scaffold(
        backgroundColor: GeneralConstants.backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildReviewTab(widget.test.questions),
                  _buildReviewTab(
                    [..._incorrectQuestions, ..._skippedQuestions],
                    emptyMessage: TestResultScreenConstants.noIncorrectMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GeneralConstants.backgroundColor,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        TextButton(
          onPressed: _onDone,
          child: Text(
            TestResultScreenConstants.doneLabel,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.secondaryColor,
            ),
          ),
        ),
        const SizedBox(width: GeneralConstants.smallMargin),
      ],
      title: Text(
        TestResultScreenConstants.appBarTitle,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.mediumFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.primaryColor,
        ),
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
        tabs: [
          Tab(text: TestResultScreenConstants.summaryTab),
          Tab(text: TestResultScreenConstants.reviewTab),
          Tab(
            text:
                '${TestResultScreenConstants.incorrectOnlyTab} (${_incorrectCount + _skippedCount})',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY TAB
  // ---------------------------------------------------------------------------

  Widget _buildSummaryTab() {
    final isMobile = Utils.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? GeneralConstants.mediumMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.mediumMargin,
      ),
      child: Column(
        children: [
          _buildScoreCircle(),
          const SizedBox(height: GeneralConstants.smallSpacing),
          Text(
            _performanceMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.mediumFontSize,
              fontWeight: FontWeight.w400,
              color: GeneralConstants.primaryColor,
            ),
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            widget.test.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.mediumOpacity,
              ),
            ),
          ),
          SizedBox(height: TestResultScreenConstants.sectionSpacing),
          _buildStatCards(),
          SizedBox(height: TestResultScreenConstants.sectionSpacing),
          _buildQuestionBreakdownBar(),
          SizedBox(height: TestResultScreenConstants.sectionSpacing),
          _buildActionButtons(),
          SizedBox(height: TestResultScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildScoreCircle() {
    return SizedBox(
      width: TestResultScreenConstants.scoreCircleSize,
      height: TestResultScreenConstants.scoreCircleSize,
      child: CustomPaint(
        painter: _ScoreCirclePainter(
          progress: _accuracy / 100,
          color: _scoreColor,
          strokeWidth: TestResultScreenConstants.scoreCircleStrokeWidth,
          backgroundColor: GeneralConstants.primaryColor.withValues(
            alpha: 0.08,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_accuracy.toStringAsFixed(0)}%',
                style: GoogleFonts.lexend(
                  fontSize: TestResultScreenConstants.scoreFontSize,
                  fontWeight: FontWeight.w600,
                  color: _scoreColor,
                ),
              ),
              Text(
                '$_correctCount / $_totalQuestions',
                style: GoogleFonts.lexend(
                  fontSize: TestResultScreenConstants.scoreLabelFontSize,
                  fontWeight: FontWeight.w300,
                  color: GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.mediumOpacity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _correctCount.toString(),
            TestResultScreenConstants.correctLabel,
            Icons.check_circle_outline,
            GeneralConstants.successColor,
          ),
        ),
        SizedBox(width: TestResultScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            _incorrectCount.toString(),
            TestResultScreenConstants.incorrectLabel,
            Icons.cancel_outlined,
            GeneralConstants.failureColor,
          ),
        ),
        SizedBox(width: TestResultScreenConstants.fieldSpacing),
        if (_skippedCount > 0) ...[
          Expanded(
            child: _buildStatCard(
              _skippedCount.toString(),
              TestResultScreenConstants.skippedLabel,
              Icons.remove_circle_outline,
              Colors.orange,
            ),
          ),
          SizedBox(width: TestResultScreenConstants.fieldSpacing),
        ],
        Expanded(
          child: _buildStatCard(
            _totalQuestions.toString(),
            TestResultScreenConstants.totalLabel,
            Icons.quiz_outlined,
            GeneralConstants.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.smallPadding,
        horizontal: GeneralConstants.tinyPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TestResultScreenConstants.cardBorderRadius,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: TestResultScreenConstants.statCardIconSize,
            color: color,
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: TestResultScreenConstants.statValueFontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: TestResultScreenConstants.statLabelFontSize,
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

  Widget _buildQuestionBreakdownBar() {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestResultScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: TestResultScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Breakdown',
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.primaryColor,
            ),
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (_correctCount > 0)
                    Flexible(
                      flex: _correctCount,
                      child: Container(color: GeneralConstants.successColor),
                    ),
                  if (_incorrectCount > 0)
                    Flexible(
                      flex: _incorrectCount,
                      child: Container(color: GeneralConstants.failureColor),
                    ),
                  if (_skippedCount > 0)
                    Flexible(
                      flex: _skippedCount,
                      child: Container(color: Colors.orange),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          Wrap(
            spacing: GeneralConstants.mediumSpacing,
            runSpacing: GeneralConstants.tinySpacing,
            children: [
              _buildLegendItem(
                GeneralConstants.successColor,
                '${TestResultScreenConstants.correctLabel} ($_correctCount)',
              ),
              _buildLegendItem(
                GeneralConstants.failureColor,
                '${TestResultScreenConstants.incorrectLabel} ($_incorrectCount)',
              ),
              if (_skippedCount > 0)
                _buildLegendItem(
                  Colors.orange,
                  '${TestResultScreenConstants.skippedLabel} ($_skippedCount)',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: GeneralConstants.tinySpacing),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: TestResultScreenConstants.badgeFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: TestResultScreenConstants.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _retryAll,
            icon: const Icon(
              Icons.replay,
              color: GeneralConstants.backgroundColor,
            ),
            label: Text(
              TestResultScreenConstants.retryAllLabel,
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
        if (_incorrectCount + _skippedCount > 0) ...[
          SizedBox(height: TestResultScreenConstants.buttonSpacing),
          SizedBox(
            width: double.infinity,
            height: TestResultScreenConstants.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: _retryIncorrect,
              icon: const Icon(
                Icons.refresh,
                color: GeneralConstants.secondaryColor,
              ),
              label: Text(
                '${TestResultScreenConstants.retryIncorrectLabel} (${_incorrectCount + _skippedCount})',
                style: GoogleFonts.lexend(
                  fontSize: GeneralConstants.smallFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.secondaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GeneralConstants.secondaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.mediumCircularRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: TestResultScreenConstants.buttonSpacing),
        SizedBox(
          width: double.infinity,
          height: TestResultScreenConstants.buttonHeight,
          child: OutlinedButton(
            onPressed: _onDone,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.largeOpacity,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  GeneralConstants.mediumCircularRadius,
                ),
              ),
            ),
            child: Text(
              TestResultScreenConstants.backToDetailLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w400,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildReviewTab(List<TestQuestion> questions, {String? emptyMessage}) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: GeneralConstants.largeIconSize,
              color: GeneralConstants.successColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: GeneralConstants.smallSpacing),
            Text(
              emptyMessage ?? TestResultScreenConstants.noIncorrectMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.mediumOpacity,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      itemCount: questions.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: TestResultScreenConstants.fieldSpacing),
      itemBuilder: (context, index) {
        final question = questions[index];
        final originalIndex = widget.test.questions.indexOf(question);
        return _buildReviewCard(question, originalIndex);
      },
    );
  }

  Widget _buildReviewCard(TestQuestion question, int originalIndex) {
    final isCorrect = widget.correctIds.contains(question.id);
    final isIncorrect = widget.incorrectIds.contains(question.id);
    final isSkipped = !isCorrect && !isIncorrect;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isCorrect) {
      statusColor = GeneralConstants.successColor;
      statusLabel = TestResultScreenConstants.correctBadge;
      statusIcon = Icons.check_circle;
    } else if (isIncorrect) {
      statusColor = GeneralConstants.failureColor;
      statusLabel = TestResultScreenConstants.incorrectBadge;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusLabel = TestResultScreenConstants.skippedLabel;
      statusIcon = Icons.remove_circle;
    }

    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestResultScreenConstants.cardBorderRadius,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewCardHeader(
            originalIndex,
            statusColor,
            statusLabel,
            statusIcon,
            question.questionType,
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          Text(
            question.question,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.primaryColor,
            ),
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          ...question.answers.map(
            (a) => _buildReviewAnswerRow(a, question, isCorrect, isSkipped),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCardHeader(
    int originalIndex,
    Color statusColor,
    String statusLabel,
    IconData statusIcon,
    QuestionType type,
  ) {
    return Row(
      children: [
        Container(
          width: TestResultScreenConstants.questionNumberSize,
          height: TestResultScreenConstants.questionNumberSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              GeneralConstants.smallCircularRadius,
            ),
          ),
          child: Text(
            '${originalIndex + 1}',
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        _buildQuestionTypeBadge(type),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TestResultScreenConstants.badgeHorizontalPadding,
            vertical: TestResultScreenConstants.badgeVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              GeneralConstants.smallCircularRadius,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: GeneralConstants.tinySpacing),
              Text(
                statusLabel,
                style: GoogleFonts.lexend(
                  fontSize: TestResultScreenConstants.badgeFontSize,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeBadge(QuestionType type) {
    final String label;
    final Color color;

    switch (type) {
      case QuestionType.singleChoice:
        label = 'Single';
        color = GeneralConstants.secondaryColor;
      case QuestionType.multipleChoice:
        label = 'Multiple';
        color = GeneralConstants.tertiaryColor;
      case QuestionType.trueFalse:
        label = 'T/F';
        color = GeneralConstants.successColor;
      case QuestionType.fillInTheBlank:
        label = 'Fill';
        color = Colors.orange;
      case QuestionType.ordering:
        label = 'Order';
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: TestResultScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReviewAnswerRow(
    TestAnswerOption answer,
    TestQuestion question,
    bool questionCorrect,
    bool questionSkipped,
  ) {
    final bool isTheCorrectAnswer = answer.isCorrect;

    final Color iconColor;
    final IconData icon;

    if (isTheCorrectAnswer) {
      iconColor = GeneralConstants.successColor;
      icon = Icons.check_circle;
    } else {
      iconColor = GeneralConstants.primaryColor.withValues(
        alpha: GeneralConstants.largeOpacity,
      );
      icon = Icons.radio_button_unchecked;
    }

    final Color? rowBackground;
    if (isTheCorrectAnswer && !questionCorrect) {
      rowBackground = GeneralConstants.successColor.withValues(alpha: 0.06);
    } else {
      rowBackground = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.smallPadding,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Text(
              answer.answerText,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize - 1,
                fontWeight: isTheCorrectAnswer
                    ? FontWeight.w500
                    : FontWeight.w300,
                color: isTheCorrectAnswer
                    ? GeneralConstants.primaryColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.smallOpacity,
                      ),
              ),
            ),
          ),
          if (isTheCorrectAnswer && !questionCorrect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: GeneralConstants.successColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                TestResultScreenConstants.correctAnswerLabel,
                style: GoogleFonts.lexend(
                  fontSize: TestResultScreenConstants.badgeFontSize - 1,
                  fontWeight: FontWeight.w400,
                  color: GeneralConstants.successColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _ScoreCirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
