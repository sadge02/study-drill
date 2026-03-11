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

import '../../models/flashcard/flashcard_model.dart';
import '../../service/flashcard/flashcard_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/flashcard/screens/flashcard_create_edit_screen_constants.dart';
import '../../utils/core/utils.dart';

// Screen for creating and editing flashcard quiz
class CreateEditFlashcardScreen extends StatefulWidget {
  const CreateEditFlashcardScreen({super.key, this.flashcardSet, this.groupId});

  final FlashcardSet? flashcardSet;
  final String? groupId;

  @override
  State<CreateEditFlashcardScreen> createState() =>
      _CreateEditFlashcardScreenState();
}

class _CreateEditFlashcardScreenState extends State<CreateEditFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final FlashcardService _service = FlashcardService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _timeLimitController = TextEditingController();

  final List<String> _tags = [];
  final List<_CardDraft> _cards = [];

  bool _isLoading = false;

  bool get _isEditing => widget.flashcardSet != null;

  String get _effectiveGroupId =>
      widget.flashcardSet?.groupId ?? widget.groupId ?? '';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.flashcardSet!.title;
      _descriptionController.text = widget.flashcardSet!.description;
      _tags.addAll(widget.flashcardSet!.tags);
      if (widget.flashcardSet!.timeLimit != null) {
        _timeLimitController.text = widget.flashcardSet!.timeLimit.toString();
      }
      for (final c in widget.flashcardSet!.cards) {
        _cards.add(_CardDraft(question: c.question, answer: c.answer));
      }
    }
    if (_cards.isEmpty) _cards.add(_CardDraft());
  }

  String? _validateAll() {
    if (_cards.isEmpty) {
      return FlashcardCreateEditScreenConstants.noCardsError;
    }
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i].question.trim().isEmpty) {
        return '${FlashcardCreateEditScreenConstants.questionEmptyError} (Card ${i + 1})';
      }
      if (_cards[i].answer.trim().isEmpty) {
        return '${FlashcardCreateEditScreenConstants.answerEmptyError} (Card ${i + 1})';
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

    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final int? timeLimit = _timeLimitController.text.trim().isNotEmpty
          ? int.tryParse(_timeLimitController.text.trim())
          : null;

      final cards = _cards
          .map(
            (c) => Flashcard(
              id: FirebaseFirestore.instance.collection('_').doc().id,
              question: c.question.trim(),
              answer: c.answer.trim(),
            ),
          )
          .toList();

      if (_isEditing) {
        final updated = widget.flashcardSet!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: List<String>.from(_tags),
          timeLimit: timeLimit,
          cards: cards,
          updatedAt: now,
        );
        await _service.updateFlashcardSet(updated);
      } else {
        final newSet = FlashcardSet(
          id: FirebaseFirestore.instance.collection('flashcards').doc().id,
          authorId: userId,
          groupId: _effectiveGroupId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: List<String>.from(_tags),
          createdAt: now,
          updatedAt: now,
          timeLimit: timeLimit,
          cards: cards,
        );
        await _service.createFlashcardSet(newSet);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnackBar(
        CustomSnackBar.success(
          message: _isEditing
              ? FlashcardCreateEditScreenConstants.updateSuccessMessage
              : FlashcardCreateEditScreenConstants.createSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Flashcard create/edit error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(CustomSnackBar.error(message: 'Failed to save: $e'));
    }
  }

  void _onTagSubmitted(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    if (_tags.length >= FlashcardCreateEditScreenConstants.maxTags) {
      _showSnackBar(
        const CustomSnackBar.info(
          message: FlashcardCreateEditScreenConstants.maxTagsError,
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
              message: FlashcardCreateEditScreenConstants.noFileSelectedMessage,
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
      final imported = <_CardDraft>[];
      for (final item in parsed) {
        final map = item as Map<String, dynamic>;
        imported.add(
          _CardDraft(
            question: map['question'] as String? ?? '',
            answer: map['answer'] as String? ?? '',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        if (_cards.length == 1 &&
            _cards.first.question.isEmpty &&
            _cards.first.answer.isEmpty) {
          _cards.clear();
        }
        _cards.addAll(imported);
      });

      _showSnackBar(
        CustomSnackBar.success(message: '${imported.length} cards imported.'),
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          const CustomSnackBar.error(
            message: FlashcardCreateEditScreenConstants.importErrorMessage,
          ),
        );
      }
    }
  }

  void _showJsonFormatDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          FlashcardCreateEditScreenConstants.jsonFormatTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            FlashcardCreateEditScreenConstants.jsonFormatHint,
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
      body: Form(
        key: _formKey,
        child: Utils.isMobile(context) ? _buildMobile() : _buildDesktop(),
      ),
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
            ? FlashcardCreateEditScreenConstants.editAppBarTitle
            : FlashcardCreateEditScreenConstants.createAppBarTitle,
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

  Widget _buildDesktop() {
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

  Widget _buildMobile() {
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
        _sectionHeader(FlashcardCreateEditScreenConstants.basicInfoSection),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        _buildTitleInput(),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        _buildDescriptionInput(),
        _spacing(FlashcardCreateEditScreenConstants.sectionSpacing),
        _sectionHeader(FlashcardCreateEditScreenConstants.tagsSection),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        _buildTagInput(),
        if (_tags.isNotEmpty) ...[
          _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
          _buildTagChips(),
        ],
        _spacing(FlashcardCreateEditScreenConstants.sectionSpacing),
        _sectionHeader(FlashcardCreateEditScreenConstants.settingsSection),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        _buildTimeLimitInput(),
        _spacing(FlashcardCreateEditScreenConstants.sectionSpacing),
        _buildImportRow(),
        _spacing(FlashcardCreateEditScreenConstants.sectionSpacing),
        _buildCardsHeader(),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        ..._buildCardEntries(),
        _spacing(FlashcardCreateEditScreenConstants.fieldSpacing),
        Center(child: _buildAddCardButton()),
        _spacing(GeneralConstants.largeSpacing),
        Center(child: _buildSubmitButton()),
        _spacing(GeneralConstants.largeSpacing),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: FlashcardCreateEditScreenConstants.sectionHeaderFontSize,
        fontWeight: FontWeight.w500,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleController,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return FlashcardCreateEditScreenConstants.titleEmptyError;
        }
        if (v.trim().length <
            FlashcardCreateEditScreenConstants.titleMinLength) {
          return FlashcardCreateEditScreenConstants.titleTooShortError;
        }
        if (v.trim().length >
            FlashcardCreateEditScreenConstants.titleMaxLength) {
          return FlashcardCreateEditScreenConstants.titleTooLongError;
        }
        return null;
      },
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDeco(
        FlashcardCreateEditScreenConstants.titleHint,
        Icons.title,
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: FlashcardCreateEditScreenConstants.descriptionMaxLines.toInt(),
      validator: (v) {
        if (v != null &&
            v.trim().length >
                FlashcardCreateEditScreenConstants.descriptionMaxLength) {
          return FlashcardCreateEditScreenConstants.descriptionTooLongError;
        }
        return null;
      },
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDeco(
        FlashcardCreateEditScreenConstants.descriptionHint,
        Icons.description_outlined,
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
      decoration: _inputDeco(
        FlashcardCreateEditScreenConstants.tagInputHint,
        Icons.tag,
      ),
    );
  }

  Widget _buildTagChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: FlashcardCreateEditScreenConstants.tagChipSpacing,
        runSpacing: FlashcardCreateEditScreenConstants.tagChipSpacing,
        children: _tags
            .map(
              (t) => Chip(
                label: Text(
                  t,
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
                onDeleted: () => setState(() => _tags.remove(t)),
                backgroundColor: GeneralConstants.tertiaryColor.withValues(
                  alpha: 0.15,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GeneralConstants.smallCircularRadius,
                  ),
                ),
              ),
            )
            .toList(),
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
      decoration: _inputDeco(
        FlashcardCreateEditScreenConstants.timeLimitHint,
        Icons.timer_outlined,
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
              FlashcardCreateEditScreenConstants.importJsonLabel,
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
        const SizedBox(width: FlashcardCreateEditScreenConstants.fieldSpacing),
        IconButton(
          onPressed: _showJsonFormatDialog,
          icon: const Icon(
            Icons.help_outline,
            color: GeneralConstants.primaryColor,
          ),
          tooltip: FlashcardCreateEditScreenConstants.jsonFormatTitle,
        ),
      ],
    );
  }

  Widget _buildCardsHeader() {
    return Row(
      children: [
        Text(
          FlashcardCreateEditScreenConstants.cardsSection,
          style: GoogleFonts.lexend(
            fontSize: FlashcardCreateEditScreenConstants.sectionHeaderFontSize,
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
            '${_cards.length}',
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

  List<Widget> _buildCardEntries() {
    final list = <Widget>[];
    for (int i = 0; i < _cards.length; i++) {
      list.add(_buildCardEntry(i));
      if (i < _cards.length - 1) {
        list.add(_spacing(FlashcardCreateEditScreenConstants.fieldSpacing));
      }
    }
    return list;
  }

  Widget _buildCardEntry(int index) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardCreateEditScreenConstants.cardRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: FlashcardCreateEditScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: FlashcardCreateEditScreenConstants.cardNumberSize,
                height: FlashcardCreateEditScreenConstants.cardNumberSize,
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
                    fontSize:
                        FlashcardCreateEditScreenConstants.cardHeaderFontSize,
                    fontWeight: FontWeight.w600,
                    color: GeneralConstants.secondaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (_cards.length > 1)
                TextButton.icon(
                  onPressed: () => setState(() => _cards.removeAt(index)),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: GeneralConstants.smallSmallIconSize,
                    color: GeneralConstants.failureColor,
                  ),
                  label: Text(
                    FlashcardCreateEditScreenConstants.removeCardLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize - 2,
                      fontWeight: FontWeight.w400,
                      color: GeneralConstants.failureColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _cards[index].question,
            onChanged: (v) => _cards[index].question = v,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              color: GeneralConstants.primaryColor,
            ),
            decoration: _inputDeco(
              FlashcardCreateEditScreenConstants.questionHint,
              Icons.help_outline,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _cards[index].answer,
            onChanged: (v) => _cards[index].answer = v,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              color: GeneralConstants.primaryColor,
            ),
            decoration: _inputDeco(
              FlashcardCreateEditScreenConstants.answerHint,
              Icons.lightbulb_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _cards.add(_CardDraft())),
      icon: const Icon(Icons.add, color: GeneralConstants.secondaryColor),
      label: Text(
        FlashcardCreateEditScreenConstants.addCardLabel,
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
      width: FlashcardCreateEditScreenConstants.buttonWidth,
      height: FlashcardCreateEditScreenConstants.buttonHeight,
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
              ? FlashcardCreateEditScreenConstants.saveButtonLabel
              : FlashcardCreateEditScreenConstants.createButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
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

  Widget _spacing(double h) => SizedBox(height: h);
}

class _CardDraft {
  String question;
  String answer;
  _CardDraft({this.question = '', this.answer = ''});
}
