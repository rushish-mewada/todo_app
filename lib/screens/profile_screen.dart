import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../models/user_profile.dart';
import '../widgets/bot_nav.dart';
import '../providers/auth_provider.dart';
import '../widgets/edit_profile.dart';
import '../widgets/logout_modal.dart';
import '../models/todo.dart'; // Import the Todo model if not already

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _localProfileImageFile;
  bool _isUploading = false;
  bool _isLoadingProfile = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;
  String? _userRole;

  late Box<UserProfile> _profileBox;
  late Box<Todo> _todoBox; // Declare Todo box

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profile');
    _todoBox = Hive.box<Todo>('todos'); // Initialize Todo box
    _loadDataFromHiveAndSync();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromHiveAndSync() async {
    if (mounted) setState(() => _isLoadingProfile = true);

    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    UserProfile? cachedProfile = _profileBox.get(user.uid);
    if (cachedProfile != null) {
      _updateUIFromProfile(cachedProfile);
    } else {
      _nameController.text = user.displayName ?? 'John Doe';
      _emailController.text = user.email ?? 'john.doe@example.com';
      _phoneController.text = 'N/A';
      _selectedGender = 'Male';
      _userRole = 'Marketing Manager';
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      await _syncFirebaseToHive();
    } else {
      if (cachedProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: Could not load profile. Please check your internet connection.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: Displaying your cached profile.')),
          );
        }
      }
    }

    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<void> _syncFirebaseToHive() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final newProfile = UserProfile(
          uid: user.uid,
          name: user.displayName ?? 'John Doe',
          email: user.email ?? 'john.doe@example.com',
          phoneNumber: 'N/A',
          gender: 'Male',
          role: 'Marketing Manager',
          remoteProfileUrl: null,
          localProfilePath: null,
        );
        await _profileBox.put(user.uid, newProfile);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': newProfile.uid,
          'name': newProfile.name,
          'email': newProfile.email,
          'phoneNumber': newProfile.phoneNumber,
          'gender': newProfile.gender,
          'role': newProfile.role,
          'profileImgUrl': newProfile.remoteProfileUrl,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _updateUIFromProfile(newProfile);
        return;
      }

      final userData = userDoc.data()!;
      final remoteUrl = userData['profileImgUrl'];
      String? localPath;

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        localPath = await _downloadAndCacheImage(remoteUrl, user.uid);
      }

      final updatedProfile = UserProfile(
        uid: user.uid,
        name: userData['name'] ?? user.displayName ?? 'John Doe',
        email: userData['email'] ?? user.email ?? 'john.doe@example.com',
        phoneNumber: userData['phoneNumber'],
        gender: userData['gender'],
        role: userData['role'],
        remoteProfileUrl: remoteUrl,
        localProfilePath: localPath,
      );

      await _profileBox.put(user.uid, updatedProfile);
      _updateUIFromProfile(updatedProfile);
    } catch (e) {
      print("Error syncing from Firebase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile from online. Please check your internet connection.')),
        );
      }
    }
  }

  void _updateUIFromProfile(UserProfile profile) {
    if (mounted) {
      setState(() {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? '';
        _selectedGender = profile.gender;
        _userRole = profile.role;
        if (profile.localProfilePath != null && File(profile.localProfilePath!).existsSync()) {
          _localProfileImageFile = File(profile.localProfilePath!);
        } else {
          _localProfileImageFile = null;
        }
      });
    }
  }

  Future<String?> _downloadAndCacheImage(String url, String userId) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final appDocDir = await getApplicationDocumentsDirectory();
        final localPath = '${appDocDir.path}/profile_$userId.jpg';
        final file = File(localPath);
        await file.writeAsBytes(bytes);
        return localPath;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final pickedFile = File(image.path);
      final appDocDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDocDir.path}/profile_${user.uid}.jpg';
      final localFile = await pickedFile.copy(localPath);

      setState(() => _localProfileImageFile = localFile);
      UserProfile? profile = _profileBox.get(user.uid);
      if (profile != null) {
        profile.localProfilePath = localPath;
        await profile.save();
      } else {
        final newProfile = UserProfile(
          uid: user.uid,
          name: user.displayName ?? 'John Doe',
          email: user.email ?? 'john.doe@example.com',
          localProfilePath: localPath,
        );
        await _profileBox.put(user.uid, newProfile);
      }

      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final userEmail = user.email;
        if (userEmail == null) throw Exception('User email is not available.');

        final destination = 'avatars/$userEmail/profile_image.jpg';
        final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
        await ref.putFile(localFile);
        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImgUrl': imageUrl,
        });

        if (profile != null) {
          profile.remoteProfileUrl = imageUrl;
          await profile.save();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved locally. Will upload when online.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update image. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
          initialRole: _userRole,
          onSave: (newName, newEmail, newPhone, newGender, newRole) async {
            final user = fb_auth.FirebaseAuth.instance.currentUser;
            if (user != null) {
              setState(() {
                _nameController.text = newName;
                _emailController.text = newEmail;
                _phoneController.text = newPhone;
                _selectedGender = newGender;
                _userRole = newRole;
              });
              Navigator.pop(context);

              UserProfile? profile = _profileBox.get(user.uid);
              if (profile != null) {
                profile.name = newName;
                profile.email = newEmail;
                profile.phoneNumber = newPhone;
                profile.gender = newGender;
                profile.role = newRole;
                await profile.save();
              } else {
                final newProfile = UserProfile(
                  uid: user.uid,
                  name: newName,
                  email: newEmail,
                  phoneNumber: newPhone,
                  gender: newGender,
                  role: newRole,
                );
                await _profileBox.put(user.uid, newProfile);
              }

              final connectivityResult = await (Connectivity().checkConnectivity());
              if (connectivityResult != ConnectivityResult.none) {
                try {
                  if (newName != user.displayName) {
                    await user.updateDisplayName(newName);
                  }
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                    'name': newName,
                    'email': newEmail,
                    'phoneNumber': newPhone,
                    'gender': newGender,
                    'role': newRole,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save updates. Please check your internet connection.')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated locally. Will upload when online.')),
                  );
                }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reset email. Please try again.')),
        );
      }
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
        final user = fb_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Remove user's profile data from Hive upon logout
          await _profileBox.delete(user.uid);
          // Clear all Todo data from Hive upon logout
          await _todoBox.clear();
          // Optionally clear other boxes related to the user if they contain user-specific data
          await Hive.box('dismissed_notifications').clear();
          await Hive.box('previous_todo_data').clear();
          await Hive.box('active_change_notification_keys').clear();
          await Hive.box('shown_notifications').clear();
        }
        await Provider.of<AuthProvider>(context, listen: false).signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to log out. Please try again.')),
          );
        }
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
                      child: _isLoadingProfile
                          ? const CircularProgressIndicator(
                        color: Color(0xFFEB5E00),
                      )
                          : _localProfileImageFile == null
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
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                if (_userRole != null && _userRole!.isNotEmpty)
                  Text(
                    _userRole!,
                    style: const TextStyle(
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
