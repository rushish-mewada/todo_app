import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  File? _localProfileImageFile;
  bool _isUploading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

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
    if (user == null) return;

    _nameController.text = user.displayName ?? 'John Doe';
    _emailController.text = user.email ?? 'john.doe@example.com';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? 'John Doe',
        'email': user.email ?? 'john.doe@example.com',
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': 'N/A',
        'gender': 'Male',
        'profileImgUrl': null,
        'localProfilePath': null,
      }, SetOptions(merge: true));
      if (mounted) setState(() {});
      return;
    }

    final userData = userDoc.data()!;
    _phoneController.text = userData['phoneNumber'] ?? 'N/A';
    _selectedGender = userData['gender'];
    final localPath = userData['localProfilePath'];
    final remoteUrl = userData['profileImgUrl'];

    if (localPath != null) {
      final localFile = File(localPath);
      if (await localFile.exists()) {
        setState(() {
          _localProfileImageFile = localFile;
        });
        return;
      }
    }

    if (remoteUrl != null) {
      await _downloadAndCacheImage(remoteUrl, user.uid);
    }
  }

  Future<void> _downloadAndCacheImage(String url, String userId) async {
    try {
      // Explicitly define the response type and check the status code
      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final appDocDir = await getApplicationDocumentsDirectory();
        final localPath = '${appDocDir.path}/profile_$userId.jpg';
        final file = File(localPath);
        await file.writeAsBytes(bytes);

        await _firestore.collection('users').doc(userId).update({
          'localProfilePath': localPath,
        });

        if (mounted) {
          setState(() {
            _localProfileImageFile = file;
          });
        }
      } else {
        // Log an error if the download fails
        print('Failed to download image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final userEmail = user.email;
      if (userEmail == null) throw Exception('User email is not available.');

      final pickedFile = File(image.path);

      final appDocDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocDir.path}/profile_${user.uid}.jpg';
      final localFile = await pickedFile.copy(localPath);

      final destination = 'avatars/$userEmail/profile_image.jpg';
      final ref = _storage.ref(destination);
      await ref.putFile(localFile);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImgUrl': imageUrl,
        'localProfilePath': localPath,
      });

      setState(() {
        _localProfileImageFile = localFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
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

                await _firestore.collection('users').doc(user.uid).update({
                  'name': newName,
                  'email': newEmail,
                  'phoneNumber': newPhone,
                  'gender': newGender,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
                Navigator.pop(context);
                _loadUserData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
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
    final double backgroundHeight = screenHeight * 0.30;
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
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: profilePictureRadius,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _localProfileImageFile != null
                          ? FileImage(_localProfileImageFile!)
                          : null,
                      child: _localProfileImageFile == null
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
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEB5E00),
                        child: _isUploading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
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
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/changepass.png',
                        title: "Change Password",
                        onTap: _changePassword,
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        context,
                        imagePath: 'assets/logout.png',
                        title: "Log out",
                        onTap: _showLogoutConfirmation,
                        iconColor: const Color(0xFFE91E63),
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

  Widget _buildMenuItem(
      BuildContext context, {
        required String imagePath,
        required String title,
        required VoidCallback onTap,
        Color? iconColor,
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
        child: Row(
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
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
