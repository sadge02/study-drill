import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';

class CreateEditGroupScreen extends StatefulWidget {
  final GroupModel? group; // If null, we are creating. If not, we are editing.
  const CreateEditGroupScreen({super.key, this.group});

  @override
  State<CreateEditGroupScreen> createState() => _CreateEditGroupScreenState();
}

class _CreateEditGroupScreenState extends State<CreateEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupService _groupService = GroupService();

  late TextEditingController _nameController;
  late TextEditingController _summaryController;
  late TextEditingController _picController;
  late GroupVisibility _visibility;
  late bool _autoAddAsEditor;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing, or defaults if creating
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _summaryController = TextEditingController(
      text: widget.group?.summary ?? '',
    );
    _picController = TextEditingController(
      text: widget.group?.profilePic ?? '',
    );
    _visibility = widget.group?.visibility ?? GroupVisibility.public;
    _autoAddAsEditor = widget.group?.settings?.autoAddAsEditor ?? false;
  }

  void _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      final settings = GroupSettings(autoAddAsEditor: _autoAddAsEditor);

      String? error;
      if (widget.group == null) {
        // CREATE LOGIC
        error = await _groupService.createGroup(
          name: _nameController.text.trim(),
          summary: _summaryController.text.trim(),
          profilePic: _picController.text.trim(),
          visibility: _visibility,
          settings: settings,
        );
      } else {
        // EDIT LOGIC
        final updatedGroup = widget.group!.copyWith(
          name: _nameController.text.trim(),
          summary: _summaryController.text.trim(),
          profilePic: _picController.text.trim(),
          visibility: _visibility,
          settings: settings,
        );
        error = await _groupService.updateGroup(updatedGroup);
      }

      if (mounted) {
        if (error == null) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.group != null;

    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Group' : 'Create Group',
          style: GoogleFonts.lexend(),
        ),
        backgroundColor: GeneralConstants.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _picController,
                decoration: const InputDecoration(
                  labelText: 'Profile Picture URL',
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<GroupVisibility>(
                value: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: GroupVisibility.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _visibility = val!),
              ),

              SwitchListTile(
                title: Text(
                  'Auto-add members as editors',
                  style: GoogleFonts.lexend(fontSize: 14),
                ),
                value: _autoAddAsEditor,
                onChanged: (val) => setState(() => _autoAddAsEditor = val),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GeneralConstants.primaryColor,
                  ),
                  child: Text(
                    isEditing ? 'Update Group' : 'Create Group',
                    style: GoogleFonts.lexend(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
