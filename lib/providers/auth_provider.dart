import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/todo.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> loginWithEmail(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _currentUser = userCredential.user;
      notifyListeners();

      await _syncTodosFromFirestoreToHive(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful")),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code.trim().toLowerCase()) {
        case 'user-not-found':
          message = "No user found with this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          message = "The email address is not valid.";
          break;
        case 'too-many-requests':
          message = "Too many failed login attempts. Please try again later.";
          break;
        default:
          message = "Login failed. Please check your credentials.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred during login.")),
      );
    }
  }

  Future<void> _syncTodosFromFirestoreToHive(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    try {
      final todoBox = Hive.box<Todo>('todos');
      final todoCollection = _firestore.collection('users').doc(user.uid).collection('todos');

      final querySnapshot = await todoCollection.get();

      await todoBox.clear();

      for (var doc in querySnapshot.docs) {
        final todoData = doc.data();
        final todo = Todo.fromMap(todoData);
        await todoBox.put(doc.id, todo);
      }
    } catch (e) {
      print('Error syncing todo data on login: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> signupWithEmail({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      _currentUser = user;

      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': 'N/A',
          'gender': 'Male',
          'role': 'User',
          'profileImgUrl': null,
        });
      }
      notifyListeners();
      await _syncTodosFromFirestoreToHive(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code.trim().toLowerCase()) {
        case 'weak-password':
          message = "The password is too weak.";
          break;
        case 'email-already-in-use':
          message = "An account already exists for this email.";
          break;
        case 'invalid-email':
          message = "The email address is not valid.";
          break;
        default:
          message = "Registration failed. Please try again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred during registration.")),
      );
      return false;
    }
  }
}
