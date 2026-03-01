import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user/user_model.dart';
import '../../utils/constants/core/general_constants.dart';

class FindUsersScreen extends StatefulWidget {
  const FindUsersScreen({super.key});

  @override
  State<FindUsersScreen> createState() => _FindUsersScreenState();
}

class _FindUsersScreenState extends State<FindUsersScreen> {
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
          'Find Users',
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
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      // Using a fallback of 16.0 just in case mediumPadding isn't a double
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
          hintText: 'Search for users...',
          hintStyle: GoogleFonts.lexend(color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search,
            color: GeneralConstants.primaryColor,
          ),
          filled: true,
          // Assuming tertiaryColor is a good background for text fields as used in avatars
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

  Widget _buildUsersList() {
    // Reference your users collection
    Query query = FirebaseFirestore.instance.collection('users');

    if (_searchQuery.isNotEmpty) {
      // Query using the lowercase username field for a case-insensitive prefix search
      query = query
          .where('username_lowercase', isGreaterThanOrEqualTo: _searchQuery)
          .where(
            'username_lowercase',
            isLessThanOrEqualTo: '$_searchQuery\uf8ff',
          )
          .limit(20);
    } else {
      // Show some default users (or you can show an empty state instead)
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
              'Error loading users',
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: GoogleFonts.lexend(color: GeneralConstants.secondaryColor),
            ),
          );
        }

        // Map Firestore documents to your UserModel
        final users = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure ID is passed if your fromJson requires the document ID to be merged
          data['id'] ??= doc.id;
          return UserModel.fromJson(data);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumPadding ?? 16.0,
          ),
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
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
          backgroundImage: NetworkImage(user.profilePic),
          onBackgroundImageError: (_, __) => const Icon(Icons.person),
        ),
        title: Text(
          user.username,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w500,
            color: GeneralConstants.primaryColor,
          ),
        ),
        subtitle: Text(
          user.summary.isNotEmpty ? user.summary : 'No summary available',
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
          // TODO: Navigate to User Profile Screen
          // Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)));
        },
      ),
    );
  }
}
