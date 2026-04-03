import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model (scalable + group ready)
class MessageModel {
  final String id;
  final String senderUid;
  final String chatId;
  final String text;
  final String? mediaUrl;
  final String type; // text, image, video
  final List<String> readBy;
  final Timestamp createdAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.chatId,
    required this.text,
    this.mediaUrl,
    this.type = 'text',
    this.readBy = const [],
    required this.createdAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'chatId': chatId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'readBy': readBy,
      'createdAt': FieldValue.serverTimestamp(), // ✅ server time
    };
  }

  /// Convert Firestore → Model
  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderUid: map['senderUid'] ?? '',
      chatId: map['chatId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'],
      type: map['type'] ?? 'text',
      readBy: List<String>.from(map['readBy'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}

/// Message service (NO duplication, scalable)
class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
    String? mediaUrl,
    String type = 'text',
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final messageData = {
      'senderUid': senderUid,
      'chatId': chatId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type,
      'readBy': [senderUid],
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.runTransaction((txn) async {
      txn.set(msgRef, messageData);

      txn.set(chatRef, {
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Stream messages (real-time)
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Mark message as read (group supported)
  Future<void> markAsRead({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    final ref = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await ref.update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }
}