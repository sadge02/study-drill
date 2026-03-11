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

import '../../models/connect/connect_model.dart';
import '../../service/connect/connect_service.dart';
import '../../utils/constants/connect/screens/connect_create_edit_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';

class ConnectCreateEditScreen extends StatefulWidget {
  const ConnectCreateEditScreen({super.key, this.connect, this.groupId});

  final ConnectModel? connect;
  final String? groupId;

  @override
  State<ConnectCreateEditScreen> createState() =>
      _ConnectCreateEditScreenState();
}

class _ConnectCreateEditScreenState extends State<ConnectCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ConnectService _service = ConnectService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _timeLimitCtrl = TextEditingController();

  final List<String> _tags = [];
  final List<_PairDraft> _pairs = [];
  bool _isLoading = false;

  bool get _isEditing => widget.connect != null;
  String get _groupId => widget.connect?.groupId ?? widget.groupId ?? '';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.connect!.title;
      _descCtrl.text = widget.connect!.description;
      _tags.addAll(widget.connect!.tags);
      if (widget.connect!.timeLimit != null) {
        _timeLimitCtrl.text = widget.connect!.timeLimit.toString();
      }
      for (final p in widget.connect!.pairs) {
        _pairs.add(_PairDraft(question: p.question, answer: p.answer));
      }
    }
    if (_pairs.isEmpty) _pairs.add(_PairDraft());
  }

  String? _validatePairs() {
    if (_pairs.isEmpty) return ConnectCreateEditScreenConstants.noPairsError;
    for (int i = 0; i < _pairs.length; i++) {
      if (_pairs[i].question.trim().isEmpty) {
        return '${ConnectCreateEditScreenConstants.questionEmptyError} (Pair ${i + 1})';
      }
      if (_pairs[i].answer.trim().isEmpty) {
        return '${ConnectCreateEditScreenConstants.answerEmptyError} (Pair ${i + 1})';
      }
    }
    return null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final err = _validatePairs();
    if (err != null) {
      _snack(CustomSnackBar.error(message: err));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final int? tl = _timeLimitCtrl.text.trim().isNotEmpty
          ? int.tryParse(_timeLimitCtrl.text.trim())
          : null;

      final pairs = _pairs
          .map(
            (p) => ConnectPair(
              id: FirebaseFirestore.instance.collection('_').doc().id,
              question: p.question.trim(),
              answer: p.answer.trim(),
            ),
          )
          .toList();

      if (_isEditing) {
        await _service.updateConnect(
          widget.connect!.copyWith(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            tags: List<String>.from(_tags),
            timeLimit: tl,
            pairs: pairs,
            updatedAt: now,
          ),
        );
      } else {
        await _service.createConnect(
          ConnectModel(
            id: FirebaseFirestore.instance.collection('connects').doc().id,
            authorId: uid,
            groupId: _groupId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            tags: List<String>.from(_tags),
            createdAt: now,
            updatedAt: now,
            timeLimit: tl,
            pairs: pairs,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(
        CustomSnackBar.success(
          message: _isEditing
              ? ConnectCreateEditScreenConstants.updateSuccessMessage
              : ConnectCreateEditScreenConstants.createSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Connect create/edit error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(CustomSnackBar.error(message: 'Failed to save: $e'));
    }
  }

  void _onTagSubmitted(String v) {
    final tag = v.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagCtrl.clear();
      return;
    }
    if (_tags.length >= ConnectCreateEditScreenConstants.maxTags) {
      _snack(
        const CustomSnackBar.info(
          message: ConnectCreateEditScreenConstants.maxTagsError,
        ),
      );
      _tagCtrl.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
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
          _snack(
            const CustomSnackBar.info(
              message: ConnectCreateEditScreenConstants.noFileSelectedMessage,
            ),
          );
        }
        return;
      }

      String jsonStr;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        jsonStr = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return;
        jsonStr = await File(path).readAsString();
      }

      final List<dynamic> parsed = json.decode(jsonStr) as List<dynamic>;
      final imported = <_PairDraft>[];
      for (final item in parsed) {
        final m = item as Map<String, dynamic>;
        imported.add(
          _PairDraft(
            question: m['question'] as String? ?? '',
            answer: m['answer'] as String? ?? '',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        if (_pairs.length == 1 &&
            _pairs.first.question.isEmpty &&
            _pairs.first.answer.isEmpty) {
          _pairs.clear();
        }
        _pairs.addAll(imported);
      });
      _snack(
        CustomSnackBar.success(
          message:
              '${imported.length} ${ConnectCreateEditScreenConstants.importSuccessMessage}',
        ),
      );
    } catch (_) {
      if (mounted) {
        _snack(
          const CustomSnackBar.error(
            message: ConnectCreateEditScreenConstants.importErrorMessage,
          ),
        );
      }
    }
  }

  void _showJsonFormat() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ConnectCreateEditScreenConstants.jsonFormatTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            ConnectCreateEditScreenConstants.jsonFormatHint,
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

  void _snack(Widget s) {
    showTopSnackBar(
      Overlay.of(context),
      displayDuration: const Duration(
        milliseconds: GeneralConstants.notificationDurationMs,
      ),
      snackBarPosition: SnackBarPosition.bottom,
      s,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _timeLimitCtrl.dispose();
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
            ? ConnectCreateEditScreenConstants.editAppBarTitle
            : ConnectCreateEditScreenConstants.createAppBarTitle,
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

  Widget _buildDesktop() => Center(
    child: FractionallySizedBox(
      widthFactor: 0.55,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.mediumMargin,
          vertical: GeneralConstants.smallMargin,
        ),
        child: _form(),
      ),
    ),
  );

  Widget _buildMobile() => Center(
    child: FractionallySizedBox(
      widthFactor: 0.92,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GeneralConstants.smallMargin),
        child: _form(),
      ),
    ),
  );

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(ConnectCreateEditScreenConstants.basicInfoSection),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        _titleField(),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        _descField(),
        _sp(ConnectCreateEditScreenConstants.sectionSpacing),
        _header(ConnectCreateEditScreenConstants.tagsSection),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        _tagField(),
        if (_tags.isNotEmpty) ...[
          _sp(ConnectCreateEditScreenConstants.fieldSpacing),
          _tagChips(),
        ],
        _sp(ConnectCreateEditScreenConstants.sectionSpacing),
        _header(ConnectCreateEditScreenConstants.settingsSection),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        _timeLimitField(),
        _sp(ConnectCreateEditScreenConstants.sectionSpacing),
        _importRow(),
        _sp(ConnectCreateEditScreenConstants.sectionSpacing),
        _pairsHeader(),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        ..._pairEntries(),
        _sp(ConnectCreateEditScreenConstants.fieldSpacing),
        Center(child: _addPairBtn()),
        _sp(GeneralConstants.largeSpacing),
        Center(child: _submitBtn()),
        _sp(GeneralConstants.largeSpacing),
      ],
    );
  }

  Widget _header(String t) => Text(
    t,
    style: GoogleFonts.lexend(
      fontSize: ConnectCreateEditScreenConstants.sectionHeaderFontSize,
      fontWeight: FontWeight.w500,
      color: GeneralConstants.primaryColor,
    ),
  );

  Widget _titleField() => TextFormField(
    controller: _titleCtrl,
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return ConnectCreateEditScreenConstants.titleEmptyError;
      }
      if (v.trim().length < ConnectCreateEditScreenConstants.titleMinLength) {
        return ConnectCreateEditScreenConstants.titleTooShortError;
      }
      if (v.trim().length > ConnectCreateEditScreenConstants.titleMaxLength) {
        return ConnectCreateEditScreenConstants.titleTooLongError;
      }
      return null;
    },
    style: GoogleFonts.lexend(
      fontSize: GeneralConstants.smallFontSize,
      color: GeneralConstants.primaryColor,
    ),
    decoration: _deco(ConnectCreateEditScreenConstants.titleHint, Icons.title),
  );

  Widget _descField() => TextFormField(
    controller: _descCtrl,
    maxLines: ConnectCreateEditScreenConstants.descriptionMaxLines.toInt(),
    validator: (v) {
      if (v != null &&
          v.trim().length >
              ConnectCreateEditScreenConstants.descriptionMaxLength) {
        return ConnectCreateEditScreenConstants.descriptionTooLongError;
      }
      return null;
    },
    style: GoogleFonts.lexend(
      fontSize: GeneralConstants.smallFontSize,
      color: GeneralConstants.primaryColor,
    ),
    decoration: _deco(
      ConnectCreateEditScreenConstants.descriptionHint,
      Icons.description_outlined,
    ),
  );

  Widget _tagField() => TextField(
    controller: _tagCtrl,
    onSubmitted: _onTagSubmitted,
    style: GoogleFonts.lexend(
      fontSize: GeneralConstants.smallFontSize,
      color: GeneralConstants.primaryColor,
    ),
    decoration: _deco(ConnectCreateEditScreenConstants.tagInputHint, Icons.tag),
  );

  Widget _tagChips() => Align(
    alignment: Alignment.centerLeft,
    child: Wrap(
      spacing: ConnectCreateEditScreenConstants.tagChipSpacing,
      runSpacing: ConnectCreateEditScreenConstants.tagChipSpacing,
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

  Widget _timeLimitField() => TextFormField(
    controller: _timeLimitCtrl,
    keyboardType: TextInputType.number,
    style: GoogleFonts.lexend(
      fontSize: GeneralConstants.smallFontSize,
      color: GeneralConstants.primaryColor,
    ),
    decoration: _deco(
      ConnectCreateEditScreenConstants.timeLimitHint,
      Icons.timer_outlined,
    ),
  );

  Widget _importRow() => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _importJson,
          icon: const Icon(
            Icons.upload_file,
            color: GeneralConstants.secondaryColor,
          ),
          label: Text(
            ConnectCreateEditScreenConstants.importJsonLabel,
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
      const SizedBox(width: ConnectCreateEditScreenConstants.fieldSpacing),
      IconButton(
        onPressed: _showJsonFormat,
        icon: const Icon(
          Icons.help_outline,
          color: GeneralConstants.primaryColor,
        ),
        tooltip: ConnectCreateEditScreenConstants.jsonFormatTitle,
      ),
    ],
  );

  Widget _pairsHeader() => Row(
    children: [
      _header(ConnectCreateEditScreenConstants.pairsSection),
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
          '${_pairs.length}',
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            fontWeight: FontWeight.w600,
            color: GeneralConstants.secondaryColor,
          ),
        ),
      ),
    ],
  );

  List<Widget> _pairEntries() {
    final list = <Widget>[];
    for (int i = 0; i < _pairs.length; i++) {
      list.add(_pairEntry(i));
      if (i < _pairs.length - 1) {
        list.add(_sp(ConnectCreateEditScreenConstants.fieldSpacing));
      }
    }
    return list;
  }

  Widget _pairEntry(int i) => Container(
    padding: const EdgeInsets.all(GeneralConstants.smallPadding),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        ConnectCreateEditScreenConstants.cardRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: ConnectCreateEditScreenConstants.cardBorderOpacity,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: ConnectCreateEditScreenConstants.cardNumberSize,
              height: ConnectCreateEditScreenConstants.cardNumberSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GeneralConstants.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  GeneralConstants.smallCircularRadius,
                ),
              ),
              child: Text(
                '${i + 1}',
                style: GoogleFonts.lexend(
                  fontSize: ConnectCreateEditScreenConstants.cardHeaderFontSize,
                  fontWeight: FontWeight.w600,
                  color: GeneralConstants.secondaryColor,
                ),
              ),
            ),
            const Spacer(),
            if (_pairs.length > 1)
              TextButton.icon(
                onPressed: () => setState(() => _pairs.removeAt(i)),
                icon: const Icon(
                  Icons.delete_outline,
                  size: GeneralConstants.smallSmallIconSize,
                  color: GeneralConstants.failureColor,
                ),
                label: Text(
                  ConnectCreateEditScreenConstants.removePairLabel,
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
          initialValue: _pairs[i].question,
          onChanged: (v) => _pairs[i].question = v,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            color: GeneralConstants.primaryColor,
          ),
          decoration: _deco(
            ConnectCreateEditScreenConstants.questionHint,
            Icons.help_outline,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _pairs[i].answer,
          onChanged: (v) => _pairs[i].answer = v,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            color: GeneralConstants.primaryColor,
          ),
          decoration: _deco(
            ConnectCreateEditScreenConstants.answerHint,
            Icons.lightbulb_outline,
          ),
        ),
      ],
    ),
  );

  Widget _addPairBtn() => OutlinedButton.icon(
    onPressed: () => setState(() => _pairs.add(_PairDraft())),
    icon: const Icon(Icons.add, color: GeneralConstants.secondaryColor),
    label: Text(
      ConnectCreateEditScreenConstants.addPairLabel,
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

  Widget _submitBtn() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }
    return SizedBox(
      width: ConnectCreateEditScreenConstants.buttonWidth,
      height: ConnectCreateEditScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _submit,
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
              ? ConnectCreateEditScreenConstants.saveButtonLabel
              : ConnectCreateEditScreenConstants.createButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
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

  Widget _sp(double h) => SizedBox(height: h);
}

class _PairDraft {
  String question;
  String answer;
  _PairDraft({this.question = '', this.answer = ''});
}
