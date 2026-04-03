import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverUid;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.receiverUid,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final MessageService _messageService = MessageService();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ Send message (new system)
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _messageService.sendMessage(
      chatId: widget.chatId,
      senderUid: currentUid,
      text: text,
    );

    _messageController.clear();

    /// scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// ✅ Mark messages as read
  void markMessagesAsRead(List<MessageModel> messages) {
    for (var msg in messages) {
      if (!msg.readBy.contains(currentUid)) {
        _messageService.markAsRead(
          chatId: widget.chatId,
          messageId: msg.id,
          uid: currentUid,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: TextStyle(fontSize: 18 * textScale),
        ),
      ),

      body: Column(
        children: [
          /// ✅ Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                /// mark as read
                markMessagesAsRead(messages);

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == currentUid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                          isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            /// message text
                            Text(
                              msg.text,
                              style: TextStyle(fontSize: 15),
                            ),

                            SizedBox(height: 4),

                            /// time + read status
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.createdAt
                                      .toDate()
                                      .toLocal()
                                      .toString()
                                      .substring(11, 16), // HH:mm
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                                SizedBox(width: 5),

                                if (isMe)
                                  Icon(
                                    msg.readBy.length > 1
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 16,
                                    color: msg.readBy.length > 1
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✅ Input box
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}