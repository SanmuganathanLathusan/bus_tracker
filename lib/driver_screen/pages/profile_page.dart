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
  })?
  onProfileUpdated;

  const ProfilePage({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  // editable fields
  String name = "";
  String driverId = "";
  String licenseNumber = "";
  String contact = "";
  String email = "";
  String busNumber = "";
  String? busName;
  String? profileImageUrl;

  File? _profileImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _profileService.getProfile();
      final user = response['user'] as Map<String, dynamic>;

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
          content: Text('Error loading profile: ${e.toString()}'),
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
      // handle / log error if needed
      debugPrint('Image pick error: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImageFile = null);
                  widget.onProfileUpdated?.call(profileImage: null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isSaving = true);

      try {
        final response = await _profileService.updateProfile(
          userName: name,
          phone: contact,
          licenseNumber: licenseNumber,
          profileImage: _profileImageFile,
        );

        final user = response['user'] as Map<String, dynamic>;

        if (!mounted) return;

        // Update local state
        setState(() {
          name = user['userName'] ?? name;
          contact = user['phone'] ?? contact;
          licenseNumber = user['licenseNumber'] ?? licenseNumber;
          busNumber = user['busNumber'] ?? busNumber;
          busName = user['busName'];
          profileImageUrl = user['profileImage'];
          _isSaving = false;
        });

        // Notify dashboard of profile update
        widget.onProfileUpdated?.call(
          name: name,
          busNumber: busNumber,
          busName: busName,
          profileImage: profileImageUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 150, 208, 245),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Driver Profile", style: AppTextStyles.heading),
              const SizedBox(height: 16),

              // --- Profile Header ---
              Card(
                elevation: 3,
                shadowColor: AppColors.shadowLight,
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _profileImageFile != null
                                  ? FileImage(_profileImageFile!)
                                  : (profileImageUrl != null &&
                                        profileImageUrl!.isNotEmpty)
                                  ? NetworkImage(
                                          'http://10.0.2.2:5000$profileImageUrl',
                                        )
                                        as ImageProvider
                                  : const NetworkImage(
                                      'https://randomuser.me/api/portraits/men/1.jpg',
                                    ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                right: 2,
                                bottom: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.waygoLightBlue,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text("Senior Driver", style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Editable Personal Information ---
              Text("Edit Information", style: AppTextStyles.subHeading),
              const SizedBox(height: 10),

              Card(
                elevation: 3,
                shadowColor: AppColors.shadowLight,
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildEditableField(
                        label: "Full Name",
                        initialValue: name,
                        onSaved: (v) => name = v ?? name,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter a valid name'
                            : null,
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: "Driver ID",
                        initialValue: driverId.substring(
                          0,
                          driverId.length > 12 ? 12 : driverId.length,
                        ),
                        readOnly: true,
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: "License Number",
                        initialValue: licenseNumber,
                        onSaved: (v) => licenseNumber = v ?? licenseNumber,
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: "Contact",
                        initialValue: contact,
                        onSaved: (v) => contact = v ?? contact,
                        validator: (v) => (v == null || v.trim().length < 7)
                            ? 'Enter valid contact'
                            : null,
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: "Email",
                        initialValue: email,
                        onSaved: (v) => email = v ?? email,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          return emailRegex.hasMatch(v)
                              ? null
                              : 'Invalid email';
                        },
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: "Assigned Bus",
                        initialValue: busName != null
                            ? '$busNumber - $busName'
                            : busNumber,
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Save Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "Saving..." : "Save Changes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentError,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Logout", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String initialValue,
    bool readOnly = false,
    FormFieldSetter<String>? onSaved,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodySmall,
          border: InputBorder.none,
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text("Confirm Logout", style: AppTextStyles.subHeading),
        content: Text(
          "Are you sure you want to logout?",
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: AppTextStyles.bodySmall),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog first

              // ✅ Navigate to SignIn screen and clear history
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome', // make sure this route exists in MaterialApp
                (route) => false, // remove all previous routes
              );
            },
            child: Text(
              "Logout",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
