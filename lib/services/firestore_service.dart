import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// -------------------------------
  /// USER OPERATIONS
  /// -------------------------------
  Future<void> createOrUpdateUser(UserModel user) async {
    await _db.collection('db_user').doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('db_user').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('db_user').get();
    return snapshot.docs.map((doc) {
      return UserModel.fromMap(doc.id, doc.data());
    }).toList();
  }

  /// -------------------------------
  /// CHAT CORE
  /// -------------------------------
  final String chatsCollection = 'chats';

  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  /// -------------------------------
  /// SEND MESSAGE
  /// -------------------------------
  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String message,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);

    final msgRef = _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc();

    final timestamp = FieldValue.serverTimestamp();

    final msgData = {
      'id': msgRef.id,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'message': message,
      'timestamp': timestamp,
      'status': 'sent',
    };

    /// 1️⃣ store message
    await msgRef.set(msgData);

    /// 2️⃣ update chat metadata (IMPORTANT)
    await _db.collection(chatsCollection).doc(chatId).set({
      'participants': [senderUid, receiverUid],
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastSenderUid': senderUid,
    }, SetOptions(merge: true));
  }

  /// -------------------------------
  /// STREAM MESSAGES
  /// -------------------------------
  Stream<List<Map<String, dynamic>>> getMessages({
    required String userUid,
    required String chatPartnerUid,
  }) {
    final chatId = getChatId(userUid, chatPartnerUid);

    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// -------------------------------
  /// STREAM USER CHATS (🔥 IMPORTANT)
  /// -------------------------------
  Stream<List<Map<String, dynamic>>> getUserChats(String uid) {
    return _db
        .collection(chatsCollection)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// -------------------------------
  /// MARK AS DELIVERED
  /// -------------------------------
  Future<void> markAsDelivered({
    required String senderUid,
    required String receiverUid,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);

    final snapshot = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'sent')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'status': 'delivered'});
    }
  }

  /// -------------------------------
  /// MARK AS READ
  /// -------------------------------
  Future<void> markAsRead({
    required String chatId,
    required String currentUserUid,
  }) async {
    final snapshot = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: currentUserUid)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'status': 'read'});
    }
  }

  /// -------------------------------
  /// UNREAD COUNT (REALTIME)
  /// -------------------------------
  Stream<int> unreadCountStream({
    required String chatId,
    required String currentUserUid,
  }) {
    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: currentUserUid)
        .where('status', whereIn: ['sent', 'delivered'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// -------------------------------
  /// ONLINE STATUS
  /// -------------------------------
  Future<void> updateOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _db.collection('db_user').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}