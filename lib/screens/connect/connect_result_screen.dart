import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/connect/connect_model.dart';
import '../../utils/constants/connect/screens/connect_result_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';
import 'connect_screen.dart';

// Screen for showing the result of the connect game
class ConnectResultScreen extends StatefulWidget {
  const ConnectResultScreen({
    super.key,
    required this.connect,
    required this.correctIds,
    required this.incorrectIds,
  });

  final ConnectModel connect;
  final List<String> correctIds;
  final List<String> incorrectIds;

  @override
  State<ConnectResultScreen> createState() => _ConnectResultScreenState();
}

class _ConnectResultScreenState extends State<ConnectResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _total => widget.connect.pairCount;
  int get _correct => widget.correctIds.length;
  int get _incorrect => widget.incorrectIds.length;
  double get _accuracy => _total == 0 ? 0 : (_correct / _total) * 100;

  List<ConnectPair> get _incorrectPairs => widget.connect.pairs
      .where((p) => widget.incorrectIds.contains(p.id))
      .toList();

  Color get _scoreColor {
    if (_accuracy >= 90) return GeneralConstants.successColor;
    if (_accuracy >= 70) return const Color(0xFF4CAF50);
    if (_accuracy >= 50) return GeneralConstants.tertiaryColor;
    return GeneralConstants.failureColor;
  }

  String get _message {
    if (_accuracy == 100) return ConnectResultScreenConstants.perfectMessage;
    if (_accuracy >= 80) return ConnectResultScreenConstants.greatMessage;
    if (_accuracy >= 60) return ConnectResultScreenConstants.goodMessage;
    if (_accuracy >= 40) return ConnectResultScreenConstants.fairMessage;
    return ConnectResultScreenConstants.poorMessage;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ConnectResultScreenConstants.tabCount,
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
        builder: (_) => ConnectScreen(connect: widget.connect),
      ),
    );
  }

  void _retryIncorrect() {
    if (_incorrectPairs.isEmpty) return;
    final retry = widget.connect.copyWith(pairs: _incorrectPairs);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => ConnectScreen(connect: retry)),
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
        appBar: _appBar(),
        body: Column(
          children: [
            _tabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _summaryTab(),
                  _reviewTab(widget.connect.pairs),
                  _reviewTab(
                    _incorrectPairs,
                    emptyMsg: ConnectResultScreenConstants.noIncorrectMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: GeneralConstants.backgroundColor,
    scrolledUnderElevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: false,
    actions: [
      TextButton(
        onPressed: _onDone,
        child: Text(
          ConnectResultScreenConstants.doneLabel,
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
      ConnectResultScreenConstants.appBarTitle,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.mediumFontSize,
        fontWeight: FontWeight.w300,
        color: GeneralConstants.primaryColor,
      ),
    ),
  );

  Widget _tabs() => Container(
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
        Tab(text: ConnectResultScreenConstants.summaryTab),
        Tab(text: ConnectResultScreenConstants.reviewTab),
        Tab(
          text:
              '${ConnectResultScreenConstants.incorrectOnlyTab} ($_incorrect)',
        ),
      ],
    ),
  );

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
            widget.connect.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.mediumOpacity,
              ),
            ),
          ),
          SizedBox(height: ConnectResultScreenConstants.sectionSpacing),
          _statCards(),
          SizedBox(height: ConnectResultScreenConstants.sectionSpacing),
          _breakdownBar(),
          SizedBox(height: ConnectResultScreenConstants.sectionSpacing),
          _actionBtns(),
          SizedBox(height: ConnectResultScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _scoreCircle() => SizedBox(
    width: ConnectResultScreenConstants.scoreCircleSize,
    height: ConnectResultScreenConstants.scoreCircleSize,
    child: CustomPaint(
      painter: _ScoreCirclePainter(
        progress: _accuracy / 100,
        color: _scoreColor,
        strokeWidth: ConnectResultScreenConstants.scoreCircleStrokeWidth,
        bgColor: GeneralConstants.primaryColor.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_accuracy.toStringAsFixed(0)}%',
              style: GoogleFonts.lexend(
                fontSize: ConnectResultScreenConstants.scoreFontSize,
                fontWeight: FontWeight.w600,
                color: _scoreColor,
              ),
            ),
            Text(
              '$_correct / $_total',
              style: GoogleFonts.lexend(
                fontSize: ConnectResultScreenConstants.scoreLabelFontSize,
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

  Widget _statCards() => Row(
    children: [
      Expanded(
        child: _statCard(
          _correct.toString(),
          ConnectResultScreenConstants.correctLabel,
          Icons.check_circle_outline,
          GeneralConstants.successColor,
        ),
      ),
      SizedBox(width: ConnectResultScreenConstants.fieldSpacing),
      Expanded(
        child: _statCard(
          _incorrect.toString(),
          ConnectResultScreenConstants.incorrectLabel,
          Icons.cancel_outlined,
          GeneralConstants.failureColor,
        ),
      ),
      SizedBox(width: ConnectResultScreenConstants.fieldSpacing),
      Expanded(
        child: _statCard(
          _total.toString(),
          ConnectResultScreenConstants.totalLabel,
          Icons.link,
          GeneralConstants.secondaryColor,
        ),
      ),
    ],
  );

  Widget _statCard(String v, String l, IconData i, Color c) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: GeneralConstants.smallPadding,
      horizontal: GeneralConstants.tinyPadding,
    ),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(
        ConnectResultScreenConstants.cardBorderRadius,
      ),
    ),
    child: Column(
      children: [
        Icon(i, size: ConnectResultScreenConstants.statCardIconSize, color: c),
        const SizedBox(height: GeneralConstants.tinySpacing),
        Text(
          v,
          style: GoogleFonts.lexend(
            fontSize: ConnectResultScreenConstants.statValueFontSize,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
        Text(
          l,
          style: GoogleFonts.lexend(
            fontSize: ConnectResultScreenConstants.statLabelFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor.withValues(
              alpha: GeneralConstants.smallOpacity,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _breakdownBar() => Container(
    padding: const EdgeInsets.all(GeneralConstants.smallPadding),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        ConnectResultScreenConstants.cardBorderRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: ConnectResultScreenConstants.cardBorderOpacity,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pair Breakdown',
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
              '${ConnectResultScreenConstants.correctLabel} ($_correct)',
            ),
            _legendItem(
              GeneralConstants.failureColor,
              '${ConnectResultScreenConstants.incorrectLabel} ($_incorrect)',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _legendItem(Color c, String l) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: GeneralConstants.tinySpacing),
      Text(
        l,
        style: GoogleFonts.lexend(
          fontSize: ConnectResultScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.primaryColor,
        ),
      ),
    ],
  );

  Widget _actionBtns() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: ConnectResultScreenConstants.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: _retryAll,
          icon: const Icon(
            Icons.replay,
            color: GeneralConstants.backgroundColor,
          ),
          label: Text(
            ConnectResultScreenConstants.retryAllLabel,
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
        SizedBox(height: ConnectResultScreenConstants.buttonSpacing),
        SizedBox(
          width: double.infinity,
          height: ConnectResultScreenConstants.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: _retryIncorrect,
            icon: const Icon(
              Icons.refresh,
              color: GeneralConstants.secondaryColor,
            ),
            label: Text(
              '${ConnectResultScreenConstants.retryIncorrectLabel} ($_incorrect)',
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
      SizedBox(height: ConnectResultScreenConstants.buttonSpacing),
      SizedBox(
        width: double.infinity,
        height: ConnectResultScreenConstants.buttonHeight,
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
            ConnectResultScreenConstants.backToDetailLabel,
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

  Widget _reviewTab(List<ConnectPair> pairs, {String? emptyMsg}) {
    if (pairs.isEmpty) {
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
              emptyMsg ?? ConnectResultScreenConstants.noIncorrectMessage,
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
      itemCount: pairs.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: ConnectResultScreenConstants.fieldSpacing),
      itemBuilder: (_, i) {
        final pair = pairs[i];
        final origIdx = widget.connect.pairs.indexOf(pair);
        return _reviewCard(pair, origIdx);
      },
    );
  }

  Widget _reviewCard(ConnectPair pair, int idx) {
    final isCorrect = widget.correctIds.contains(pair.id);
    final Color sc;
    final String sl;
    final IconData si;
    if (isCorrect) {
      sc = GeneralConstants.successColor;
      sl = ConnectResultScreenConstants.correctBadge;
      si = Icons.check_circle;
    } else {
      sc = GeneralConstants.failureColor;
      sl = ConnectResultScreenConstants.incorrectBadge;
      si = Icons.cancel;
    }
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ConnectResultScreenConstants.cardBorderRadius,
        ),
        border: Border.all(color: sc.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ConnectResultScreenConstants.cardNumberSize,
                height: ConnectResultScreenConstants.cardNumberSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
                child: Text(
                  '${idx + 1}',
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: sc,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      ConnectResultScreenConstants.badgeHorizontalPadding,
                  vertical: ConnectResultScreenConstants.badgeVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(si, size: 14, color: sc),
                    const SizedBox(width: GeneralConstants.tinySpacing),
                    Text(
                      sl,
                      style: GoogleFonts.lexend(
                        fontSize: ConnectResultScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w500,
                        color: sc,
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
                ConnectResultScreenConstants.questionSideLabel,
                GeneralConstants.secondaryColor,
              ),
              const SizedBox(width: GeneralConstants.smallSpacing),
              Expanded(
                child: Text(
                  pair.question,
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
                  ConnectResultScreenConstants.answerSideLabel,
                  GeneralConstants.successColor,
                ),
                const SizedBox(width: GeneralConstants.smallSpacing),
                Expanded(
                  child: Text(
                    pair.answer,
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
                            ConnectResultScreenConstants.badgeFontSize - 1,
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

  Widget _sideBadge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      l,
      style: GoogleFonts.lexend(
        fontSize: ConnectResultScreenConstants.badgeFontSize,
        fontWeight: FontWeight.w600,
        color: c,
      ),
    ),
  );
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color bgColor;

  _ScoreCirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) =>
      old.progress != progress || old.color != color;
}
