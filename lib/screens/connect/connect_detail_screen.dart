import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/connect/connect_model.dart';
import '../../models/user/user_model.dart';
import '../../service/connect/connect_service.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/connect/screens/connect_detail_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';
import 'connect_create_edit_screen.dart';
import 'connect_screen.dart';

// Screen that will contain all the tutorial about the connect
class ConnectDetailScreen extends StatefulWidget {
  const ConnectDetailScreen({super.key, required this.connectId});

  final String connectId;

  @override
  State<ConnectDetailScreen> createState() => _ConnectDetailScreenState();
}

class _ConnectDetailScreenState extends State<ConnectDetailScreen>
    with SingleTickerProviderStateMixin {
  final ConnectService _service = ConnectService();
  final UserService _userService = UserService();
  late TabController _tabController;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ConnectDetailScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleDelete(ConnectModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ConnectDetailScreenConstants.deleteConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          ConnectDetailScreenConstants.deleteConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              ConnectDetailScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ConnectDetailScreenConstants.confirmDeleteLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteConnect(c.id);
    if (!mounted) return;
    _snack(
      const CustomSnackBar.success(
        message: ConnectDetailScreenConstants.deleteSuccessMessage,
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
    return StreamBuilder<ConnectModel?>(
      stream: _service.streamConnectById(widget.connectId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
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
        final c = snap.data;
        if (c == null) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _appBar(null),
            body: Center(
              child: Text(
                'Connect not found.',
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
          appBar: _appBar(c),
          body: Column(
            children: [
              _tabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_overviewTab(c), _pairsTab(c), _statsTab(c)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(ConnectModel? c) => AppBar(
    backgroundColor: GeneralConstants.backgroundColor,
    toolbarHeight: GeneralConstants.appBarHeight,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: GeneralConstants.primaryColor),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      c?.title ?? ConnectDetailScreenConstants.appBarTitle,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.lexend(
        fontSize: Utils.isMobile(context)
            ? GeneralConstants.smallTitleSize
            : GeneralConstants.mediumTitleSize,
        fontWeight: FontWeight.w200,
        color: GeneralConstants.primaryColor,
      ),
    ),
    actions: c != null ? _actions(c) : null,
  );

  List<Widget> _actions(ConnectModel c) {
    if (c.authorId != _uid) return [];
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
                builder: (_) => ConnectCreateEditScreen(connect: c),
              ),
            );
          } else if (v == 'delete') {
            _handleDelete(c);
          }
        },
        itemBuilder: (_) => [
          _popup(
            'edit',
            Icons.edit_outlined,
            ConnectDetailScreenConstants.editLabel,
            GeneralConstants.primaryColor,
          ),
          _popup(
            'delete',
            Icons.delete_outline,
            ConnectDetailScreenConstants.deleteLabel,
            GeneralConstants.failureColor,
          ),
        ],
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  PopupMenuItem<String> _popup(String v, IconData i, String l, Color c) =>
      PopupMenuItem<String>(
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

  Widget _tabBar() => Container(
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
        Tab(text: ConnectDetailScreenConstants.overviewTab),
        Tab(text: ConnectDetailScreenConstants.pairsTab),
        Tab(text: ConnectDetailScreenConstants.statisticsTab),
      ],
    ),
  );

  EdgeInsets _pad() => EdgeInsets.symmetric(
    horizontal: Utils.isMobile(context)
        ? GeneralConstants.smallMargin
        : MediaQuery.of(context).size.width * 0.2,
    vertical: GeneralConstants.smallMargin,
  );

  Widget _overviewTab(ConnectModel c) {
    final my = c.attemptsForUser(_uid);
    return SingleChildScrollView(
      padding: _pad(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow(c, my),
          SizedBox(height: ConnectDetailScreenConstants.sectionSpacing),
          _startBtn(c),
          SizedBox(height: ConnectDetailScreenConstants.sectionSpacing),
          _info(
            ConnectDetailScreenConstants.descriptionLabel,
            Icons.description_outlined,
            child: Text(
              c.description.isEmpty
                  ? ConnectDetailScreenConstants.noDescriptionLabel
                  : c.description,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: c.description.isEmpty
                    ? GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      )
                    : GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
          _info(
            ConnectDetailScreenConstants.tagsLabel,
            Icons.tag,
            child: c.tags.isEmpty
                ? Text(
                    ConnectDetailScreenConstants.noTagsLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: ConnectDetailScreenConstants.tagChipSpacing,
                    runSpacing: ConnectDetailScreenConstants.tagChipSpacing,
                    children: c.tags.map(_tagChip).toList(),
                  ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
          _info(
            ConnectDetailScreenConstants.timeLimitLabel,
            Icons.timer_outlined,
            child: Text(
              c.hasTimeLimit
                  ? _fmtTime(c.timeLimit!)
                  : ConnectDetailScreenConstants.noTimeLimitLabel,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: c.hasTimeLimit
                    ? GeneralConstants.primaryColor
                    : GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
              ),
            ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
          _info(
            ConnectDetailScreenConstants.createdLabel,
            Icons.calendar_today_outlined,
            child: Text(
              _fmtDate(c.createdAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
          _info(
            ConnectDetailScreenConstants.updatedLabel,
            Icons.update_outlined,
            child: Text(
              _fmtDate(c.updatedAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _statRow(ConnectModel c, List<ConnectAttempt> my) => Row(
    children: [
      Expanded(
        child: _stat(
          c.pairCount.toString(),
          ConnectDetailScreenConstants.pairsCountLabel,
          Icons.link,
        ),
      ),
      SizedBox(width: ConnectDetailScreenConstants.fieldSpacing),
      Expanded(
        child: _stat(
          c.attemptCount.toString(),
          ConnectDetailScreenConstants.attemptsCountLabel,
          Icons.people_outline,
        ),
      ),
      SizedBox(width: ConnectDetailScreenConstants.fieldSpacing),
      Expanded(
        child: _stat(
          '${c.averageAccuracy.toStringAsFixed(0)}%',
          ConnectDetailScreenConstants.avgAccuracyLabel,
          Icons.analytics_outlined,
        ),
      ),
      SizedBox(width: ConnectDetailScreenConstants.fieldSpacing),
      Expanded(
        child: _stat(
          my.length.toString(),
          ConnectDetailScreenConstants.yourAttemptsLabel,
          Icons.person_outline,
        ),
      ),
    ],
  );

  Widget _stat(String val, String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: GeneralConstants.smallPadding,
    ),
    decoration: BoxDecoration(
      color: GeneralConstants.secondaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(
        ConnectDetailScreenConstants.cardBorderRadius,
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
            fontSize: ConnectDetailScreenConstants.statFontSize,
            fontWeight: FontWeight.w600,
            color: GeneralConstants.primaryColor,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: ConnectDetailScreenConstants.statLabelFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor.withValues(
              alpha: GeneralConstants.smallOpacity,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _startBtn(ConnectModel c) => SizedBox(
    width: double.infinity,
    height: ConnectDetailScreenConstants.startButtonHeight,
    child: ElevatedButton.icon(
      onPressed: c.pairs.isNotEmpty
          ? () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ConnectScreen(connect: c),
              ),
            )
          : null,
      icon: const Icon(
        Icons.play_arrow_rounded,
        color: GeneralConstants.backgroundColor,
      ),
      label: Text(
        ConnectDetailScreenConstants.startLabel,
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

  Widget _info(String title, IconData icon, {required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GeneralConstants.smallPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ConnectDetailScreenConstants.cardBorderRadius,
          ),
          border: Border.all(
            color: GeneralConstants.primaryColor.withValues(
              alpha: ConnectDetailScreenConstants.cardBorderOpacity,
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
                        ConnectDetailScreenConstants.sectionHeaderFontSize,
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

  Widget _tagChip(String tag) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: ConnectDetailScreenConstants.badgeHorizontalPadding,
      vertical: ConnectDetailScreenConstants.badgeVerticalPadding,
    ),
    decoration: BoxDecoration(
      color: GeneralConstants.tertiaryColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(GeneralConstants.smallCircularRadius),
    ),
    child: Text(
      tag,
      style: GoogleFonts.lexend(
        fontSize: ConnectDetailScreenConstants.badgeFontSize,
        fontWeight: FontWeight.w300,
        color: GeneralConstants.secondaryColor,
      ),
    ),
  );

  Widget _pairsTab(ConnectModel c) {
    if (c.pairs.isEmpty) {
      return Center(
        child: Text(
          ConnectDetailScreenConstants.noPairsMessage,
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
      itemCount: c.pairs.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
      itemBuilder: (_, i) => _pairPreview(c.pairs[i], i),
    );
  }

  Widget _pairPreview(ConnectPair pair, int i) => Container(
    padding: const EdgeInsets.all(GeneralConstants.smallPadding),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        ConnectDetailScreenConstants.cardBorderRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: ConnectDetailScreenConstants.cardBorderOpacity,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ConnectDetailScreenConstants.cardNumberSize,
          height: ConnectDetailScreenConstants.cardNumberSize,
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
                    ConnectDetailScreenConstants.questionSideLabel,
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
              Row(
                children: [
                  _sideBadge(
                    ConnectDetailScreenConstants.answerSideLabel,
                    GeneralConstants.successColor,
                  ),
                  const SizedBox(width: GeneralConstants.smallSpacing),
                  Expanded(
                    child: Text(
                      pair.answer,
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

  Widget _sideBadge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      l,
      style: GoogleFonts.lexend(
        fontSize: ConnectDetailScreenConstants.badgeFontSize,
        fontWeight: FontWeight.w600,
        color: c,
      ),
    ),
  );

  Widget _statsTab(ConnectModel c) {
    if (c.attempts.isEmpty) {
      return Center(
        child: Text(
          ConnectDetailScreenConstants.noAttemptsMessage,
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
    final my = c.attemptsForUser(_uid);
    final all = List<ConnectAttempt>.from(c.attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final uids = c.attempts.map((a) => a.userId).toSet().toList();

    return SingleChildScrollView(
      padding: _pad(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leaderboard(c, uids),
          SizedBox(height: ConnectDetailScreenConstants.sectionSpacing),
          if (my.isNotEmpty) ...[
            _sectionLabel(ConnectDetailScreenConstants.myAttemptsLabel),
            SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
            ...my.map(
              (a) => Padding(
                padding: EdgeInsets.only(
                  bottom: ConnectDetailScreenConstants.fieldSpacing,
                ),
                child: _attemptCard(a, c.pairCount),
              ),
            ),
          ],
          _sectionLabel(ConnectDetailScreenConstants.allAttemptsLabel),
          SizedBox(height: ConnectDetailScreenConstants.fieldSpacing),
          ...all.map(
            (a) => Padding(
              padding: EdgeInsets.only(
                bottom: ConnectDetailScreenConstants.fieldSpacing,
              ),
              child: _attemptCardUser(a, c.pairCount),
            ),
          ),
          SizedBox(height: ConnectDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _leaderboard(ConnectModel c, List<String> uids) =>
      FutureBuilder<List<UserModel>>(
        future: _userService.getUsersByIds(uids),
        builder: (context, snap) {
          final users = snap.data ?? [];
          final map = {for (final u in users) u.id: u};
          final entries = <_LB>[];
          for (final uid in uids) {
            final ua = c.attemptsForUser(uid);
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
                ConnectDetailScreenConstants.cardBorderRadius,
              ),
              border: Border.all(
                color: GeneralConstants.primaryColor.withValues(
                  alpha: ConnectDetailScreenConstants.cardBorderOpacity,
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
                            ConnectDetailScreenConstants.sectionHeaderFontSize,
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
              fontSize: ConnectDetailScreenConstants.badgeFontSize,
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

  Widget _attemptCard(ConnectAttempt a, int total) => Container(
    padding: const EdgeInsets.all(GeneralConstants.smallPadding),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        ConnectDetailScreenConstants.cardBorderRadius,
      ),
      border: Border.all(
        color: GeneralConstants.primaryColor.withValues(
          alpha: ConnectDetailScreenConstants.cardBorderOpacity,
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
                    '${a.correct} ${ConnectDetailScreenConstants.correctLabel}',
                    style: GoogleFonts.lexend(
                      fontSize: ConnectDetailScreenConstants.badgeFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.successColor,
                    ),
                  ),
                  const SizedBox(width: GeneralConstants.smallSpacing),
                  Text(
                    '${a.incorrect} ${ConnectDetailScreenConstants.incorrectLabel}',
                    style: GoogleFonts.lexend(
                      fontSize: ConnectDetailScreenConstants.badgeFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.failureColor,
                    ),
                  ),
                  const SizedBox(width: GeneralConstants.smallSpacing),
                  Text(
                    '${a.total}/$total',
                    style: GoogleFonts.lexend(
                      fontSize: ConnectDetailScreenConstants.badgeFontSize,
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

  Widget _attemptCardUser(
    ConnectAttempt a,
    int total,
  ) => FutureBuilder<UserModel?>(
    future: _userService.getUserById(a.userId),
    builder: (context, snap) {
      final u = snap.data;
      final name = u?.username ?? 'Unknown';
      final pic = u?.profilePic ?? '';
      return Container(
        padding: const EdgeInsets.all(GeneralConstants.smallPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ConnectDetailScreenConstants.cardBorderRadius,
          ),
          border: Border.all(
            color: GeneralConstants.primaryColor.withValues(
              alpha: ConnectDetailScreenConstants.cardBorderOpacity,
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
                        '${a.correct}/${a.total}',
                        style: GoogleFonts.lexend(
                          fontSize: ConnectDetailScreenConstants.badgeFontSize,
                          fontWeight: FontWeight.w300,
                          color: GeneralConstants.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: GeneralConstants.smallSpacing),
                      Text(
                        _fmtDate(a.completedAt),
                        style: GoogleFonts.lexend(
                          fontSize: ConnectDetailScreenConstants.badgeFontSize,
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

  Widget _accBadge(double acc) {
    final Color cl;
    if (acc >= 80) {
      cl = GeneralConstants.successColor;
    } else if (acc >= 50) {
      cl = GeneralConstants.tertiaryColor;
    } else {
      cl = GeneralConstants.failureColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ConnectDetailScreenConstants.badgeHorizontalPadding,
        vertical: ConnectDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: cl.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        '${acc.toStringAsFixed(0)}%',
        style: GoogleFonts.lexend(
          fontSize: ConnectDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: cl,
        ),
      ),
    );
  }

  Widget _sectionLabel(String l) => Text(
    l,
    style: GoogleFonts.lexend(
      fontSize: ConnectDetailScreenConstants.sectionHeaderFontSize,
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
