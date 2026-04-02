import 'package:flutter/material.dart';
import 'package:nextalk/screens/chat_screen.dart';
import 'package:nextalk/screens/profile_module.dart';
import 'package:nextalk/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  String searchQuery = '';
  bool showSearch = false; // Controls visibility of search bar

  Map<String, int> unreadCounts = {}; // unread messages per user
  Map<String, Stream<int>> unreadStreams = {}; // store streams
  UserModel? currentUserModel; // stores logged-in user info

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void _toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      if (!showSearch) {
        searchQuery = '';
        filteredUsers = users;
      }
    });
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredUsers = users
          .where((user) => user.name.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  void fetchUsers() async {
    // 1. Fetch all users
    List<UserModel> fetchedUsers = await _firestoreService.getAllUsers();

    // 2. Set current user model
    UserModel loggedInUser = fetchedUsers.firstWhere(
          (user) => user.uid == _auth.currentUser!.uid,
      orElse: () => UserModel(
        uid: _auth.currentUser!.uid,
        name: _auth.currentUser!.displayName ?? '',
        email: _auth.currentUser!.email ?? '',
        profilePicture: '',
        bio: '',
      ),
    );

    setState(() {
      users = fetchedUsers;
      filteredUsers = fetchedUsers;
      currentUserModel = loggedInUser;
    });

    // 3. Fetch unread message counts
    Map<String, int> batchCounts = {};
    await Future.wait(users.map((user) async {
      if (user.uid == _auth.currentUser!.uid) return;
      int count = await _firestoreService.getUnreadMessageCount(
        senderUid: user.uid,
        receiverUid: _auth.currentUser!.uid,
      );
      batchCounts[user.uid] = count;
    }));

    setState(() {
      unreadCounts = batchCounts;
    });

    // 4. Setup live streams for unread messages
    for (var user in users) {
      if (user.uid == _auth.currentUser!.uid) continue;
      if (unreadStreams[user.uid] != null) continue;

      Stream<int> stream = _firestoreService.unreadMessageCountStream(
        senderUid: user.uid,
        receiverUid: _auth.currentUser!.uid,
      );

      stream.listen((count) {
        setState(() {
          unreadCounts[user.uid] = count;
        });
      });

      unreadStreams[user.uid] = stream;
    }
  }

  void logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      appBar: AppBar(
        title: showSearch
            ? TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
          ),
          onChanged: _filterUsers,
        )
            : Text(
          'ChatPal',
          style: TextStyle(fontSize: 20 * textScale),
        ),
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: currentUserModel?.profilePicture.isNotEmpty == true
                        ? NetworkImage(currentUserModel!.profilePicture)
                        : null,
                    child: currentUserModel?.profilePicture.isEmpty == true
                        ? Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentUserModel?.email ?? 'No Email',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
                      email: currentUserModel?.email ?? '',
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
        ),
      ),
      body: Column(
        children: [
          // Optional: Show search results count
          if (showSearch && searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing ${filteredUsers.length} results',
                style: TextStyle(fontSize: 14 * textScale),
              ),
            ),
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                if (user.uid == _auth.currentUser!.uid) return SizedBox.shrink();

                int unreadCount = unreadCounts[user.uid] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePicture.isNotEmpty
                        ? NetworkImage(user.profilePicture)
                        : null,
                    child: user.profilePicture.isEmpty ? Icon(Icons.person) : null,
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(fontSize: 16 * textScale),
                  ),
                  subtitle: Text(
                    user.bio,
                    style: TextStyle(fontSize: 14 * textScale),
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverUid: user.uid,
                          receiverName: user.name,
                        ),
                      ),
                    ).then((_) => fetchUsers());
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.chat),
      ),
    );
  }
}
