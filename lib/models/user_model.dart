import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for ChatPal (scalable + future-ready)
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String bio;
  final String profilePicture;

  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final String? username;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.bio,
    required this.profilePicture,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.username,
  });

  /// Convert UserModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(), // auto updated
      'fcmToken': fcmToken,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert Firestore → UserModel
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'],
      username: map['username'],
    );
  }
}

/// Firestore Service (User + Chat management)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Update online status
  Future<void> updateOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Update FCM token
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  /// Get all users (for new chat screen)
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get single user
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  /// Stream single user (real-time updates)
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Create chat (1-to-1 or group)
  Future<String> createChat({
    required List<String> participants,
    String? groupName,
  }) async {
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

  /// Get chats for current user (Home screen)
  Stream<QuerySnapshot> getUserChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }
}