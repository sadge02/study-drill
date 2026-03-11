import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/flashcard/flashcard_model.dart';
import '../../models/user/user_model.dart';
import '../../service/flashcard/flashcard_service.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/flashcard/screens/flashcard_detail_screen_constants.dart';
import '../../utils/core/utils.dart';
import 'flashcard_create_edit_screen.dart';
import 'flashcard_screen.dart';

// Screen for going through the details of a flashcard quiz
class FlashcardDetailScreen extends StatefulWidget {
  const FlashcardDetailScreen({super.key, required this.flashcardSetId});

  final String flashcardSetId;

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardService _service = FlashcardService();
  final UserService _userService = UserService();
  late TabController _tabController;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FlashcardDetailScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleDelete(FlashcardSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          FlashcardDetailScreenConstants.deleteConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          FlashcardDetailScreenConstants.deleteConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              FlashcardDetailScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              FlashcardDetailScreenConstants.confirmDeleteLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteFlashcardSet(set.id);
    if (!mounted) return;
    _snack(
      const CustomSnackBar.success(
        message: FlashcardDetailScreenConstants.deleteSuccessMessage,
      ),
    );
    Navigator.pop(context);
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
  Widget build(BuildContext context) {
    return StreamBuilder<FlashcardSet?>(
      stream: _service.streamFlashcardSetById(widget.flashcardSetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _appBar(null),
            body: const Center(
              child: CircularProgressIndicator(
                color: GeneralConstants.primaryColor,
              ),
            ),
          );
        }
        final set = snapshot.data;
        if (set == null) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _appBar(null),
            body: Center(
              child: Text(
                'Flashcard set not found.',
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
          appBar: _appBar(set),
          body: Column(
            children: [
              _tabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _overviewTab(set),
                    _cardsTab(set),
                    _statisticsTab(set),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(FlashcardSet? set) {
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
        set?.title ?? FlashcardDetailScreenConstants.appBarTitle,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lexend(
          fontSize: Utils.isMobile(context)
              ? GeneralConstants.smallTitleSize
              : GeneralConstants.mediumTitleSize,
          fontWeight: FontWeight.w200,
          color: GeneralConstants.primaryColor,
        ),
      ),
      actions: set != null ? _actions(set) : null,
    );
  }

  List<Widget> _actions(FlashcardSet set) {
    if (set.authorId != _uid) return [];
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: GeneralConstants.primaryColor),
        offset: const Offset(0, GeneralConstants.appBarHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
        ),
        onSelected: (v) {
          if (v == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CreateEditFlashcardScreen(flashcardSet: set),
              ),
            );
          } else if (v == 'delete') {
            _handleDelete(set);
          }
        },
        itemBuilder: (_) => [
          _popupItem(
            'edit',
            Icons.edit_outlined,
            FlashcardDetailScreenConstants.editLabel,
            GeneralConstants.primaryColor,
          ),
          _popupItem(
            'delete',
            Icons.delete_outline,
            FlashcardDetailScreenConstants.deleteLabel,
            GeneralConstants.failureColor,
          ),
        ],
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  PopupMenuItem<String> _popupItem(String v, IconData i, String l, Color c) {
    return PopupMenuItem<String>(
      value: v,
      child: Row(
        children: [
          Icon(i, color: c),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Text(
            l,
            style: GoogleFonts.lexend(fontWeight: FontWeight.w300, color: c),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
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
          Tab(text: FlashcardDetailScreenConstants.overviewTab),
          Tab(text: FlashcardDetailScreenConstants.cardsTab),
          Tab(text: FlashcardDetailScreenConstants.statisticsTab),
        ],
      ),
    );
  }

  EdgeInsets _pad() => EdgeInsets.symmetric(
    horizontal: Utils.isMobile(context)
        ? GeneralConstants.smallMargin
        : MediaQuery.of(context).size.width * 0.2,
    vertical: GeneralConstants.smallMargin,
  );

  Widget _overviewTab(FlashcardSet set) {
    final my = set.attemptsForUser(_uid);
    return SingleChildScrollView(
      padding: _pad(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow(set, my),
          SizedBox(height: FlashcardDetailScreenConstants.sectionSpacing),
          _startButton(set),
          SizedBox(height: FlashcardDetailScreenConstants.sectionSpacing),
          _infoSection(
            FlashcardDetailScreenConstants.descriptionLabel,
            Icons.description_outlined,
            child: Text(
              set.description.isEmpty
                  ? FlashcardDetailScreenConstants.noDescriptionLabel
                  : set.description,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: set.description.isEmpty
                    ? GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      )
                    : GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
          _infoSection(
            FlashcardDetailScreenConstants.tagsLabel,
            Icons.tag,
            child: set.tags.isEmpty
                ? Text(
                    FlashcardDetailScreenConstants.noTagsLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: FlashcardDetailScreenConstants.tagChipSpacing,
                    runSpacing: FlashcardDetailScreenConstants.tagChipSpacing,
                    children: set.tags.map(_tagChip).toList(),
                  ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
          _infoSection(
            FlashcardDetailScreenConstants.timeLimitLabel,
            Icons.timer_outlined,
            child: Text(
              set.hasTimeLimit
                  ? _fmtTime(set.timeLimit!)
                  : FlashcardDetailScreenConstants.noTimeLimitLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: set.hasTimeLimit
                    ? GeneralConstants.primaryColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
              ),
            ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
          _infoSection(
            FlashcardDetailScreenConstants.createdLabel,
            Icons.calendar_today_outlined,
            child: Text(
              _fmtDate(set.createdAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
          _infoSection(
            FlashcardDetailScreenConstants.updatedLabel,
            Icons.update_outlined,
            child: Text(
              _fmtDate(set.updatedAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _statRow(FlashcardSet set, List<FlashcardAttempt> my) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            set.cardCount.toString(),
            FlashcardDetailScreenConstants.cardsCountLabel,
            Icons.style,
          ),
        ),
        SizedBox(width: FlashcardDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _statCard(
            set.attemptCount.toString(),
            FlashcardDetailScreenConstants.attemptsCountLabel,
            Icons.people_outline,
          ),
        ),
        SizedBox(width: FlashcardDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _statCard(
            '${set.averageAccuracy.toStringAsFixed(0)}%',
            FlashcardDetailScreenConstants.avgAccuracyLabel,
            Icons.analytics_outlined,
          ),
        ),
        SizedBox(width: FlashcardDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _statCard(
            my.length.toString(),
            FlashcardDetailScreenConstants.yourAttemptsLabel,
            Icons.person_outline,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String val, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.secondaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          FlashcardDetailScreenConstants.cardBorderRadius,
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
            val,
            style: GoogleFonts.lexend(
              fontSize: FlashcardDetailScreenConstants.statFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.primaryColor,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: FlashcardDetailScreenConstants.statLabelFontSize,
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

  Widget _startButton(FlashcardSet set) {
    return SizedBox(
      width: double.infinity,
      height: FlashcardDetailScreenConstants.startButtonHeight,
      child: ElevatedButton.icon(
        onPressed: set.cards.isNotEmpty
            ? () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => FlashcardScreen(flashcardSet: set),
                ),
              )
            : null,
        icon: const Icon(
          Icons.play_arrow_rounded,
          color: GeneralConstants.backgroundColor,
        ),
        label: Text(
          FlashcardDetailScreenConstants.startLabel,
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

  Widget _infoSection(String title, IconData icon, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: FlashcardDetailScreenConstants.cardBorderOpacity,
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
                  fontSize:
                      FlashcardDetailScreenConstants.sectionHeaderFontSize,
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

  Widget _tagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlashcardDetailScreenConstants.badgeHorizontalPadding,
        vertical: FlashcardDetailScreenConstants.badgeVerticalPadding,
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
          fontSize: FlashcardDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.secondaryColor,
        ),
      ),
    );
  }

  Widget _cardsTab(FlashcardSet set) {
    if (set.cards.isEmpty) {
      return Center(
        child: Text(
          FlashcardDetailScreenConstants.noCardsMessage,
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
    return ListView.separated(
      padding: _pad(),
      itemCount: set.cards.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
      itemBuilder: (_, i) => _cardPreview(set.cards[i], i),
    );
  }

  Widget _cardPreview(Flashcard card, int index) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: FlashcardDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: FlashcardDetailScreenConstants.cardNumberSize,
            height: FlashcardDetailScreenConstants.cardNumberSize,
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
                Row(
                  children: [
                    _sideBadge(
                      FlashcardDetailScreenConstants.questionSideLabel,
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
                Row(
                  children: [
                    _sideBadge(
                      FlashcardDetailScreenConstants.answerSideLabel,
                      GeneralConstants.successColor,
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Expanded(
                      child: Text(
                        card.answer,
                        style: GoogleFonts.lexend(
                          fontSize: GeneralConstants.smallFontSize - 1,
                          fontWeight: FontWeight.w300,
                          color: GeneralConstants.primaryColor.withValues(
                            alpha: GeneralConstants.smallOpacity,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          fontSize: FlashcardDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statisticsTab(FlashcardSet set) {
    if (set.attempts.isEmpty) {
      return Center(
        child: Text(
          FlashcardDetailScreenConstants.noAttemptsMessage,
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
    final my = set.attemptsForUser(_uid);
    final all = List<FlashcardAttempt>.from(set.attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final uniqueIds = set.attempts.map((a) => a.userId).toSet().toList();

    return SingleChildScrollView(
      padding: _pad(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leaderboard(set, uniqueIds),
          SizedBox(height: FlashcardDetailScreenConstants.sectionSpacing),
          if (my.isNotEmpty) ...[
            _sectionLabel(FlashcardDetailScreenConstants.myAttemptsLabel),
            SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
            ...my.map(
              (a) => Padding(
                padding: EdgeInsets.only(
                  bottom: FlashcardDetailScreenConstants.fieldSpacing,
                ),
                child: _attemptCard(a, set.cardCount),
              ),
            ),
          ],
          _sectionLabel(FlashcardDetailScreenConstants.allAttemptsLabel),
          SizedBox(height: FlashcardDetailScreenConstants.fieldSpacing),
          ...all.map(
            (a) => Padding(
              padding: EdgeInsets.only(
                bottom: FlashcardDetailScreenConstants.fieldSpacing,
              ),
              child: _attemptCardUser(a, set.cardCount),
            ),
          ),
          SizedBox(height: FlashcardDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _leaderboard(FlashcardSet set, List<String> uids) {
    return FutureBuilder<List<UserModel>>(
      future: _userService.getUsersByIds(uids),
      builder: (context, snap) {
        final users = snap.data ?? [];
        final map = {for (final u in users) u.id: u};
        final entries = <_LB>[];
        for (final uid in uids) {
          final ua = set.attemptsForUser(uid);
          if (ua.isEmpty) continue;
          final best = ua.reduce((a, b) => a.accuracy >= b.accuracy ? a : b);
          entries.add(
            _LB(
              uid: uid,
              name: map[uid]?.username ?? 'Unknown',
              pic: map[uid]?.profilePic ?? '',
              acc: best.accuracy,
              cnt: ua.length,
            ),
          );
        }
        entries.sort((a, b) => b.acc.compareTo(a.acc));
        return Container(
          padding: const EdgeInsets.all(GeneralConstants.smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              FlashcardDetailScreenConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: GeneralConstants.primaryColor.withValues(
                alpha: FlashcardDetailScreenConstants.cardBorderOpacity,
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
                      fontSize:
                          FlashcardDetailScreenConstants.sectionHeaderFontSize,
                      fontWeight: FontWeight.w500,
                      color: GeneralConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GeneralConstants.smallSpacing),
              ...entries.asMap().entries.map((e) => _lbRow(e.key, e.value)),
            ],
          ),
        );
      },
    );
  }

  Widget _lbRow(int rank, _LB e) {
    Color? medal;
    if (rank == 0) medal = const Color(0xFFFFD700);
    if (rank == 1) medal = const Color(0xFFC0C0C0);
    if (rank == 2) medal = const Color(0xFFCD7F32);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal != null
                ? Icon(Icons.emoji_events, color: medal, size: 20)
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
            backgroundImage: e.pic.isNotEmpty ? NetworkImage(e.pic) : null,
            child: e.pic.isEmpty
                ? Text(
                    e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
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
              e.name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: e.uid == _uid ? FontWeight.w600 : FontWeight.w400,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          Text(
            '${e.cnt}x',
            style: GoogleFonts.lexend(
              fontSize: FlashcardDetailScreenConstants.badgeFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.mediumOpacity,
              ),
            ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          _accBadge(e.acc),
        ],
      ),
    );
  }

  Widget _attemptCard(FlashcardAttempt a, int total) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FlashcardDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: FlashcardDetailScreenConstants.cardBorderOpacity,
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
                  _fmtDate(a.completedAt),
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
                      '${a.correct} ${FlashcardDetailScreenConstants.correctLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: FlashcardDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      '${a.incorrect} ${FlashcardDetailScreenConstants.incorrectLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: FlashcardDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.failureColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      '${a.totalCards}/$total',
                      style: GoogleFonts.lexend(
                        fontSize: FlashcardDetailScreenConstants.badgeFontSize,
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
          _accBadge(a.accuracy),
        ],
      ),
    );
  }

  Widget _attemptCardUser(FlashcardAttempt a, int total) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(a.userId),
      builder: (context, snap) {
        final u = snap.data;
        final name = u?.username ?? 'Unknown';
        final pic = u?.profilePic ?? '';
        return Container(
          padding: const EdgeInsets.all(GeneralConstants.smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              FlashcardDetailScreenConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: GeneralConstants.primaryColor.withValues(
                alpha: FlashcardDetailScreenConstants.cardBorderOpacity,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: GeneralConstants.tertiaryColor,
                backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                child: pic.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                      name,
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
                          '${a.correct}/${a.totalCards}',
                          style: GoogleFonts.lexend(
                            fontSize:
                                FlashcardDetailScreenConstants.badgeFontSize,
                            fontWeight: FontWeight.w300,
                            color: GeneralConstants.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: GeneralConstants.smallSpacing),
                        Text(
                          _fmtDate(a.completedAt),
                          style: GoogleFonts.lexend(
                            fontSize:
                                FlashcardDetailScreenConstants.badgeFontSize,
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
              _accBadge(a.accuracy),
            ],
          ),
        );
      },
    );
  }

  Widget _accBadge(double acc) {
    final Color c;
    if (acc >= 80) {
      c = GeneralConstants.successColor;
    } else if (acc >= 50) {
      c = GeneralConstants.tertiaryColor;
    } else {
      c = GeneralConstants.failureColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlashcardDetailScreenConstants.badgeHorizontalPadding,
        vertical: FlashcardDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        '${acc.toStringAsFixed(0)}%',
        style: GoogleFonts.lexend(
          fontSize: FlashcardDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }

  Widget _sectionLabel(String l) => Text(
    l,
    style: GoogleFonts.lexend(
      fontSize: FlashcardDetailScreenConstants.sectionHeaderFontSize,
      fontWeight: FontWeight.w500,
      color: GeneralConstants.primaryColor,
    ),
  );

  String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

  String _fmtTime(int s) {
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    if (r == 0) return '${m}m';
    return '${m}m ${r}s';
  }
}

class _LB {
  final String uid, name, pic;
  final double acc;
  final int cnt;
  const _LB({
    required this.uid,
    required this.name,
    required this.pic,
    required this.acc,
    required this.cnt,
  });
}
