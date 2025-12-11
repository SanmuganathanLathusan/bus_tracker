// lib/driver_screen/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  final Function({
    String? name,
    String? busNumber,
    String? busName,
    String? profileImage,
  })? onProfileUpdated;

  const ProfilePage({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  String name = "";
  String driverId = "";
  String licenseNumber = "";
  String contact = "";
  String email = "";
  String busNumber = "";
  String? busName;
  String? profileImageUrl;

  File? _profileImageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ------------------------
  // SAME FUNCTIONS
  // ------------------------
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _profileService.getProfile();
      final user = response['user'];

      if (!mounted) return;
      setState(() {
        name = user['userName'] ?? '';
        driverId = user['id'] ?? '';
        licenseNumber = user['licenseNumber'] ?? '';
        contact = user['phone'] ?? '';
        email = user['email'] ?? '';
        busNumber = user['busNumber'] ?? 'Not Assigned';
        busName = user['busName'];
        profileImageUrl = user['profileImage'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1500,
        maxHeight: 1500,
      );
      if (picked != null) {
        setState(() => _profileImageFile = File(picked.path));
        widget.onProfileUpdated?.call(profileImage: picked.path);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take a photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          if (_profileImageFile != null)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Remove picture"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _profileImageFile = null);
                widget.onProfileUpdated?.call(profileImage: null);
              },
            ),
        ]),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final response = await _profileService.updateProfile(
        userName: name,
        phone: contact,
        licenseNumber: licenseNumber,
        profileImage: _profileImageFile,
      );

      final user = response['user'];

      if (!mounted) return;

      setState(() {
        name = user['userName'] ?? name;
        contact = user['phone'] ?? contact;
        licenseNumber = user['licenseNumber'] ?? licenseNumber;
        busNumber = user['busNumber'] ?? busNumber;
        busName = user['busName'];
        profileImageUrl = user['profileImage'];
        _isSaving = false;
      });

      widget.onProfileUpdated?.call(
        name: name,
        busNumber: busNumber,
        busName: busName,
        profileImage: profileImageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEditableField({
    required String label,
    required String initialValue,
    bool readOnly = false,
    FormFieldSetter<String>? onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        border: const UnderlineInputBorder(),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text("Logout", style: AppTextStyles.subHeading),
        content: Text("Are you sure?", style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/welcome",
                (route) => false,
              );
            },
            child: Text("Logout",
                style: TextStyle(color: AppColors.accentError)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  //                UPDATED UI (Same Logic, Cleaner)
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Driver Profile", style: AppTextStyles.heading),
            const SizedBox(height: 20),

            // ------------------ PROFILE CARD ------------------
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // ------------------ EDIT SECTION ------------------
            Text("Edit Information", style: AppTextStyles.subHeading),
            const SizedBox(height: 10),
            _buildEditableCard(),

            const SizedBox(height: 25),

            // ------------------ SAVE BUTTON ------------------
            _buildSaveButton(),
            const SizedBox(height: 15),

            // ------------------ LOGOUT BUTTON ------------------
            _buildLogoutButton(),
          ]),
        ),
      ),
    );
  }

  // ------------------------
  //   CLEANER UI WIDGETS
  // ------------------------
  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      color: AppColors.backgroundSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageOptions,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: _profileImageFile != null
                    ? FileImage(_profileImageFile!)
                    : (profileImageUrl != null)
                        ? NetworkImage("http://10.0.2.2:5000$profileImageUrl")
                        : const NetworkImage(
                            "https://randomuser.me/api/portraits/men/1.jpg"),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: AppTextStyles.title),
            Text("Senior Driver", style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableCard() {
    return Card(
      elevation: 3,
      color: AppColors.backgroundSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildEditableField(
            label: "Full Name",
            initialValue: name,
            onSaved: (v) => name = v ?? name,
            validator: (v) =>
                (v == null || v.isEmpty) ? "Enter valid name" : null,
          ),
          _buildEditableField(
            label: "Driver ID",
            initialValue: driverId,
            readOnly: true,
          ),
          _buildEditableField(
            label: "License Number",
            initialValue: licenseNumber,
            onSaved: (v) => licenseNumber = v ?? licenseNumber,
          ),
          _buildEditableField(
            label: "Contact Number",
            initialValue: contact,
            onSaved: (v) => contact = v ?? contact,
          ),
          _buildEditableField(
            label: "Email",
            initialValue: email,
            onSaved: (v) => email = v ?? email,
          ),
          _buildEditableField(
            label: "Assigned Bus",
            initialValue:
                busName != null ? "$busNumber - $busName" : busNumber,
            readOnly: true,
          ),
        ]),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveProfile,
      icon: _isSaving
          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
          : const Icon(Icons.save),
      label: Text(_isSaving ? "Saving..." : "Save Changes"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () => _showLogoutDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentError,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: const Text("Logout"),
    );
  }
}
