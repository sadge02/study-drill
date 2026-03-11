import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/test/test_model.dart';
import '../../service/test/test_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/test/screens/test_create_edit_screen_constants.dart';
import '../../utils/core/utils.dart';

// Screen for creating and editing tests
class TestCreateEditScreen extends StatefulWidget {
  const TestCreateEditScreen({super.key, this.test, this.groupId});

  final TestModel? test;
  final String? groupId;

  @override
  State<TestCreateEditScreen> createState() => _TestCreateEditScreenState();
}

class _TestCreateEditScreenState extends State<TestCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TestService _testService = TestService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _timeLimitController = TextEditingController();

  final List<String> _tags = [];
  final List<_QuestionDraft> _questions = [];

  bool _isLoading = false;

  bool get _isEditing => widget.test != null;

  String get _effectiveGroupId => widget.test?.groupId ?? widget.groupId ?? '';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.test!.title;
      _descriptionController.text = widget.test!.description;
      _tags.addAll(widget.test!.tags);
      if (widget.test!.timeLimit != null) {
        _timeLimitController.text = widget.test!.timeLimit.toString();
      }
      for (final q in widget.test!.questions) {
        _questions.add(
          _QuestionDraft(
            question: q.question,
            type: q.questionType,
            answers: q.answers
                .map(
                  (a) =>
                      _AnswerDraft(text: a.answerText, isCorrect: a.isCorrect),
                )
                .toList(),
          ),
        );
      }
    }
    if (_questions.isEmpty) {
      _questions.add(_QuestionDraft());
    }
  }

  String? _validateAll() {
    if (_questions.isEmpty) {
      return TestCreateEditScreenConstants.noQuestionsError;
    }
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.question.trim().isEmpty) {
        return '${TestCreateEditScreenConstants.questionEmptyError} (Q${i + 1})';
      }
      if (q.answers.length <
          TestCreateEditScreenConstants.minAnswersPerQuestion) {
        return '${TestCreateEditScreenConstants.noAnswersError} (Q${i + 1})';
      }
      if (q.type == QuestionType.trueFalse && q.answers.length != 2) {
        return '${TestCreateEditScreenConstants.trueFalseRequiresTwo} (Q${i + 1})';
      }
      if (!q.answers.any((a) => a.isCorrect)) {
        return '${TestCreateEditScreenConstants.noCorrectAnswerError} (Q${i + 1})';
      }
      for (int j = 0; j < q.answers.length; j++) {
        if (q.answers[j].text.trim().isEmpty) {
          return '${TestCreateEditScreenConstants.answerEmptyError} (Q${i + 1}, A${j + 1})';
        }
      }
    }
    return null;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final validationError = _validateAll();
    if (validationError != null) {
      _showSnackBar(CustomSnackBar.error(message: validationError));
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final questions = _questions.map((q) {
      return TestQuestion(
        id: FirebaseFirestore.instance.collection('_').doc().id,
        question: q.question.trim(),
        questionType: q.type,
        answers: q.answers.map((a) {
          return TestAnswerOption(
            id: FirebaseFirestore.instance.collection('_').doc().id,
            answerText: a.text.trim(),
            isCorrect: a.isCorrect,
          );
        }).toList(),
      );
    }).toList();

    final int? timeLimit = _timeLimitController.text.trim().isNotEmpty
        ? int.tryParse(_timeLimitController.text.trim())
        : null;

    if (_isEditing) {
      final updated = widget.test!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: List<String>.from(_tags),
        timeLimit: timeLimit,
        questions: questions,
        updatedAt: now,
      );
      await _testService.updateTest(updated);
    } else {
      final newTest = TestModel(
        id: FirebaseFirestore.instance.collection('tests').doc().id,
        authorId: userId,
        groupId: _effectiveGroupId.isNotEmpty ? _effectiveGroupId : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: List<String>.from(_tags),
        createdAt: now,
        updatedAt: now,
        timeLimit: timeLimit,
        questions: questions,
      );
      await _testService.createTest(newTest);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    _showSnackBar(
      CustomSnackBar.success(
        message: _isEditing
            ? TestCreateEditScreenConstants.updateSuccessMessage
            : TestCreateEditScreenConstants.createSuccessMessage,
      ),
    );
    Navigator.pop(context);
  }

  void _onTagSubmitted(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    if (_tags.length >= TestCreateEditScreenConstants.maxTags) {
      _showSnackBar(
        const CustomSnackBar.info(
          message: TestCreateEditScreenConstants.maxTagsError,
        ),
      );
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _onTagRemoved(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft()));
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _addAnswer(int questionIndex) {
    setState(() {
      _questions[questionIndex].answers.add(_AnswerDraft());
    });
  }

  void _removeAnswer(int questionIndex, int answerIndex) {
    setState(() {
      _questions[questionIndex].answers.removeAt(answerIndex);
    });
  }

  void _toggleCorrect(int questionIndex, int answerIndex) {
    setState(() {
      final q = _questions[questionIndex];
      if (q.type == QuestionType.singleChoice ||
          q.type == QuestionType.trueFalse) {
        for (int i = 0; i < q.answers.length; i++) {
          q.answers[i].isCorrect = i == answerIndex;
        }
      } else {
        q.answers[answerIndex].isCorrect = !q.answers[answerIndex].isCorrect;
      }
    });
  }

  void _onQuestionTypeChanged(int questionIndex, QuestionType? type) {
    if (type == null) return;
    setState(() {
      _questions[questionIndex].type = type;
      if (type == QuestionType.trueFalse) {
        _questions[questionIndex].answers = [
          _AnswerDraft(text: 'True', isCorrect: true),
          _AnswerDraft(text: 'False', isCorrect: false),
        ];
      }
    });
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          _showSnackBar(
            const CustomSnackBar.info(
              message: TestCreateEditScreenConstants.noFileSelectedMessage,
            ),
          );
        }
        return;
      }

      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        jsonString = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return;
        jsonString = await File(path).readAsString();
      }

      final List<dynamic> parsed = json.decode(jsonString) as List<dynamic>;

      final imported = <_QuestionDraft>[];
      for (final item in parsed) {
        final map = item as Map<String, dynamic>;
        final questionText = map['question'] as String? ?? '';
        final typeStr = map['type'] as String? ?? 'single_choice';
        final answersRaw = map['answers'] as List<dynamic>? ?? [];

        final type = _parseQuestionType(typeStr);

        final answers = answersRaw.map((a) {
          final aMap = a as Map<String, dynamic>;
          return _AnswerDraft(
            text: aMap['text'] as String? ?? '',
            isCorrect: aMap['correct'] as bool? ?? false,
          );
        }).toList();

        imported.add(
          _QuestionDraft(
            question: questionText,
            type: type,
            answers: answers.isEmpty
                ? [
                    _AnswerDraft(text: '', isCorrect: true),
                    _AnswerDraft(text: '', isCorrect: false),
                  ]
                : answers,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        if (_questions.length == 1 &&
            _questions.first.question.isEmpty &&
            _questions.first.answers.every(
              (a) => a.text.isEmpty || a.text == 'True' || a.text == 'False',
            )) {
          _questions.clear();
        }
        _questions.addAll(imported);
      });

      _showSnackBar(
        CustomSnackBar.success(
          message: '${imported.length} questions imported.',
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          const CustomSnackBar.error(
            message: TestCreateEditScreenConstants.importErrorMessage,
          ),
        );
      }
    }
  }

  QuestionType _parseQuestionType(String value) {
    switch (value) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_the_blank':
        return QuestionType.fillInTheBlank;
      case 'ordering':
        return QuestionType.ordering;
      default:
        return QuestionType.singleChoice;
    }
  }

  void _showJsonFormatDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          TestCreateEditScreenConstants.jsonFormatTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            TestCreateEditScreenConstants.jsonFormatHint,
            style: GoogleFonts.sourceCodePro(
              fontSize: GeneralConstants.smallFontSize - 2,
              color: GeneralConstants.primaryColor,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          ),
        ],
      ),
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        _isEditing
            ? TestCreateEditScreenConstants.editAppBarTitle
            : TestCreateEditScreenConstants.createAppBarTitle,
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

  Widget _buildBody(BuildContext context) {
    return Form(
      key: _formKey,
      child: Utils.isMobile(context)
          ? _buildBodyMobile(context)
          : _buildBodyDesktop(context),
    );
  }

  Widget _buildBodyDesktop(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.55,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
            vertical: GeneralConstants.smallMargin,
          ),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildBodyMobile(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.92,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GeneralConstants.smallMargin),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(TestCreateEditScreenConstants.basicInfoSection),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        _buildTitleInput(),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        _buildDescriptionInput(),
        _buildSpacing(height: TestCreateEditScreenConstants.sectionSpacing),
        _buildSectionHeader(TestCreateEditScreenConstants.tagsSection),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        _buildTagInput(),
        if (_tags.isNotEmpty) ...[
          _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
          _buildActiveTagChips(),
        ],
        _buildSpacing(height: TestCreateEditScreenConstants.sectionSpacing),
        _buildSectionHeader(TestCreateEditScreenConstants.settingsSection),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        _buildTimeLimitInput(),
        _buildSpacing(height: TestCreateEditScreenConstants.sectionSpacing),
        _buildImportRow(),
        _buildSpacing(height: TestCreateEditScreenConstants.sectionSpacing),
        _buildQuestionsHeader(),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        ..._buildQuestionCards(),
        _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        Center(child: _buildAddQuestionButton()),
        _buildSpacing(height: GeneralConstants.largeSpacing),
        Center(child: _buildSubmitButton()),
        _buildSpacing(height: GeneralConstants.largeSpacing),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: TestCreateEditScreenConstants.sectionHeaderFontSize,
        fontWeight: FontWeight.w500,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleController,
      validator: _validateTitle,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: TestCreateEditScreenConstants.titleHint,
        icon: Icons.title,
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      validator: _validateDescription,
      maxLines: TestCreateEditScreenConstants.descriptionMaxLines.toInt(),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: TestCreateEditScreenConstants.descriptionHint,
        icon: Icons.description_outlined,
      ),
    );
  }

  Widget _buildTagInput() {
    return TextField(
      controller: _tagController,
      onSubmitted: _onTagSubmitted,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: TestCreateEditScreenConstants.tagInputHint,
        icon: Icons.tag,
      ),
    );
  }

  Widget _buildActiveTagChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: TestCreateEditScreenConstants.tagChipSpacing,
        runSpacing: TestCreateEditScreenConstants.tagChipSpacing,
        children: _tags.map((tag) => _buildRemovableTagChip(tag)).toList(),
      ),
    );
  }

  Widget _buildRemovableTagChip(String tag) {
    return Chip(
      label: Text(
        tag,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w400,
          color: GeneralConstants.secondaryColor,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: GeneralConstants.smallSmallIconSize,
      ),
      deleteIconColor: GeneralConstants.secondaryColor,
      onDeleted: () => _onTagRemoved(tag),
      backgroundColor: GeneralConstants.tertiaryColor.withValues(alpha: 0.15),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
    );
  }

  Widget _buildTimeLimitInput() {
    return TextFormField(
      controller: _timeLimitController,
      keyboardType: TextInputType.number,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: TestCreateEditScreenConstants.timeLimitHint,
        icon: Icons.timer_outlined,
      ),
    );
  }

  Widget _buildImportRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _importJson,
            icon: const Icon(
              Icons.upload_file,
              color: GeneralConstants.secondaryColor,
            ),
            label: Text(
              TestCreateEditScreenConstants.importJsonLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w400,
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
              padding: const EdgeInsets.symmetric(
                vertical: GeneralConstants.smallPadding,
              ),
            ),
          ),
        ),
        const SizedBox(width: TestCreateEditScreenConstants.fieldSpacing),
        IconButton(
          onPressed: _showJsonFormatDialog,
          icon: const Icon(
            Icons.help_outline,
            color: GeneralConstants.primaryColor,
          ),
          tooltip: TestCreateEditScreenConstants.jsonFormatTitle,
        ),
      ],
    );
  }

  Widget _buildQuestionsHeader() {
    return Row(
      children: [
        Text(
          TestCreateEditScreenConstants.questionsSection,
          style: GoogleFonts.lexend(
            fontSize: TestCreateEditScreenConstants.sectionHeaderFontSize,
            fontWeight: FontWeight.w500,
            color: GeneralConstants.primaryColor,
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: GeneralConstants.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              GeneralConstants.smallCircularRadius,
            ),
          ),
          child: Text(
            '${_questions.length}',
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.secondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildQuestionCards() {
    final cards = <Widget>[];
    for (int i = 0; i < _questions.length; i++) {
      cards.add(_buildQuestionCard(i));
      if (i < _questions.length - 1) {
        cards.add(
          _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
        );
      }
    }
    return cards;
  }

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];

    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          TestCreateEditScreenConstants.questionCardRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: TestCreateEditScreenConstants.questionCardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCardHeader(index),
          _buildSpacing(height: TestCreateEditScreenConstants.answerRowSpacing),
          _buildQuestionTextField(index),
          _buildSpacing(height: TestCreateEditScreenConstants.answerRowSpacing),
          _buildQuestionTypeDropdown(index),
          _buildSpacing(height: TestCreateEditScreenConstants.fieldSpacing),
          ..._buildAnswerRows(index),
          if (q.type != QuestionType.trueFalse)
            Padding(
              padding: const EdgeInsets.only(
                top: TestCreateEditScreenConstants.answerRowSpacing,
              ),
              child: _buildAddAnswerButton(index),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCardHeader(int index) {
    return Row(
      children: [
        Container(
          width: TestCreateEditScreenConstants.questionNumberSize,
          height: TestCreateEditScreenConstants.questionNumberSize,
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
              fontSize: TestCreateEditScreenConstants.questionHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.secondaryColor,
            ),
          ),
        ),
        const Spacer(),
        if (_questions.length > 1)
          TextButton.icon(
            onPressed: () => _removeQuestion(index),
            icon: const Icon(
              Icons.delete_outline,
              size: GeneralConstants.smallSmallIconSize,
              color: GeneralConstants.failureColor,
            ),
            label: Text(
              TestCreateEditScreenConstants.removeQuestionLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize - 2,
                fontWeight: FontWeight.w400,
                color: GeneralConstants.failureColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionTextField(int index) {
    return TextFormField(
      initialValue: _questions[index].question,
      onChanged: (val) => _questions[index].question = val,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: TestCreateEditScreenConstants.questionHint,
        icon: Icons.help_outline,
      ),
    );
  }

  Widget _buildQuestionTypeDropdown(int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.tertiaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<QuestionType>(
          value: _questions[index].type,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: GeneralConstants.primaryColor,
          ),
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            color: GeneralConstants.primaryColor,
          ),
          items: QuestionType.values.map((type) {
            return DropdownMenuItem<QuestionType>(
              value: type,
              child: Text(
                _questionTypeLabel(type),
                style: GoogleFonts.lexend(
                  fontSize: GeneralConstants.smallFontSize,
                  color: GeneralConstants.primaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => _onQuestionTypeChanged(index, val),
        ),
      ),
    );
  }

  List<Widget> _buildAnswerRows(int questionIndex) {
    final q = _questions[questionIndex];
    final rows = <Widget>[];

    for (int i = 0; i < q.answers.length; i++) {
      rows.add(_buildAnswerRow(questionIndex, i));
      if (i < q.answers.length - 1) {
        rows.add(
          _buildSpacing(height: TestCreateEditScreenConstants.answerRowSpacing),
        );
      }
    }

    return rows;
  }

  Widget _buildAnswerRow(int questionIndex, int answerIndex) {
    final answer = _questions[questionIndex].answers[answerIndex];
    final q = _questions[questionIndex];
    final isTrueFalse = q.type == QuestionType.trueFalse;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _toggleCorrect(questionIndex, answerIndex),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: GeneralConstants.transitionDurationMs ~/ 3,
            ),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: answer.isCorrect
                  ? GeneralConstants.successColor
                  : Colors.transparent,
              border: Border.all(
                color: answer.isCorrect
                    ? GeneralConstants.successColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.largeOpacity,
                      ),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(
                q.type == QuestionType.multipleChoice ? 4 : 12,
              ),
            ),
            child: answer.isCorrect
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: GeneralConstants.backgroundColor,
                  )
                : null,
          ),
        ),
        const SizedBox(width: GeneralConstants.smallSpacing),
        Expanded(
          child: isTrueFalse
              ? Text(
                  answer.text,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    color: GeneralConstants.primaryColor,
                  ),
                )
              : TextFormField(
                  initialValue: answer.text,
                  onChanged: (val) =>
                      _questions[questionIndex].answers[answerIndex].text = val,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    color: GeneralConstants.primaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        '${TestCreateEditScreenConstants.answerHint} ${answerIndex + 1}',
                    hintStyle: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                    filled: true,
                    fillColor: GeneralConstants.tertiaryColor.withValues(
                      alpha: 0.06,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        GeneralConstants.smallCircularRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        GeneralConstants.smallCircularRadius,
                      ),
                      borderSide: const BorderSide(
                        color: GeneralConstants.secondaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: GeneralConstants.smallPadding,
                      vertical: GeneralConstants.tinyPadding,
                    ),
                    isDense: true,
                  ),
                ),
        ),
        if (!isTrueFalse &&
            q.answers.length >
                TestCreateEditScreenConstants.minAnswersPerQuestion)
          IconButton(
            onPressed: () => _removeAnswer(questionIndex, answerIndex),
            icon: const Icon(
              Icons.close,
              size: GeneralConstants.smallSmallIconSize,
              color: GeneralConstants.failureColor,
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: GeneralConstants.tinyPadding),
          ),
      ],
    );
  }

  Widget _buildAddAnswerButton(int questionIndex) {
    return GestureDetector(
      onTap: () => _addAnswer(questionIndex),
      child: Row(
        children: [
          const Icon(
            Icons.add_circle_outline,
            size: GeneralConstants.smallSmallIconSize,
            color: GeneralConstants.secondaryColor,
          ),
          const SizedBox(width: GeneralConstants.tinySpacing),
          Text(
            TestCreateEditScreenConstants.addAnswerLabel,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize - 2,
              fontWeight: FontWeight.w400,
              color: GeneralConstants.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return OutlinedButton.icon(
      onPressed: _addQuestion,
      icon: const Icon(Icons.add, color: GeneralConstants.secondaryColor),
      label: Text(
        TestCreateEditScreenConstants.addQuestionLabel,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w400,
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
        padding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.mediumPadding,
          vertical: GeneralConstants.smallPadding,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }

    return SizedBox(
      width: TestCreateEditScreenConstants.buttonWidth,
      height: TestCreateEditScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _handleSubmit,
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
          _isEditing
              ? TestCreateEditScreenConstants.saveButtonLabel
              : TestCreateEditScreenConstants.createButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.mediumOpacity,
        ),
      ),
      prefixIcon: Icon(icon, color: GeneralConstants.primaryColor),
      filled: true,
      fillColor: GeneralConstants.tertiaryColor.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        borderSide: const BorderSide(color: GeneralConstants.secondaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        borderSide: const BorderSide(color: GeneralConstants.failureColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        borderSide: const BorderSide(color: GeneralConstants.failureColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.mediumPadding,
        vertical: GeneralConstants.smallPadding,
      ),
    );
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return TestCreateEditScreenConstants.singleChoiceLabel;
      case QuestionType.multipleChoice:
        return TestCreateEditScreenConstants.multipleChoiceLabel;
      case QuestionType.trueFalse:
        return TestCreateEditScreenConstants.trueFalseLabel;
      case QuestionType.fillInTheBlank:
        return TestCreateEditScreenConstants.fillInBlankLabel;
      case QuestionType.ordering:
        return TestCreateEditScreenConstants.orderingLabel;
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TestCreateEditScreenConstants.titleEmptyError;
    }
    if (value.trim().length < TestCreateEditScreenConstants.titleMinLength) {
      return TestCreateEditScreenConstants.titleTooShortError;
    }
    if (value.trim().length > TestCreateEditScreenConstants.titleMaxLength) {
      return TestCreateEditScreenConstants.titleTooLongError;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null &&
        value.trim().length >
            TestCreateEditScreenConstants.descriptionMaxLength) {
      return TestCreateEditScreenConstants.descriptionTooLongError;
    }
    return null;
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}

class _QuestionDraft {
  String question;
  QuestionType type;
  List<_AnswerDraft> answers;

  _QuestionDraft({
    this.question = '',
    this.type = QuestionType.singleChoice,
    List<_AnswerDraft>? answers,
  }) : answers =
           answers ??
           [
             _AnswerDraft(text: '', isCorrect: true),
             _AnswerDraft(text: '', isCorrect: false),
           ];
}

class _AnswerDraft {
  String text;
  bool isCorrect;

  _AnswerDraft({this.text = '', this.isCorrect = false});
}
