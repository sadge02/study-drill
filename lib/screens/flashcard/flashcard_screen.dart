import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/flashcard/flashcard_model.dart';
import '../../service/flashcard/flashcard_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/flashcard/screens/flashcard_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'flashcard_result_screen.dart';

// Screen for taking the flashcard quiz
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.flashcardSet});

  final FlashcardSet flashcardSet;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final FlashcardService _service = FlashcardService();

  int _currentIndex = 0;
  bool _showAnswer = false;

  final List<String> _correctIds = [];
  final List<String> _incorrectIds = [];

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isFinished = false;

  List<Flashcard> get _cards => widget.flashcardSet.cards;
  int get _total => _cards.length;
  double get _progress => _total == 0 ? 0 : (_currentIndex + 1) / _total;

  @override
  void initState() {
    super.initState();
    if (widget.flashcardSet.hasTimeLimit) {
      _remainingSeconds = widget.flashcardSet.timeLimit!;
      _startTimer();
    }
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
          FlashcardScreenConstants.timeUpTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          FlashcardScreenConstants.timeUpMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishSession();
            },
            child: Text(
              FlashcardScreenConstants.timeUpConfirm,
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _onShowAnswer() {
    setState(() => _showAnswer = true);
  }

  void _onGotIt() {
    _correctIds.add(_cards[_currentIndex].id);
    _advance();
  }

  void _onMissedIt() {
    _incorrectIds.add(_cards[_currentIndex].id);
    _advance();
  }

  void _advance() {
    if (_currentIndex >= _total - 1) {
      _finishSession();
      return;
    }
    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }

  void _finishSession() async {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();

    final attempt = FlashcardAttempt(
      id: FirebaseFirestore.instance.collection('_').doc().id,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      correctCardIds: List<String>.from(_correctIds),
      incorrectCardIds: List<String>.from(_incorrectIds),
      completedAt: DateTime.now(),
    );

    await _service.addAttempt(widget.flashcardSet.id, attempt);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FlashcardResultScreen(
          flashcardSet: widget.flashcardSet,
          correctIds: _correctIds,
          incorrectIds: _incorrectIds,
        ),
      ),
    );
  }

  void _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          FlashcardScreenConstants.quitConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          FlashcardScreenConstants.quitConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              FlashcardScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              FlashcardScreenConstants.confirmQuitLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
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
                  widthFactor: isMobile ? 0.92 : 0.5,
                  child: _buildCardArea(),
                ),
              ),
            ),
            _buildButtons(isMobile),
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
      leading: IconButton(
        icon: const Icon(Icons.close, color: GeneralConstants.primaryColor),
        onPressed: _confirmQuit,
      ),
      title: Text(
        widget.flashcardSet.title,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.mediumFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.primaryColor,
        ),
      ),
      actions: widget.flashcardSet.hasTimeLimit
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
                            fontSize: FlashcardScreenConstants.timerFontSize,
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
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.mediumMargin,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${FlashcardScreenConstants.cardLabel} ${_currentIndex + 1} ${FlashcardScreenConstants.ofLabel} $_total',
                style: GoogleFonts.lexend(
                  fontSize: FlashcardScreenConstants.counterFontSize,
                  fontWeight: FontWeight.w400,
                  color: GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.smallOpacity,
                  ),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.lexend(
                  fontSize: FlashcardScreenConstants.counterFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              FlashcardScreenConstants.progressBarRadius,
            ),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: FlashcardScreenConstants.progressBarHeight,
              backgroundColor: GeneralConstants.primaryColor.withValues(
                alpha: 0.08,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(
                GeneralConstants.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
        ],
      ),
    );
  }

  Widget _buildCardArea() {
    final card = _cards[_currentIndex];

    return GestureDetector(
      onTap: _showAnswer ? null : _onShowAnswer,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Container(
          key: ValueKey<String>('${_currentIndex}_${_showAnswer ? 'a' : 'q'}'),
          width: double.infinity,
          padding: const EdgeInsets.all(GeneralConstants.largePadding),
          decoration: BoxDecoration(
            color: _showAnswer
                ? GeneralConstants.secondaryColor.withValues(alpha: 0.04)
                : GeneralConstants.backgroundColor,
            borderRadius: BorderRadius.circular(
              FlashcardScreenConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: _showAnswer
                  ? GeneralConstants.secondaryColor.withValues(alpha: 0.25)
                  : GeneralConstants.primaryColor.withValues(
                      alpha: FlashcardScreenConstants.cardBorderOpacity,
                    ),
            ),
            boxShadow: [
              BoxShadow(
                color: GeneralConstants.primaryColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      (_showAnswer
                              ? GeneralConstants.successColor
                              : GeneralConstants.secondaryColor)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
                child: Text(
                  _showAnswer
                      ? FlashcardScreenConstants.answerSideLabel
                      : FlashcardScreenConstants.questionSideLabel,
                  style: GoogleFonts.lexend(
                    fontSize: FlashcardScreenConstants.cardSideLabelFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: _showAnswer
                        ? GeneralConstants.successColor
                        : GeneralConstants.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: GeneralConstants.mediumSpacing),
              Text(
                _showAnswer ? card.answer : card.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: _showAnswer
                      ? FlashcardScreenConstants.cardAnswerFontSize
                      : FlashcardScreenConstants.cardQuestionFontSize,
                  fontWeight: _showAnswer ? FontWeight.w400 : FontWeight.w500,
                  color: GeneralConstants.primaryColor,
                ),
              ),
              if (!_showAnswer) ...[
                const SizedBox(height: GeneralConstants.mediumSpacing),
                Text(
                  FlashcardScreenConstants.tapToRevealLabel,
                  style: GoogleFonts.lexend(
                    fontSize: FlashcardScreenConstants.counterFontSize,
                    fontWeight: FontWeight.w300,
                    color: GeneralConstants.primaryColor.withValues(
                      alpha: GeneralConstants.largeOpacity,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? GeneralConstants.mediumMargin
            : MediaQuery.of(context).size.width * 0.225,
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
        child: _showAnswer
            ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: FlashcardScreenConstants.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: _onMissedIt,
                        icon: const Icon(
                          Icons.close,
                          color: GeneralConstants.backgroundColor,
                        ),
                        label: Text(
                          FlashcardScreenConstants.missedItLabel,
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: GeneralConstants.backgroundColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GeneralConstants.failureColor,
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
                  SizedBox(width: FlashcardScreenConstants.buttonSpacing),
                  Expanded(
                    child: SizedBox(
                      height: FlashcardScreenConstants.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: _onGotIt,
                        icon: const Icon(
                          Icons.check,
                          color: GeneralConstants.backgroundColor,
                        ),
                        label: Text(
                          FlashcardScreenConstants.gotItLabel,
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: GeneralConstants.backgroundColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GeneralConstants.successColor,
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
              )
            : SizedBox(
                width: double.infinity,
                height: FlashcardScreenConstants.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _onShowAnswer,
                  icon: const Icon(
                    Icons.visibility,
                    color: GeneralConstants.backgroundColor,
                  ),
                  label: Text(
                    FlashcardScreenConstants.showAnswerLabel,
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
    );
  }
}
