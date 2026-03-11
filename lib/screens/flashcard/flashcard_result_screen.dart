import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/flashcard/flashcard_model.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/flashcard/screens/flashcard_result_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'flashcard_screen.dart';

// Screen for result of the flashcard quiz
class FlashcardResultScreen extends StatefulWidget {
  const FlashcardResultScreen({
    super.key,
    required this.flashcardSet,
    required this.correctIds,
    required this.incorrectIds,
  });

  final FlashcardSet flashcardSet;
  final List<String> correctIds;
  final List<String> incorrectIds;

  @override
  State<FlashcardResultScreen> createState() => _FlashcardResultScreenState();
}

class _FlashcardResultScreenState extends State<FlashcardResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _total => widget.flashcardSet.cardCount;
  int get _correct => widget.correctIds.length;
  int get _incorrect => widget.incorrectIds.length;
  double get _accuracy => _total == 0 ? 0 : (_correct / _total) * 100;

  List<Flashcard> get _incorrectCards => widget.flashcardSet.cards
      .where((c) => widget.incorrectIds.contains(c.id))
      .toList();

  Color get _scoreColor {
    if (_accuracy >= 90) return GeneralConstants.successColor;
    if (_accuracy >= 70) return const Color(0xFF4CAF50);
    if (_accuracy >= 50) return GeneralConstants.tertiaryColor;
    return GeneralConstants.failureColor;
  }

  String get _message {
    if (_accuracy == 100) return FlashcardResultScreenConstants.perfectMessage;
    if (_accuracy >= 80) return FlashcardResultScreenConstants.greatMessage;
    if (_accuracy >= 60) return FlashcardResultScreenConstants.goodMessage;
    if (_accuracy >= 40) return FlashcardResultScreenConstants.fairMessage;
    return FlashcardResultScreenConstants.poorMessage;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FlashcardResultScreenConstants.tabCount,
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
      MaterialPageRoute<void>(
        builder: (_) => FlashcardScreen(flashcardSet: widget.flashcardSet),
      ),
    );
  }

  void _retryIncorrect() {
    if (_incorrectCards.isEmpty) return;
    final retrySet = widget.flashcardSet.copyWith(cards: _incorrectCards);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FlashcardScreen(flashcardSet: retrySet),
      ),
    );
  }

  void _onDone() => Navigator.pop(context);

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
                  _summaryTab(),
                  _reviewTab(widget.flashcardSet.cards),
                  _reviewTab(
                    _incorrectCards,
                    emptyMessage:
                        FlashcardResultScreenConstants.noIncorrectMessage,
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
            FlashcardResultScreenConstants.doneLabel,
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
        FlashcardResultScreenConstants.appBarTitle,
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
          Tab(text: FlashcardResultScreenConstants.summaryTab),
          Tab(text: FlashcardResultScreenConstants.reviewTab),
          Tab(
            text:
                '${FlashcardResultScreenConstants.incorrectOnlyTab} ($_incorrect)',
          ),
        ],
      ),
    );
  }

  Widget _summaryTab() {
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
          _scoreCircle(),
          const SizedBox(height: GeneralConstants.smallSpacing),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.mediumFontSize,
              fontWeight: FontWeight.w400,
              color: GeneralConstants.primaryColor,
            ),
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            widget.flashcardSet.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.mediumOpacity,
              ),
            ),
          ),
          SizedBox(height: FlashcardResultScreenConstants.sectionSpacing),
          _statCards(),
          SizedBox(height: FlashcardResultScreenConstants.sectionSpacing),
          _breakdownBar(),
          SizedBox(height: FlashcardResultScreenConstants.sectionSpacing),
          _actionButtons(),
          SizedBox(height: FlashcardResultScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _scoreCircle() {
    return SizedBox(
      width: FlashcardResultScreenConstants.scoreCircleSize,
      height: FlashcardResultScreenConstants.scoreCircleSize,
      child: CustomPaint(
        painter: _ScoreCirclePainter(
          progress: _accuracy / 100,
          color: _scoreColor,
          strokeWidth: FlashcardResultScreenConstants.scoreCircleStrokeWidth,
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
                  fontSize: FlashcardResultScreenConstants.scoreFontSize,
                  fontWeight: FontWeight.w600,
                  color: _scoreColor,
                ),
              ),
              Text(
                '$_correct / $_total',
                style: GoogleFonts.lexend(
                  fontSize: FlashcardResultScreenConstants.scoreLabelFontSize,
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

  Widget _statCards() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            _correct.toString(),
            FlashcardResultScreenConstants.correctLabel,
            Icons.check_circle_outline,
            GeneralConstants.successColor,
          ),
        ),
        SizedBox(width: FlashcardResultScreenConstants.fieldSpacing),
        Expanded(
          child: _statCard(
            _incorrect.toString(),
            FlashcardResultScreenConstants.incorrectLabel,
            Icons.cancel_outlined,
            GeneralConstants.failureColor,
          ),
        ),
        SizedBox(width: FlashcardResultScreenConstants.fieldSpacing),
        Expanded(
          child: _statCard(
            _total.toString(),
            FlashcardResultScreenConstants.totalLabel,
            Icons.style_outlined,
            GeneralConstants.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.smallPadding,
        horizontal: GeneralConstants.tinyPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          FlashcardResultScreenConstants.cardBorderRadius,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: FlashcardResultScreenConstants.statCardIconSize,
            color: color,
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            val,
            style: GoogleFonts.lexend(
              fontSize: FlashcardResultScreenConstants.statValueFontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: FlashcardResultScreenConstants.statLabelFontSize,
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

  Widget _breakdownBar() {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardResultScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: FlashcardResultScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Breakdown',
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
                  if (_correct > 0)
                    Flexible(
                      flex: _correct,
                      child: Container(color: GeneralConstants.successColor),
                    ),
                  if (_incorrect > 0)
                    Flexible(
                      flex: _incorrect,
                      child: Container(color: GeneralConstants.failureColor),
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
              _legendItem(
                GeneralConstants.successColor,
                '${FlashcardResultScreenConstants.correctLabel} ($_correct)',
              ),
              _legendItem(
                GeneralConstants.failureColor,
                '${FlashcardResultScreenConstants.incorrectLabel} ($_incorrect)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
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
            fontSize: FlashcardResultScreenConstants.badgeFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: FlashcardResultScreenConstants.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _retryAll,
            icon: const Icon(
              Icons.replay,
              color: GeneralConstants.backgroundColor,
            ),
            label: Text(
              FlashcardResultScreenConstants.retryAllLabel,
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
        if (_incorrect > 0) ...[
          SizedBox(height: FlashcardResultScreenConstants.buttonSpacing),
          SizedBox(
            width: double.infinity,
            height: FlashcardResultScreenConstants.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: _retryIncorrect,
              icon: const Icon(
                Icons.refresh,
                color: GeneralConstants.secondaryColor,
              ),
              label: Text(
                '${FlashcardResultScreenConstants.retryIncorrectLabel} ($_incorrect)',
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
        SizedBox(height: FlashcardResultScreenConstants.buttonSpacing),
        SizedBox(
          width: double.infinity,
          height: FlashcardResultScreenConstants.buttonHeight,
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
              FlashcardResultScreenConstants.backToDetailLabel,
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

  Widget _reviewTab(List<Flashcard> cards, {String? emptyMessage}) {
    if (cards.isEmpty) {
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
              emptyMessage ?? FlashcardResultScreenConstants.noIncorrectMessage,
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
      itemCount: cards.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: FlashcardResultScreenConstants.fieldSpacing),
      itemBuilder: (_, i) {
        final card = cards[i];
        final origIdx = widget.flashcardSet.cards.indexOf(card);
        return _reviewCard(card, origIdx);
      },
    );
  }

  Widget _reviewCard(Flashcard card, int origIdx) {
    final isCorrect = widget.correctIds.contains(card.id);
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isCorrect) {
      statusColor = GeneralConstants.successColor;
      statusLabel = FlashcardResultScreenConstants.correctBadge;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = GeneralConstants.failureColor;
      statusLabel = FlashcardResultScreenConstants.incorrectBadge;
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardResultScreenConstants.cardBorderRadius,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: FlashcardResultScreenConstants.cardNumberSize,
                height: FlashcardResultScreenConstants.cardNumberSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
                child: Text(
                  '${origIdx + 1}',
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      FlashcardResultScreenConstants.badgeHorizontalPadding,
                  vertical: FlashcardResultScreenConstants.badgeVerticalPadding,
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
                        fontSize: FlashcardResultScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          Row(
            children: [
              _sideBadge(
                FlashcardResultScreenConstants.questionSideLabel,
                GeneralConstants.secondaryColor,
              ),
              const SizedBox(width: GeneralConstants.smallSpacing),
              Expanded(
                child: Text(
                  card.question,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GeneralConstants.smallPadding,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isCorrect
                  ? null
                  : GeneralConstants.successColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(
                GeneralConstants.smallCircularRadius,
              ),
            ),
            child: Row(
              children: [
                _sideBadge(
                  FlashcardResultScreenConstants.answerSideLabel,
                  GeneralConstants.successColor,
                ),
                const SizedBox(width: GeneralConstants.smallSpacing),
                Expanded(
                  child: Text(
                    card.answer,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize - 1,
                      fontWeight: FontWeight.w400,
                      color: GeneralConstants.primaryColor,
                    ),
                  ),
                ),
                if (!isCorrect)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: GeneralConstants.successColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Correct answer',
                      style: GoogleFonts.lexend(
                        fontSize:
                            FlashcardResultScreenConstants.badgeFontSize - 1,
                        fontWeight: FontWeight.w400,
                        color: GeneralConstants.successColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: FlashcardResultScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) =>
      old.progress != progress || old.color != color;
}
