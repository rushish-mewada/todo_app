import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../models/todo.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get userTaskCollection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  static Future<void> syncWithFirestore() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print('[Sync] Skipped: No internet');
      return;
    }

    final box = Hive.box<Todo>('todos');
    print('[Sync] Running syncWithFirestore...');

    for (var key in box.keys) {
      final todo = box.get(key);
      if (todo == null) continue;

      final isDeleted = todo.isDeleted ?? false;
      final needsUpdate = todo.needsUpdate ?? false;

      // 1. ADD to Firestore if new (no firebaseId)
      if (todo.firebaseId == null && !isDeleted) {
        final docId = await _addToFirestore(todo);
        if (docId != null) {
          todo.firebaseId = docId;
          await todo.save();
          print('[Sync] Added: ${todo.title}');
        }
      }

      // 2. UPDATE in Firestore if needed
      else if (todo.firebaseId != null && needsUpdate && !isDeleted) {
        await _updateInFirestore(todo.firebaseId!, todo);
        todo.needsUpdate = false;
        await todo.save();
        print('[Sync] Updated: ${todo.title}');
      }

      // 3. DELETE from Firestore if marked deleted
      else if (todo.firebaseId != null && isDeleted) {
        await _deleteFromFirestore(todo.firebaseId!);
        await todo.delete(); // Remove from Hive
        print('[Sync] Deleted: ${todo.title}');
      }
    }
  }

  static Future<String?> _addToFirestore(Todo todo) async {
    try {
      final docRef = await userTaskCollection.add({
        'title': todo.title,
        'description': todo.description,
        'emoji': todo.emoji,
        'date': todo.date,
        'time': todo.time,
        'priority': todo.priority,
        'status': todo.status,
        'isCompleted': todo.isCompleted,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('[Sync] Error adding: $e');
      return null;
    }
  }

  static Future<void> _updateInFirestore(String firebaseId, Todo todo) async {
    try {
      await userTaskCollection.doc(firebaseId).update({
        'title': todo.title,
        'description': todo.description,
        'emoji': todo.emoji,
        'date': todo.date,
        'time': todo.time,
        'priority': todo.priority,
        'status': todo.status,
        'isCompleted': todo.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[Sync] Error updating: $e');
    }
  }

  static Future<void> _deleteFromFirestore(String firebaseId) async {
    try {
      await userTaskCollection.doc(firebaseId).delete();
    } catch (e) {
      print('[Sync] Error deleting: $e');
    }
  }

  /// 🔄 Auto-sync when internet reconnects
  static void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('[Sync] Internet back! Triggering sync...');
        syncWithFirestore();
      }
    });
  }
}
