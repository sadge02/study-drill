import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService();

    return StreamBuilder<GroupModel?>(
      stream: groupService.getGroupStream(groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final group = snapshot.data!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    group.profilePic,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: GoogleFonts.lexend(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            group.visibility == GroupVisibility.private
                                ? Icons.lock
                                : Icons.public,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        group.summary,
                        style: GoogleFonts.lexend(color: Colors.grey[700]),
                      ),
                      const Divider(height: 40),

                      _buildInfoRow(
                        Icons.people,
                        '${group.userIds.length} Members',
                      ),
                      _buildInfoRow(
                        Icons.quiz,
                        '${group.testIds.length} Tests',
                      ),
                      _buildInfoRow(
                        Icons.style,
                        '${group.flashcardIds.length} Flashcards',
                      ),

                      const SizedBox(height: 30),

                      // Action Button Logic
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => groupService.joinGroup(group),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Text(
                            'Join Group',
                            style: GoogleFonts.lexend(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.lexend(fontSize: 16)),
        ],
      ),
    );
  }
}
