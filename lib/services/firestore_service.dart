import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/todo.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isSyncing = false;

  static CollectionReference<Map<String, dynamic>> _getCollectionReference(String type) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in. Cannot access Firestore.");

    String collectionName;
    switch (type) {
      case 'Habit':
        collectionName = 'habits';
        break;
      case 'Journal':
        collectionName = 'journals';
        break;
      case 'Note':
        collectionName = 'notes';
        break;
      case 'To-Do':
      default:
        collectionName = 'todos';
    }
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  static Future<void> syncAll() async {
    if (_isSyncing) {
      print('[Sync] Skipped: Another sync is already in progress.');
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('[Sync] Skipped: No internet connection.');
      return;
    }

    _isSyncing = true;
    print('[Sync] Starting two-way sync for all types...');
    try {
      // Sync each type with its own collection
      await _syncType('To-Do');
      await _syncType('Habit');
      await _syncType('Journal');
      await _syncType('Note');
    } catch (e) {
      print('[Sync] Error during syncAll: $e');
    } finally {
      _isSyncing = false;
      print('[Sync] Sync finished for all types.');
    }
  }

  static Future<void> _syncType(String type) async {
    print('[Sync] Syncing type: $type');
    final box = Hive.box<Todo>('todos');
    final localItemsForType = box.values.where((item) => item.type == type).toList();
    final collectionRef = _getCollectionReference(type);

    await _pullRemoteChanges(type, collectionRef, box);
    await _pushLocalChanges(type, collectionRef, localItemsForType, box);
  }

  static Future<void> _pullRemoteChanges(
      String type,
      CollectionReference<Map<String, dynamic>> collectionRef,
      Box<Todo> box) async {
    try {
      final remoteSnapshot = await collectionRef.get();
      final remoteIds = remoteSnapshot.docs.map((doc) => doc.id).toSet();
      final localItemsForType = box.values.where((item) => item.type == type).toList();

      for (final localItem in localItemsForType) {
        if (localItem.firebaseId != null &&
            localItem.firebaseId != 'syncing' &&
            !remoteIds.contains(localItem.firebaseId)) {
          print('[Sync] Deleting local $type removed from remote: ${localItem.title}');
          await localItem.delete();
        }
      }

      final localIdsAfterDeletion = box.values.where((t) => t.type == type).map((t) => t.firebaseId).toSet();
      for (final doc in remoteSnapshot.docs) {
        if (!localIdsAfterDeletion.contains(doc.id)) {
          final data = doc.data();
          final newItem = Todo.fromMap(data)..firebaseId = doc.id;
          await box.add(newItem);
          print('[Sync] Pulled new $type from remote: ${newItem.title}');
        }
      }
    } catch (e) {
      print('[Sync] Error pulling changes for type $type: $e');
    }
  }

  static Future<void> _pushLocalChanges(
      String type,
      CollectionReference<Map<String, dynamic>> collectionRef,
      List<Todo> localItems,
      Box<Todo> box) async {
    for (var item in localItems) {
      final localKey = item.key;

      try {
        if (item.isDeleted == true && item.firebaseId != null && item.firebaseId != 'syncing') {
          await collectionRef.doc(item.firebaseId!).delete();
          await item.delete();
          print('[Sync] Deleted $type from cloud: ${item.title}');
        } else if (item.firebaseId == null) {
          item.firebaseId = 'syncing';
          await item.save();

          final newId = await collectionRef.add(item.toMap());

          final freshItem = box.get(localKey);
          if (freshItem == null) continue;

          if (newId != null) {
            freshItem.firebaseId = newId.id;
            freshItem.needsUpdate = false;
            await freshItem.save();
            print('[Sync] Added $type to cloud: ${freshItem.title}');
          } else {
            freshItem.firebaseId = null;
            await freshItem.save();
          }
        } else if (item.needsUpdate == true && item.firebaseId != null && item.firebaseId != 'syncing') {
          await collectionRef.doc(item.firebaseId!).update(item.toMap());
          item.needsUpdate = false;
          await item.save();
          print('[Sync] Updated $type in cloud: ${item.title}');
        }
      } catch (e) {
        print('[Sync] Error pushing change for $type "${item.title}": $e');
        final erroredItem = box.get(localKey);
        if (erroredItem != null && erroredItem.firebaseId == 'syncing') {
          erroredItem.firebaseId = null;
          await erroredItem.save();
        }
      }
    }
  }

  static void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print('[Sync] Internet connection detected. Triggering sync.');
        syncAll();
      }
    });
  }
}
