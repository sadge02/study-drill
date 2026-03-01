import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Adjust this import path based on where you place this file
import '../../models/group/group_model.dart';
import '../../utils/constants/core/general_constants.dart';

class FindGroupsScreen extends StatefulWidget {
  const FindGroupsScreen({super.key});

  @override
  State<FindGroupsScreen> createState() => _FindGroupsScreenState();
}

class _FindGroupsScreenState extends State<FindGroupsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: GeneralConstants.appBarElevation,
        toolbarHeight: GeneralConstants.appBarHeight,
        iconTheme: const IconThemeData(color: GeneralConstants.primaryColor),
        centerTitle: true,
        title: Text(
          'Find Groups',
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumTitleSize,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildGroupsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(GeneralConstants.mediumPadding ?? 16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
        decoration: InputDecoration(
          hintText: 'Search for group...',
          hintStyle: GoogleFonts.lexend(color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search,
            color: GeneralConstants.primaryColor,
          ),
          filled: true,
          fillColor: GeneralConstants.tertiaryColor ?? Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              GeneralConstants.mediumCircularRadius ?? 12.0,
            ),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    // Reference your group collection
    Query query = FirebaseFirestore.instance.collection('group');

    // Optionally, if you only want to show public group, uncomment below:
    // query = query.where('visibility', isEqualTo: 'public');

    if (_searchQuery.isNotEmpty) {
      // Query using the name_lowercase field defined in your GroupModel
      query = query
          .where('name_lowercase', isGreaterThanOrEqualTo: _searchQuery)
          .where('name_lowercase', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(20);
    } else {
      query = query.limit(20);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading group',
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No group found',
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          );
        }

        // Map Firestore documents to your GroupModel
        final groups = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] ??= doc.id;
          return GroupModel.fromJson(data);
        }).toList();

        return ListView.builder(
          itemCount: groups.length,
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumPadding ?? 16.0,
          ),
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index]);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      color: GeneralConstants.backgroundColor,
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: GeneralConstants.smallSpacing ?? 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius ?? 12.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: GeneralConstants.tertiaryColor,
          backgroundImage: group.profilePic.isNotEmpty
              ? NetworkImage(group.profilePic)
              : null,
          onBackgroundImageError: (_, __) => const Icon(Icons.groups),
          child: group.profilePic.isEmpty ? const Icon(Icons.groups) : null,
        ),
        title: Text(
          group.name, // Uses the 'name' field from GroupModel
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w500,
            color: GeneralConstants.primaryColor,
          ),
        ),
        subtitle: Text(
          group.summary.isNotEmpty ? group.summary : 'No summary available',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lexend(
            color: GeneralConstants.secondaryColor ?? Colors.grey[700],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: GeneralConstants.primaryColor,
        ),
        onTap: () {
          // TODO: Navigate to Group Details Screen
        },
      ),
    );
  }
}
