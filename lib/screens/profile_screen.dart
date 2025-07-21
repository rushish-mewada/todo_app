import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/bot_nav.dart';
import '../providers/auth_provider.dart';
import '../widgets/edit_profile.dart';
import '../widgets/logout_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? 'John Doe';
      _emailController.text = user.email ?? 'john.doe@example.com';

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        _phoneController.text = userData?['phoneNumber'] ?? 'N/A';
        _selectedGender = userData?['gender'];
        final localImagePath = userData?['profileImg'];

        if (localImagePath != null && localImagePath.isNotEmpty) {
          final file = File(localImagePath);
          if (await file.exists()) {
            _profileImageFile = file;
          } else {
            _profileImageFile = null;
          }
        } else {
          _profileImageFile = null;
        }
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'John Doe',
          'email': user.email ?? 'john.doe@example.com',
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': 'N/A',
          'gender': 'Male',
          'profileImg': null,
        }, SetOptions(merge: true));
      }
      setState(() {});
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDocDir.path}/profile_images');

      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      final localPath = '${profileImagesDir.path}/${fb_auth.FirebaseAuth.instance.currentUser!.uid}_profile.jpg';
      final newImageFile = await File(image.path).copy(localPath);

      setState(() {
        _profileImageFile = newImageFile;
      });

      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {'profileImg': localPath},
          SetOptions(merge: true),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image Updated!')),
      );
    }
  }

  Future<void> _showEditProfileModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditProfileModal(
          initialName: _nameController.text,
          initialEmail: _emailController.text,
          initialPhone: _phoneController.text,
          initialGender: _selectedGender,
          onSave: (newName, newEmail, newPhone, newGender) async {
            final user = fb_auth.FirebaseAuth.instance.currentUser;
            if (user != null) {
              try {
                if (newName != user.displayName) {
                  await user.updateDisplayName(newName);
                }

                await _firestore.collection('users').doc(user.uid).set({
                  'name': newName,
                  'email': newEmail,
                  'phoneNumber': newPhone,
                  'gender': newGender,
                }, SetOptions(merge: true));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
                Navigator.pop(context);
              } on fb_auth.FirebaseAuthException catch (e) {
                String message = 'Failed to update profile: ${e.message}';
                if (e.code == 'requires-recent-login') {
                  message = 'Please re-login to update your email/password.';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('An unexpected error occurred: $e')),
                );
              }
            }
          },
        );
      },
    );
    _loadUserData();
  }

  Future<void> _changePassword() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
      return;
    }

    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox to reset your password.'),
          duration: Duration(seconds: 5),
        ),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else {
        message = 'Failed to send password reset email: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return const LogoutModal();
      },
    );

    if (confirmLogout == true) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const double profilePictureRadius = 60;

    final double backgroundImageEndPercentage = 0.30;

    final double backgroundHeight = screenHeight * backgroundImageEndPercentage;

    final double profilePictureTop = backgroundHeight - profilePictureRadius;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: backgroundHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/profilebg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Positioned(
            top: profilePictureTop,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: profilePictureRadius,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImageFile != null
                          ? FileImage(_profileImageFile!)
                          : null,
                      child: _profileImageFile == null
                          ? Icon(
                        Icons.person,
                        size: profilePictureRadius * 4 / 3,
                        color: Colors.grey[600],
                      )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFEB5E00),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: profilePictureTop + (2 * profilePictureRadius) + 16,
            child: Column(
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Text(
                      authProvider.currentUser?.displayName ?? _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  "Marketing Manager",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    children: [
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/editprofile.png',
                        title: "Edit Profile",
                        onTap: _showEditProfileModal,
                        iconColor: const Color(0xFFEB5E00),
                        textColor: const Color(0xFF505050),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/changepass.png',
                        title: "Change Password",
                        onTap: _changePassword,
                        iconColor: const Color(0xFFEB5E00),
                        textColor: const Color(0xFF505050),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/logout.png',
                        title: "Log out",
                        onTap: _showLogoutConfirmation,
                        iconColor: const Color(0xFFE91E63),
                        textColor: const Color(0xFF505050),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BotNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/notifications');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/calendar');
          }
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color textColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  imagePath,
                  width: 40,
                  height: 40,
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
              ],
            ),
            if (title != "Log out")
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 48.0),
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  height: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
