import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final bool isLoggedIn;
  const ChatPage({super.key, required this.isLoggedIn});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _communityController = TextEditingController();
  final _directController = TextEditingController();
  final _doctorController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedDirectUserId = '';
  String _selectedDirectUserName = '';
  bool _inDirectChat = false;
  String _error = '';
  String _userRole = 'user';

  // For doctor viewing user chats
  String _selectedDoctorUserId = '';
  String _selectedDoctorUserName = '';
  bool _inDoctorChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = snap.data()?['role'] ?? 'user';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _communityController.dispose();
    _directController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  String _getDirectChatId(String otherUserId) {
    List<String> ids = [_auth.currentUser!.uid, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  Future<String> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (_) {}
    return 'Unknown';
  }

  Future<void> _sendCommunityMessage() async {
    if (_communityController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('community_messages').add({
      'senderId': _auth.currentUser!.uid,
      'message': _communityController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _communityController.clear();
  }

  Future<void> _sendDirectMessage() async {
    if (_directController.text.trim().isEmpty) return;
    if (_selectedDirectUserId == _auth.currentUser!.uid) return;
    final chatId = _getDirectChatId(_selectedDirectUserId);

    await FirebaseFirestore.instance.collection('direct_chats').doc(chatId)
        .collection('messages')
        .add({
      'senderId': _auth.currentUser!.uid,
      'message': _directController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('direct_chats').doc(chatId).set({
      'participants': [_auth.currentUser!.uid, _selectedDirectUserId]
    }, SetOptions(merge: true));

    _directController.clear();
  }

  //USERS & DOCTOR MESSAGE
  Future<void> _sendDoctorMessage() async {
    if (_doctorController.text.trim().isEmpty) return;
    final currentUserId = _auth.currentUser!.uid;

    String chatDocId;
    if (_userRole == 'doctor') {
      if (_selectedDoctorUserId.isEmpty) return;
      chatDocId = _selectedDoctorUserId;
    } else {
      chatDocId = currentUserId;
    }

    final chatDocRef = FirebaseFirestore.instance
        .collection('doctor_chats')
        .doc(chatDocId);

    // Ensure the parent document exists
    await chatDocRef.set({
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add the actual message
    await chatDocRef.collection('messages').add({
      'senderId': currentUserId,
      'message': _doctorController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _doctorController.clear();
  }

  //DELETE CHAT FUNCTION
  Future<void> _deleteChat(String collection, String docId) async {
    final chatDocRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    // Delete all messages
    final messages = await chatDocRef.collection('messages').get();
    for (var msg in messages.docs) {
      await msg.reference.delete();
    }

    // Delete parent document
    await chatDocRef.delete();
  }

  Future<void> _addDirectUserDialog() async {
    final _emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add User by Email'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(hintText: 'Enter email'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty) return;

              final users = await FirebaseFirestore.instance.collection('users')
                  .where('email', isEqualTo: email).get();

              if (users.docs.isEmpty) {
                setState(() => _error = 'User not found');
              } else {
                final user = users.docs.first;
                setState(() {
                  _selectedDirectUserId = user.id;
                  _selectedDirectUserName = '${user['firstName']} ${user['lastName']}';
                  _inDirectChat = true;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))
        ],
      ),
    );
  }

  Widget _buildMessageCard(String sender, String message, bool isMe, DocumentReference ref) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe
            ? () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete message?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
              ],
            ),
          );
          if (confirm == true) await ref.delete();
        }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.teal : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(sender, style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 4),
              Text(message, style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _communityTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('community_messages')
                .orderBy('createdAt', descending: false).snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return FutureBuilder<String>(
                    future: _getUserName(data['senderId'] ?? ''),
                    builder: (_, nameSnapshot) {
                      final senderName = nameSnapshot.data ?? 'Unknown';
                      return _buildMessageCard(senderName, data['message'] ?? '', data['senderId'] == _auth.currentUser!.uid, docs[i].reference);
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(controller: _communityController, decoration: const InputDecoration(hintText: 'Type a message...', border: OutlineInputBorder())),
              ),
              IconButton(onPressed: _sendCommunityMessage, icon: const Icon(Icons.send))
            ],
          ),
        ),
      ],
    );
  }

  Widget _directTab() {
    if (_inDirectChat) {
      final chatId = _getDirectChatId(_selectedDirectUserId);
      return Column(
        children: [
          AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _inDirectChat = false)),
            title: Text(_selectedDirectUserName),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete chat?'),
                      content: const Text('This will remove all messages for this chat.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _deleteChat('direct_chats', chatId);
                    setState(() => _inDirectChat = false);
                  }
                },
              )
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('direct_chats').doc(chatId).collection('messages').orderBy('createdAt', descending: false).snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getUserName(data['senderId'] ?? ''),
                      builder: (_, nameSnapshot) {
                        final senderName = nameSnapshot.data ?? 'Unknown';
                        return _buildMessageCard(senderName, data['message'] ?? '', data['senderId'] == _auth.currentUser!.uid, docs[i].reference);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _directController, decoration: const InputDecoration(hintText: 'Type a message...', border: OutlineInputBorder()))),
                IconButton(onPressed: _sendDirectMessage, icon: const Icon(Icons.send))
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(onPressed: _addDirectUserDialog, icon: const Icon(Icons.add), label: const Text('Start Direct Chat')),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('direct_chats').where('participants', arrayContains: _auth.currentUser!.uid).snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final otherUserId = (data['participants'] as List).firstWhere((id) => id != _auth.currentUser!.uid);
                    return FutureBuilder<String>(
                      future: _getUserName(otherUserId),
                      builder: (_, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox();
                        final name = userSnapshot.data!;
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.teal, child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _selectedDirectUserId = otherUserId;
                              _selectedDirectUserName = name;
                              _inDirectChat = true;
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

  //DOCTOR TAB
  Widget _doctorTab() {
    if (_userRole != 'doctor') {
      // regular user view
      return Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctor_chats')
                  .doc(_auth.currentUser!.uid)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getUserName(data['senderId'] ?? ''),
                      builder: (_, nameSnapshot) {
                        final senderName = nameSnapshot.data ?? 'Unknown';
                        return _buildMessageCard(senderName, data['message'] ?? '', data['senderId'] == _auth.currentUser!.uid, docs[i].reference);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doctorController,
                    decoration: const InputDecoration(
                        hintText: 'Send message to doctor...',
                        border: OutlineInputBorder()),
                  ),
                ),
                IconButton(onPressed: _sendDoctorMessage, icon: const Icon(Icons.send))
              ],
            ),
          ),
        ],
      );
    } else {
      // doctor view
      if (_inDoctorChat) {
        return Column(
          children: [
            AppBar(
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _inDoctorChat = false)),
              title: Text(_selectedDoctorUserName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete chat?'),
                        content: const Text('This will remove all messages for this user.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteChat('doctor_chats', _selectedDoctorUserId);
                      setState(() => _inDoctorChat = false);
                    }
                  },
                )
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor_chats')
                    .doc(_selectedDoctorUserId)
                    .collection('messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return FutureBuilder<String>(
                        future: _getUserName(data['senderId'] ?? ''),
                        builder: (_, nameSnapshot) {
                          final senderName = nameSnapshot.data ?? 'Unknown';
                          return _buildMessageCard(senderName, data['message'] ?? '', data['senderId'] == _auth.currentUser!.uid, docs[i].reference);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _doctorController,
                      decoration: const InputDecoration(
                        hintText: 'Reply to user...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(onPressed: _sendDoctorMessage, icon: const Icon(Icons.send))
                ],
              ),
            ),
          ],
        );
      } else {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('doctor_chats').snapshots(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final userId = docs[i].id;
                return FutureBuilder<String>(
                  future: _getUserName(userId),
                  builder: (_, nameSnap) {
                    final userName = nameSnap.data ?? userId;
                    final lastMsg = docs[i].reference.collection('messages')
                        .orderBy('createdAt', descending: true).limit(1)
                        .snapshots();
                    return StreamBuilder<QuerySnapshot>(
                      stream: lastMsg,
                      builder: (_, msgSnap) {
                        String lastMessage = '';
                        if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                          lastMessage = msgSnap.data!.docs.first['message'] ?? '';
                        }
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(userName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white))),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => setState(() {
                            _selectedDoctorUserId = userId;
                            _selectedDoctorUserName = userName;
                            _inDoctorChat = true;
                          }),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) return const Center(child: Text('Log in to access chat.'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Community'),
            Tab(text: 'Direct'),
            Tab(text: 'Doctor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_communityTab(), _directTab(), _doctorTab()],
      ),
    );
  }
}
