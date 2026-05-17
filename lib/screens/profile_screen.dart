import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Try to get profile from Firestore
    final data = await _authService.getUserProfile();

    if (mounted) {
      setState(() {
        // If Firestore has data use it, otherwise fallback to Firebase Auth data
        _profile = data ??
            {
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'phone': '',
            };

        // Make sure email is always set from Auth if missing in Firestore
        _profile!['email'] ??= user.email ?? '';

        _nameCtrl.text = _profile?['name'] ?? '';
        _phoneCtrl.text = _profile?['phone'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Profile Picture",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                title: const Text("Take a Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);
      final Uint8List bytes = await file.readAsBytes();
      
      setState(() {
        _selectedImageBase64 = base64Encode(bytes);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        profileImageBase64: _selectedImageBase64,
      );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _profile?['name'] = _nameCtrl.text.trim();
        _profile?['phone'] = _phoneCtrl.text.trim();
        if (_selectedImageBase64 != null) {
          _profile?['profileImage'] = _selectedImageBase64;
        }
        _selectedImageBase64 = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _authService.logout();
    // StreamBuilder in main.dart automatically goes back to LoginScreen
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    final user = _authService.currentUser;
    final displayName = _profile?['name'] ?? user?.displayName ?? 'User';
    final firstLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit',
                  style: TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700)),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _selectedImageBase64 = null;
                _nameCtrl.text = _profile?['name'] ?? '';
                _phoneCtrl.text = _profile?['phone'] ?? '';
              }),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _editing ? _pickImage : null,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: (_selectedImageBase64 == null && (_profile?['profileImage']?.toString().isNotEmpty != true))
                            ? AppColors.gradientAccent
                            : null,
                        color: (_selectedImageBase64 != null || (_profile?['profileImage']?.toString().isNotEmpty == true))
                            ? AppColors.surface
                            : null,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 3),
                        image: (_selectedImageBase64 != null)
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(_selectedImageBase64!)),
                                fit: BoxFit.cover,
                              )
                            : (_profile?['profileImage']?.toString().isNotEmpty == true)
                                ? DecorationImage(
                                    image: MemoryImage(base64Decode(_profile!['profileImage'])),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: (_selectedImageBase64 == null && (_profile?['profileImage']?.toString().isNotEmpty != true))
                          ? Center(
                              child: Text(
                                firstLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (_editing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              _profile?['email'] ?? user?.email ?? '',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // ── Info Card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (_editing) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Save Changes',
                      isLoading: _saving,
                      onPressed: _saveProfile,
                      icon: Icons.save_rounded,
                    ),
                  ] else ...[
                    _infoRow(
                        Icons.person_outline,
                        'Name',
                        _profile?['name']?.toString().isNotEmpty == true
                            ? _profile!['name']
                            : user?.displayName ?? '-'),
                    const Divider(color: AppColors.divider, height: 24),
                    _infoRow(Icons.email_outlined, 'Email',
                        _profile?['email'] ?? user?.email ?? '-'),
                    const Divider(color: AppColors.divider, height: 24),
                    _infoRow(
                        Icons.phone_outlined,
                        'Phone',
                        (_profile?['phone'] == null ||
                                _profile!['phone'].toString().isEmpty)
                            ? 'Not added'
                            : _profile!['phone']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Menu Items ───────────────────────────────────────────────
            _menuItem(
              icon: Icons.receipt_long_outlined,
              label: 'Order History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _menuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _menuItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // ── Seed Database (Hidden Admin Feature) ───────────────────
            _menuItem(
              icon: Icons.cloud_upload_outlined,
              label: 'Seed Database (Upload Dummy Data)',
              onTap: () async {
                try {
                  await ProductService.uploadDummyData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database seeded successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seeding failed: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────────────────
            SecondaryButton(
              label: 'Sign Out',
              onPressed: _logout,
              icon: Icons.logout_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
