import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import 'chat_screen.dart';
import 'profile_module.dart';
import 'login_screen.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool showSearch = false;
  String searchQuery = '';

  void logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;
    double textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      appBar: AppBar(
        title: showSearch
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search chats...',
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => searchQuery = val),
        )
            : Text('ChatPal', style: TextStyle(fontSize: 20 * textScale)),
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),

      // ✅ Drawer (same as before)
      drawer: Drawer(
        child: FutureBuilder<UserModel?>(
          future: _firestoreService.getUser(currentUid),
          builder: (context, snapshot) {
            final user = snapshot.data;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration:
                  BoxDecoration(color: Theme.of(context).primaryColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.profilePicture.isNotEmpty == true
                            ? NetworkImage(user!.profilePicture)
                            : null,
                        child: user?.profilePicture.isEmpty == true
                            ? Icon(Icons.person)
                            : null,
                      ),
                      SizedBox(height: 10),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSetupScreen(
                          email: user?.email ?? '',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: logout,
                ),
              ],
            );
          },
        ),
      ),

      // ✅ MAIN CHAT LIST
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserChats(currentUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;

          // 🔥 remove empty chats
          chats = chats
              .where((chat) =>
          (chat['lastMessage'] ?? '').toString().isNotEmpty)
              .toList();

          // 🔍 search filter
          if (searchQuery.isNotEmpty) {
            chats = chats.where((chat) {
              final name = (chat['groupName'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();
          }

          if (chats.isEmpty) {
            return Center(child: Text("No chats yet"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);

              final otherUid =
              participants.firstWhere((id) => id != currentUid);

              return FutureBuilder<UserModel?>(
                future: _firestoreService.getUser(otherUid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return SizedBox();

                  final user = userSnap.data!;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profilePicture.isNotEmpty
                          ? NetworkImage(user.profilePicture)
                          : null,
                      child: user.profilePicture.isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),

                    title: Text(user.name),

                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: chat['lastTimestamp'] != null
                        ? Text(
                      (chat['lastTimestamp'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString()
                          .substring(11, 16), // HH:mm
                      style: TextStyle(fontSize: 12),
                    )
                        : null,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            receiverUid: user.uid,
                            receiverName: user.name,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      // ✅ FAB → New Chat Screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 👉 open all users screen (create new chat)
        },
        child: Icon(Icons.chat),
      ),
    );
  }
}