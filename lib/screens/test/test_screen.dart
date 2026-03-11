import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/test/test_model.dart';
import '../../service/test/test_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/test/screens/test_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'test_result_screen.dart';

// Screen for when user is taking a test
class TestScreen extends StatefulWidget {
  const TestScreen({super.key, required this.test});

  final TestModel test;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TestService _testService = TestService();
  late final PageController _pageController;

  int _currentPage = 0;

  final Map<int, Set<String>> _selectedAnswerIds = {};
  final Map<int, String> _fillInBlankAnswers = {};

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitted = false;

  List<TestQuestion> get _questions => widget.test.questions;

  int get _totalQuestions => _questions.length;

  double get _progress =>
      _totalQuestions == 0 ? 0 : (_currentPage + 1) / _totalQuestions;

  int get _unansweredCount {
    int count = 0;
    for (int i = 0; i < _totalQuestions; i++) {
      final q = _questions[i];
      if (q.questionType == QuestionType.fillInTheBlank) {
        if ((_fillInBlankAnswers[i] ?? '').trim().isEmpty) count++;
      } else {
        if ((_selectedAnswerIds[i] ?? {}).isEmpty) count++;
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.test.isTimed) {
      _remainingSeconds = widget.test.timeLimit!;
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
    if (_isSubmitted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          TestScreenConstants.timeUpTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          TestScreenConstants.timeUpMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: Text(
              TestScreenConstants.timeUpConfirm,
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentPage < _totalQuestions - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _onPrevious() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _onAnswerSelected(int questionIndex, String answerId) {
    setState(() {
      final q = _questions[questionIndex];
      final selected = _selectedAnswerIds.putIfAbsent(questionIndex, () => {});

      if (q.questionType == QuestionType.singleChoice ||
          q.questionType == QuestionType.trueFalse) {
        selected.clear();
        selected.add(answerId);
      } else {
        if (selected.contains(answerId)) {
          selected.remove(answerId);
        } else {
          selected.add(answerId);
        }
      }
    });
  }

  void _onFillInBlankChanged(int questionIndex, String value) {
    _fillInBlankAnswers[questionIndex] = value;
  }

  void _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          TestScreenConstants.quitConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          TestScreenConstants.quitConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              TestScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              TestScreenConstants.confirmQuitLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmSubmit() async {
    final unanswered = _unansweredCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          TestScreenConstants.submitConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          unanswered > 0
              ? '$unanswered ${TestScreenConstants.unansweredWarning}'
              : TestScreenConstants.submitConfirmMessage,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w300,
            color: unanswered > 0
                ? GeneralConstants.failureColor
                : GeneralConstants.primaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              TestScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              TestScreenConstants.confirmSubmitLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _submitTest();
    }
  }

  void _submitTest() async {
    if (_isSubmitted) return;
    _isSubmitted = true;
    _timer?.cancel();

    final List<String> correctIds = [];
    final List<String> incorrectIds = [];

    for (int i = 0; i < _totalQuestions; i++) {
      final q = _questions[i];
      bool isCorrect;

      if (q.questionType == QuestionType.fillInTheBlank) {
        final userAnswer = (_fillInBlankAnswers[i] ?? '').trim().toLowerCase();
        final correctAnswer = q.answers
            .firstWhere((a) => a.isCorrect)
            .answerText
            .trim()
            .toLowerCase();
        isCorrect = userAnswer == correctAnswer;
      } else {
        final selected = _selectedAnswerIds[i] ?? {};
        final correctSet = q.correctAnswerIds.toSet();
        isCorrect =
            selected.length == correctSet.length &&
            selected.containsAll(correctSet);
      }

      if (isCorrect) {
        correctIds.add(q.id);
      } else {
        incorrectIds.add(q.id);
      }
    }

    final attempt = TestAttempt(
      id: FirebaseFirestore.instance.collection('_').doc().id,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      correctQuestionIds: correctIds,
      incorrectQuestionIds: incorrectIds,
      completedAt: DateTime.now(),
    );

    await _testService.addAttempt(widget.test.id, attempt);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TestResultScreen(
          test: widget.test,
          correctIds: correctIds,
          incorrectIds: incorrectIds,
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
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
            _buildProgressSection(),
            Expanded(
              child: isMobile
                  ? _buildPageView(0.92)
                  : Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        child: _buildPageViewContent(),
                      ),
                    ),
            ),
            _buildNavigationBar(isMobile),
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
        widget.test.title,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.mediumFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.primaryColor,
        ),
      ),
      actions: widget.test.isTimed
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
                          _formatTimer(_remainingSeconds),
                          style: GoogleFonts.lexend(
                            fontSize: TestScreenConstants.timerFontSize,
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

  Widget _buildProgressSection() {
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
                '${TestScreenConstants.questionLabel} ${_currentPage + 1} ${TestScreenConstants.ofLabel} $_totalQuestions',
                style: GoogleFonts.lexend(
                  fontSize: TestScreenConstants.counterFontSize,
                  fontWeight: FontWeight.w400,
                  color: GeneralConstants.primaryColor.withValues(
                    alpha: GeneralConstants.smallOpacity,
                  ),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.lexend(
                  fontSize: TestScreenConstants.counterFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              TestScreenConstants.progressBarRadius,
            ),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: TestScreenConstants.progressBarHeight,
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

  Widget _buildPageView(double widthFactor) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: _buildPageViewContent(),
      ),
    );
  }

  Widget _buildPageViewContent() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _totalQuestions,
      onPageChanged: (page) => setState(() => _currentPage = page),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) => _buildQuestionPage(index),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.smallMargin,
        vertical: GeneralConstants.smallMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTypeBadge(question.questionType),
          const SizedBox(height: TestScreenConstants.sectionSpacing),
          Text(
            question.question,
            style: GoogleFonts.lexend(
              fontSize: TestScreenConstants.questionFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.primaryColor,
            ),
          ),
          const SizedBox(height: TestScreenConstants.sectionSpacing),
          _buildQuestionHint(question.questionType),
          const SizedBox(height: GeneralConstants.smallSpacing),
          if (question.questionType == QuestionType.fillInTheBlank)
            _buildFillInBlankInput(index)
          else
            ..._buildAnswerOptions(index, question),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeBadge(QuestionType type) {
    final String label;
    final Color color;

    switch (type) {
      case QuestionType.singleChoice:
        label = 'Single Choice';
        color = GeneralConstants.secondaryColor;
      case QuestionType.multipleChoice:
        label = 'Multiple Choice';
        color = GeneralConstants.tertiaryColor;
      case QuestionType.trueFalse:
        label = 'True / False';
        color = GeneralConstants.successColor;
      case QuestionType.fillInTheBlank:
        label = 'Fill in the Blank';
        color = Colors.orange;
      case QuestionType.ordering:
        label = 'Ordering';
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: TestScreenConstants.counterFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuestionHint(QuestionType type) {
    final String hint;
    switch (type) {
      case QuestionType.singleChoice:
        hint = TestScreenConstants.singleChoiceHint;
      case QuestionType.multipleChoice:
        hint = TestScreenConstants.multipleChoiceHint;
      case QuestionType.trueFalse:
        hint = TestScreenConstants.trueFalseHint;
      case QuestionType.fillInTheBlank:
        hint = TestScreenConstants.fillInBlankHint;
      case QuestionType.ordering:
        hint = TestScreenConstants.orderingHint;
    }

    return Text(
      hint,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        fontWeight: FontWeight.w300,
        color: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.mediumOpacity,
        ),
      ),
    );
  }

  List<Widget> _buildAnswerOptions(int questionIndex, TestQuestion question) {
    final selected = _selectedAnswerIds[questionIndex] ?? {};

    return question.answers.asMap().entries.map((entry) {
      final answer = entry.value;
      final isSelected = selected.contains(answer.id);

      return Padding(
        padding: EdgeInsets.only(bottom: TestScreenConstants.answerSpacing),
        child: _buildAnswerCard(
          questionIndex,
          answer,
          isSelected,
          question.questionType,
        ),
      );
    }).toList();
  }

  Widget _buildAnswerCard(
    int questionIndex,
    TestAnswerOption answer,
    bool isSelected,
    QuestionType type,
  ) {
    return GestureDetector(
      onTap: () => _onAnswerSelected(questionIndex, answer.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(GeneralConstants.smallPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? GeneralConstants.secondaryColor.withValues(
                  alpha: TestScreenConstants.answerCardSelectedOpacity,
                )
              : GeneralConstants.backgroundColor,
          borderRadius: BorderRadius.circular(
            TestScreenConstants.answerCardRadius,
          ),
          border: Border.all(
            color: isSelected
                ? GeneralConstants.secondaryColor
                : GeneralConstants.primaryColor.withValues(
                    alpha: TestScreenConstants.answerCardBorderOpacity,
                  ),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildSelectionIndicator(isSelected, type),
            const SizedBox(width: GeneralConstants.smallSpacing),
            Expanded(
              child: Text(
                answer.answerText,
                style: GoogleFonts.lexend(
                  fontSize: GeneralConstants.smallFontSize,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  color: isSelected
                      ? GeneralConstants.secondaryColor
                      : GeneralConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(bool isSelected, QuestionType type) {
    final isCheckbox = type == QuestionType.multipleChoice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected
            ? GeneralConstants.secondaryColor
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? GeneralConstants.secondaryColor
              : GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.largeOpacity,
                ),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(isCheckbox ? 4 : 11),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 14,
              color: GeneralConstants.backgroundColor,
            )
          : null,
    );
  }

  Widget _buildFillInBlankInput(int questionIndex) {
    return TextFormField(
      initialValue: _fillInBlankAnswers[questionIndex] ?? '',
      onChanged: (val) => _onFillInBlankChanged(questionIndex, val),
      maxLines: TestScreenConstants.fillInBlankMaxLines.toInt(),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: TestScreenConstants.fillInBlankHint,
        hintStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
        filled: true,
        fillColor: GeneralConstants.tertiaryColor.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TestScreenConstants.answerCardRadius,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TestScreenConstants.answerCardRadius,
          ),
          borderSide: const BorderSide(color: GeneralConstants.secondaryColor),
        ),
        contentPadding: const EdgeInsets.all(GeneralConstants.smallPadding),
      ),
    );
  }

  Widget _buildNavigationBar(bool isMobile) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _totalQuestions - 1;

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
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: TestScreenConstants.buttonHeight,
                child: OutlinedButton(
                  onPressed: isFirst ? null : _onPrevious,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isFirst
                          ? GeneralConstants.primaryColor.withValues(
                              alpha: 0.15,
                            )
                          : GeneralConstants.primaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GeneralConstants.mediumCircularRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    TestScreenConstants.previousLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w400,
                      color: isFirst
                          ? GeneralConstants.primaryColor.withValues(alpha: 0.3)
                          : GeneralConstants.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: GeneralConstants.smallSpacing),
            _buildDotIndicators(),
            const SizedBox(width: GeneralConstants.smallSpacing),
            Expanded(
              child: SizedBox(
                height: TestScreenConstants.buttonHeight,
                child: isLast
                    ? ElevatedButton(
                        onPressed: _confirmSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GeneralConstants.secondaryColor,
                          elevation: GeneralConstants.buttonElevation,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GeneralConstants.mediumCircularRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          TestScreenConstants.submitLabel,
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: GeneralConstants.backgroundColor,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GeneralConstants.secondaryColor,
                          elevation: GeneralConstants.buttonElevation,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GeneralConstants.mediumCircularRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          TestScreenConstants.nextLabel,
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.smallFontSize,
                            fontWeight: FontWeight.w500,
                            color: GeneralConstants.backgroundColor,
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

  Widget _buildDotIndicators() {
    if (_totalQuestions > 10) {
      return Text(
        '${_currentPage + 1}/$_totalQuestions',
        style: GoogleFonts.lexend(
          fontSize: TestScreenConstants.counterFontSize,
          fontWeight: FontWeight.w400,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalQuestions, (i) {
        final bool isAnswered;
        final q = _questions[i];
        if (q.questionType == QuestionType.fillInTheBlank) {
          isAnswered = (_fillInBlankAnswers[i] ?? '').trim().isNotEmpty;
        } else {
          isAnswered = (_selectedAnswerIds[i] ?? {}).isNotEmpty;
        }

        return GestureDetector(
          onTap: () => _goToPage(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _currentPage ? 10 : 8,
            height: i == _currentPage ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _currentPage
                  ? GeneralConstants.secondaryColor
                  : isAnswered
                  ? GeneralConstants.secondaryColor.withValues(alpha: 0.35)
                  : GeneralConstants.primaryColor.withValues(alpha: 0.15),
            ),
          ),
        );
      }),
    );
  }
}
