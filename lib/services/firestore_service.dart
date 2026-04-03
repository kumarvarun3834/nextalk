import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrUpdateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  /// ===============================
  /// CHAT SECTION
  /// ===============================

  /// Create OR get existing chat (prevents duplicates)
  Future<String> createOrGetChat({
    required List<String> participants,
    String? groupName,
  }) async {
    participants.sort(); // IMPORTANT for consistency

    final existing = await _db
        .collection('chats')
        .where('participants', isEqualTo: participants)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _db.collection('chats').add({
      'participants': participants,
      'isGroup': participants.length > 2,
      'groupName': groupName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Get user chats (Home Screen)
  Stream<QuerySnapshot> getUserChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String message,
  }) async {
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    await msgRef.set({
      'senderUid': senderUid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    /// Update chat preview
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> markAsDelivered({
    required String chatId,
    required String currentUid,
  }) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('status', isEqualTo: 'sent')
        .get();

    for (var doc in snapshot.docs) {
      if (doc['senderUid'] != currentUid) {
        await doc.reference.update({'status': 'delivered'});
      }
    }
  }

  Future<void> markAsRead({
    required String chatId,
    required String currentUid,
  }) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    for (var doc in snapshot.docs) {
      if (doc['senderUid'] != currentUid) {
        await doc.reference.update({'status': 'read'});
      }
    }
  }

  Future<int> getUnreadCount({
    required String chatId,
    required String currentUid,
  }) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('status', isEqualTo: 'sent')
        .get();

    return snapshot.docs
        .where((doc) => doc['senderUid'] != currentUid)
        .length;
  }
}