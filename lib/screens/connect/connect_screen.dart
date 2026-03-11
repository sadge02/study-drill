import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/connect/connect_model.dart';
import '../../service/connect/connect_service.dart';
import '../../utils/constants/connect/screens/connect_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';
import 'connect_result_screen.dart';

// Screen where user will play the connect game where he connects answer to the question
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.connect});

  final ConnectModel connect;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final ConnectService _service = ConnectService();

  late final List<List<ConnectPair>> _screens;
  int _currentScreen = 0;

  final Map<String, String> _matches = {};
  String? _selectedQuestionId;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isFinished = false;

  late List<ConnectPair> _shuffledQuestions;
  late List<ConnectPair> _shuffledAnswers;

  int get _totalScreens => _screens.length;
  int get _totalPairs => widget.connect.pairCount;
  double get _progress =>
      _totalScreens == 0 ? 0 : (_currentScreen + 1) / _totalScreens;

  @override
  void initState() {
    super.initState();
    _screens = _buildScreens();
    _prepareCurrentScreen();
    if (widget.connect.hasTimeLimit) {
      _remainingSeconds = widget.connect.timeLimit!;
      _startTimer();
    }
  }

  List<List<ConnectPair>> _buildScreens() {
    final dist = widget.connect.questionDistribution;
    final all = List<ConnectPair>.from(widget.connect.pairs);
    final result = <List<ConnectPair>>[];
    int offset = 0;
    for (final count in dist) {
      result.add(all.sublist(offset, offset + count));
      offset += count;
    }
    return result;
  }

  void _prepareCurrentScreen() {
    _shuffledQuestions = List<ConnectPair>.from(_screens[_currentScreen])
      ..shuffle();
    _shuffledAnswers = List<ConnectPair>.from(_screens[_currentScreen])
      ..shuffle();
    _selectedQuestionId = null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        _onTimeUp();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _onTimeUp() {
    if (_isFinished) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          ConnectScreenConstants.timeUpTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          ConnectScreenConstants.timeUpMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finish();
            },
            child: Text(
              ConnectScreenConstants.timeUpConfirm,
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _onQuestionTap(String pairId) {
    if (_matches.containsKey(pairId)) return;
    setState(() => _selectedQuestionId = pairId);
  }

  void _onAnswerTap(String pairId) {
    if (_selectedQuestionId == null) return;
    if (_matches.containsValue(pairId)) return;
    setState(() {
      _matches[_selectedQuestionId!] = pairId;
      _selectedQuestionId = null;
    });
  }

  void _onAnswerDragAccept(String answerPairId, String questionPairId) {
    if (_matches.containsKey(questionPairId)) return;
    if (_matches.containsValue(answerPairId)) return;
    setState(() {
      _matches[questionPairId] = answerPairId;
      _selectedQuestionId = null;
    });
  }

  void _undoMatch(String questionId) {
    setState(() => _matches.remove(questionId));
  }

  bool get _allCurrentMatched {
    for (final pair in _screens[_currentScreen]) {
      if (!_matches.containsKey(pair.id)) return false;
    }
    return true;
  }

  void _goNext() {
    if (!_allCurrentMatched) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            ConnectScreenConstants.incompleteTitle,
            style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
          ),
          content: Text(
            ConnectScreenConstants.incompleteMessage,
            style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                ConnectScreenConstants.incompleteConfirm,
                style: GoogleFonts.lexend(
                  color: GeneralConstants.secondaryColor,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    if (_currentScreen >= _totalScreens - 1) {
      _finish();
      return;
    }
    setState(() {
      _currentScreen++;
      _prepareCurrentScreen();
    });
  }

  void _goPrev() {
    if (_currentScreen <= 0) return;
    setState(() {
      _currentScreen--;
      _prepareCurrentScreen();
    });
  }

  void _finish() async {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();

    final correctIds = <String>[];
    final incorrectIds = <String>[];

    for (final pair in widget.connect.pairs) {
      final matchedTo = _matches[pair.id];
      if (matchedTo == pair.id) {
        correctIds.add(pair.id);
      } else {
        incorrectIds.add(pair.id);
      }
    }

    final attempt = ConnectAttempt(
      id: FirebaseFirestore.instance.collection('_').doc().id,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      correctPairIds: correctIds,
      incorrectPairIds: incorrectIds,
      completedAt: DateTime.now(),
    );

    await _service.addAttempt(widget.connect.id, attempt);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ConnectResultScreen(
          connect: widget.connect,
          correctIds: correctIds,
          incorrectIds: incorrectIds,
        ),
      ),
    );
  }

  void _confirmQuit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ConnectScreenConstants.quitConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          ConnectScreenConstants.quitConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              ConnectScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ConnectScreenConstants.confirmQuitLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  String _fmtTimer(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Utils.isMobile(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: GeneralConstants.backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: isMobile ? 0.96 : 0.6,
                  child: _buildMatchArea(),
                ),
              ),
            ),
            _buildBottomBar(isMobile),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: GeneralConstants.backgroundColor,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.close, color: GeneralConstants.primaryColor),
      onPressed: _confirmQuit,
    ),
    title: Text(
      widget.connect.title,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.mediumFontSize,
        fontWeight: FontWeight.w300,
        color: GeneralConstants.primaryColor,
      ),
    ),
    actions: widget.connect.hasTimeLimit
        ? [
            Padding(
              padding: const EdgeInsets.only(
                right: GeneralConstants.smallMargin,
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GeneralConstants.smallPadding,
                    vertical: GeneralConstants.tinyPadding,
                  ),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 30
                        ? GeneralConstants.failureColor.withValues(alpha: 0.1)
                        : GeneralConstants.secondaryColor.withValues(
                            alpha: 0.08,
                          ),
                    borderRadius: BorderRadius.circular(
                      GeneralConstants.smallCircularRadius,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: GeneralConstants.smallSmallIconSize,
                        color: _remainingSeconds <= 30
                            ? GeneralConstants.failureColor
                            : GeneralConstants.secondaryColor,
                      ),
                      const SizedBox(width: GeneralConstants.tinySpacing),
                      Text(
                        _fmtTimer(_remainingSeconds),
                        style: GoogleFonts.lexend(
                          fontSize: ConnectScreenConstants.timerFontSize,
                          fontWeight: FontWeight.w500,
                          color: _remainingSeconds <= 30
                              ? GeneralConstants.failureColor
                              : GeneralConstants.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
        : null,
  );

  Widget _buildProgress() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: GeneralConstants.mediumMargin,
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${ConnectScreenConstants.screenLabel} ${_currentScreen + 1} ${ConnectScreenConstants.ofLabel} $_totalScreens',
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.counterFontSize,
                fontWeight: FontWeight.w400,
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.smallOpacity,
                ),
              ),
            ),
            Text(
              '${ConnectScreenConstants.matchedLabel}: ${_matches.length}/$_totalPairs',
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.counterFontSize,
                fontWeight: FontWeight.w500,
                color: GeneralConstants.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: GeneralConstants.tinySpacing),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            ConnectScreenConstants.progressBarRadius,
          ),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: ConnectScreenConstants.progressBarHeight,
            backgroundColor: GeneralConstants.primaryColor.withValues(
              alpha: 0.08,
            ),
            valueColor: const AlwaysStoppedAnimation<Color>(
              GeneralConstants.secondaryColor,
            ),
          ),
        ),
        const SizedBox(height: GeneralConstants.tinySpacing),
        Text(
          ConnectScreenConstants.instructionLabel,
          style: GoogleFonts.lexend(
            fontSize: ConnectScreenConstants.counterFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor.withValues(
              alpha: GeneralConstants.mediumOpacity,
            ),
          ),
        ),
        const SizedBox(height: GeneralConstants.smallSpacing),
      ],
    ),
  );

  Widget _buildMatchArea() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.smallMargin,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildQuestionColumn()),
            SizedBox(width: ConnectScreenConstants.columnSpacing),
            Expanded(child: _buildAnswerColumn()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ConnectScreenConstants.questionColumnLabel,
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.columnLabelFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: GeneralConstants.secondaryColor,
              ),
            ),
          ),
        ),
        ..._shuffledQuestions.map((pair) {
          final isMatched = _matches.containsKey(pair.id);
          final isSelected = _selectedQuestionId == pair.id;

          return Padding(
            padding: EdgeInsets.only(
              bottom: ConnectScreenConstants.itemSpacing,
            ),
            child: Draggable<String>(
              data: pair.id,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 160,
                  child: _questionCard(pair, false, true),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: _questionCard(pair, false, false),
              ),
              child: GestureDetector(
                onTap: isMatched
                    ? () => _undoMatch(pair.id)
                    : () => _onQuestionTap(pair.id),
                child: _questionCard(pair, isSelected, isMatched),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _questionCard(ConnectPair pair, bool isSelected, bool isMatched) {
    Color borderColor;
    Color bgColor;
    if (isMatched) {
      borderColor = GeneralConstants.successColor.withValues(alpha: 0.5);
      bgColor = GeneralConstants.successColor.withValues(alpha: 0.06);
    } else if (isSelected) {
      borderColor = GeneralConstants.secondaryColor;
      bgColor = GeneralConstants.secondaryColor.withValues(alpha: 0.08);
    } else {
      borderColor = GeneralConstants.primaryColor.withValues(
        alpha: ConnectScreenConstants.cardBorderOpacity,
      );
      bgColor = GeneralConstants.backgroundColor;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(ConnectScreenConstants.cardPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          ConnectScreenConstants.cardBorderRadius,
        ),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: GeneralConstants.secondaryColor.withValues(
                    alpha: 0.15,
                  ),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              pair.question,
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.cardFontSize,
                fontWeight: FontWeight.w500,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          if (isMatched)
            const Icon(
              Icons.check_circle,
              size: 18,
              color: GeneralConstants.successColor,
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ConnectScreenConstants.answerColumnLabel,
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.columnLabelFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: GeneralConstants.successColor,
              ),
            ),
          ),
        ),
        ..._shuffledAnswers.map((pair) {
          final isMatched = _matches.containsValue(pair.id);

          return Padding(
            padding: EdgeInsets.only(
              bottom: ConnectScreenConstants.itemSpacing,
            ),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) =>
                  !isMatched && !_matches.containsKey(details.data),
              onAcceptWithDetails: (details) =>
                  _onAnswerDragAccept(pair.id, details.data),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return GestureDetector(
                  onTap: isMatched ? null : () => _onAnswerTap(pair.id),
                  child: _answerCard(pair, isMatched, isHovering),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _answerCard(ConnectPair pair, bool isMatched, bool isHovering) {
    Color borderColor;
    Color bgColor;
    if (isMatched) {
      borderColor = GeneralConstants.successColor.withValues(alpha: 0.5);
      bgColor = GeneralConstants.successColor.withValues(alpha: 0.06);
    } else if (isHovering) {
      borderColor = GeneralConstants.tertiaryColor;
      bgColor = GeneralConstants.tertiaryColor.withValues(alpha: 0.08);
    } else {
      borderColor = GeneralConstants.primaryColor.withValues(
        alpha: ConnectScreenConstants.cardBorderOpacity,
      );
      bgColor = GeneralConstants.backgroundColor;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(ConnectScreenConstants.cardPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          ConnectScreenConstants.cardBorderRadius,
        ),
        border: Border.all(color: borderColor, width: isHovering ? 2 : 1),
      ),
      child: Row(
        children: [
          if (isMatched)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: GeneralConstants.successColor,
              ),
            ),
          Expanded(
            child: Text(
              pair.answer,
              style: GoogleFonts.lexend(
                fontSize: ConnectScreenConstants.cardFontSize,
                fontWeight: isMatched ? FontWeight.w500 : FontWeight.w400,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isMobile) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile
          ? GeneralConstants.mediumMargin
          : MediaQuery.of(context).size.width * 0.2,
      vertical: GeneralConstants.smallPadding,
    ),
    decoration: BoxDecoration(
      color: GeneralConstants.backgroundColor,
      border: Border(
        top: BorderSide(
          color: GeneralConstants.primaryColor.withValues(alpha: 0.08),
        ),
      ),
    ),
    child: SafeArea(
      child: Row(
        children: [
          if (_currentScreen > 0)
            Expanded(
              child: SizedBox(
                height: ConnectScreenConstants.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: _goPrev,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: GeneralConstants.secondaryColor,
                  ),
                  label: Text(
                    ConnectScreenConstants.previousScreenLabel,
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
          SizedBox(width: ConnectScreenConstants.buttonSpacing),
          Expanded(
            child: SizedBox(
              height: ConnectScreenConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _goNext,
                icon: Icon(
                  _currentScreen >= _totalScreens - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                  color: GeneralConstants.backgroundColor,
                ),
                label: Text(
                  _currentScreen >= _totalScreens - 1
                      ? 'Submit'
                      : ConnectScreenConstants.nextScreenLabel,
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
    ),
  );
}
