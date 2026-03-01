import 'package:flutter/material.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/models/user/user_model.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;
  // In a real app, you'd fetch these via your UserService/GroupService
  final List<UserModel> groupMembers;
  final UserModel author;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.groupMembers,
    required this.author,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin =
        widget.group.adminIds.contains(widget.currentUserId) ||
        widget.group.authorId == widget.currentUserId;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(isAdmin),
            SliverToBoxAdapter(child: _buildGroupInfo()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: "Materials"),
                    Tab(text: "Members"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildMaterialsTab(), _buildMembersTab()],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {}, // Trigger add test/flashcard/member
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // --- 1. Dynamic Header ---
  SliverAppBar _buildSliverAppBar(bool isAdmin) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // Navigate to Group Settings
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.group.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.group.profilePic, fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Overview Section ---
  Widget _buildGroupInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(widget.group.visibility.name.toUpperCase()),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              const Spacer(),
              Text(
                "Created ${_formatDate(widget.group.createdAt)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.group.summary.isNotEmpty
                ? widget.group.summary
                : "No summary provided.",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (widget.group.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: widget.group.tags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statColumn("Members", widget.group.userIds.length.toString()),
        _statColumn("Tests", widget.group.testIds.length.toString()),
        _statColumn("Flashcards", widget.group.flashcardIds.length.toString()),
      ],
    );
  }

  Widget _statColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // --- 3. Materials Tab ---
  Widget _buildMaterialsTab() {
    // Replace with actual Lists querying testIds, flashcardIds, etc.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.assignment),
          title: Text("Midterm Biology Review (Test)"),
          subtitle: Text("20 questions"),
          trailing: Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: Icon(Icons.style),
          title: Text("Cell Structures (Flashcards)"),
          subtitle: Text("45 cards"),
          trailing: Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // --- 4. Rich Members Tab ---
  Widget _buildMembersTab() {
    return ListView.builder(
      itemCount: widget.groupMembers.length,
      itemBuilder: (context, index) {
        final user = widget.groupMembers[index];
        final isAuthor = widget.group.authorId == user.id;
        final isAdmin = widget.group.adminIds.contains(user.id);
        final isEditor = widget.group.editorUserIds.contains(user.id);

        String roleLabel = "";
        Color roleColor = Colors.grey;

        if (isAuthor) {
          roleLabel = "Owner";
          roleColor = Colors.deepPurple;
        } else if (isAdmin) {
          roleLabel = "Admin";
          roleColor = Colors.blue;
        } else if (isEditor) {
          roleLabel = "Editor";
          roleColor = Colors.green;
        }

        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(user.profilePic)),
          title: Row(
            children: [
              Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (roleLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: roleColor),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(fontSize: 10, color: roleColor),
                  ),
                ),
            ],
          ),
          // Using User details: Summary for flavor text
          subtitle: Text(
            user.summary.isNotEmpty ? user.summary : "No status",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Using User details: Statistics (if you have them structured)
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show modal bottom sheet with full user profile overview
              // check privacy settings before showing stats here!
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

// Helper class for sticky tabs
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
