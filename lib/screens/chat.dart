import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Main chat page widget
class ChatPage extends StatefulWidget {
  final bool isLoggedIn; // Check if user is logged in
  const ChatPage({super.key, required this.isLoggedIn});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controls the three tabs
  final _communityController = TextEditingController(); // Input for community chat
  final _directController = TextEditingController(); // Input for direct chat
  final _doctorController = TextEditingController(); // Input for doctor chat
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase auth instance

  // Direct chat state
  String _selectedDirectUserId = '';
  String _selectedDirectUserName = '';
  bool _inDirectChat = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Initialize TabController for community, direct, doctor tabs
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _tabController.dispose();
    _communityController.dispose();
    _directController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  // Generate unique ID for direct chat between two users
  String _getDirectChatId(String otherUserId) {
    List<String> ids = [_auth.currentUser!.uid, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  // Fetch user name from Firestore
  Future<String> _getUserName(String uid) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return '${data['firstName']} ${data['lastName']}';
      }
    } catch (_) {}
    return 'Unknown';
  }

  // Send message to community chat
  Future<void> _sendCommunityMessage() async {
    if (_communityController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('community_messages').add({
      'senderId': _auth.currentUser!.uid,
      'message': _communityController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _communityController.clear();
  }

  // Send direct message to a selected user
  Future<void> _sendDirectMessage() async {
    if (_directController.text.trim().isEmpty) return;
    if (_selectedDirectUserId == _auth.currentUser!.uid) return;
    final chatId = _getDirectChatId(_selectedDirectUserId);

    await FirebaseFirestore.instance
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': _auth.currentUser!.uid,
      'message': _directController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Save chat participants
    await FirebaseFirestore.instance.collection('direct_chats').doc(chatId).set({
      'participants': [_auth.currentUser!.uid, _selectedDirectUserId]
    }, SetOptions(merge: true));

    _directController.clear();
  }

  // Send message to doctor
  Future<void> _sendDoctorMessage() async {
    if (_doctorController.text.trim().isEmpty) return;
    final doctorId = 'doctor1';
    await FirebaseFirestore.instance
        .collection('doctor_chats')
        .doc(doctorId)
        .collection('messages')
        .add({
      'senderId': _auth.currentUser!.uid,
      'message': _doctorController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _doctorController.clear();
  }

  // Show dialog to add direct chat user by email
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

              final users = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .get();

              if (users.docs.isEmpty) {
                setState(() => _error = 'User not found');
              } else {
                final user = users.docs.first;
                setState(() {
                  _selectedDirectUserId = user.id;
                  _selectedDirectUserName =
                  '${user['firstName']} ${user['lastName']}';
                  _inDirectChat = true;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'))
        ],
      ),
    );
  }

  // Build individual chat message card
  Widget _buildMessageCard(
      String sender, String message, bool isMe, DocumentReference ref) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Allow deleting own messages
        onLongPress: isMe
            ? () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete message?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete')),
              ],
            ),
          );
          if (confirm == true) {
            await ref.delete();
          }
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
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(sender,
                  style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 4),
              Text(message,
                  style: TextStyle(
                      fontSize: 16, color: isMe ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  // Community chat tab
  Widget _communityTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_messages')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return FutureBuilder<String>(
                    future: _getUserName(data['senderId'] ?? ''),
                    builder: (_, nameSnapshot) {
                      final senderName = nameSnapshot.data ?? 'Unknown';
                      return _buildMessageCard(senderName, data['message'] ?? '',
                          data['senderId'] == _auth.currentUser!.uid, docs[i].reference);
                    },
                  );
                },
              );
            },
          ),
        ),
        // Input field and send button
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _communityController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                  onPressed: _sendCommunityMessage, icon: const Icon(Icons.send))
            ],
          ),
        ),
      ],
    );
  }

  // Build individual direct chat tile
  Widget _buildDirectChatTile(String otherUserId, String name, DocumentSnapshot chatDoc) {
    return GestureDetector(
      // Allow deleting entire chat
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete entire chat?'),
            content: const Text('This will delete all messages in this chat.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          final messages = await chatDoc.reference.collection('messages').get();
          for (var msg in messages.docs) {
            await msg.reference.delete();
          }
          await chatDoc.reference.delete();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: StreamBuilder<QuerySnapshot>(
          stream: chatDoc.reference.collection('messages')
              .orderBy('createdAt', descending: true).limit(1).snapshots(),
          builder: (_, msgSnap) {
            String lastMsg = '';
            String time = '';
            if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
              final data = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
              lastMsg = data['message'] ?? '';
              final ts = data['createdAt'] as Timestamp?;
              if (ts != null) {
                time = DateFormat('HH:mm').format(ts.toDate());
              }
            }
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () => setState(() {
                _selectedDirectUserId = otherUserId;
                _selectedDirectUserName = name;
                _inDirectChat = true;
              }),
            );
          },
        ),
      ),
    );
  }

  // Direct chat tab
  Widget _directTab() {
    if (_inDirectChat) {
      // Show individual direct chat messages
      final chatId = _getDirectChatId(_selectedDirectUserId);
      return Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _inDirectChat = false),
            ),
            title: Text(_selectedDirectUserName),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getUserName(data['senderId'] ?? ''),
                      builder: (_, nameSnapshot) {
                        final senderName = nameSnapshot.data ?? 'Unknown';
                        return _buildMessageCard(
                            senderName,
                            data['message'] ?? '',
                            data['senderId'] == _auth.currentUser!.uid,
                            docs[i].reference);
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
                    controller: _directController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: _sendDirectMessage, icon: const Icon(Icons.send))
              ],
            ),
          ),
        ],
      );
    } else {
      // Show list of all direct chats
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _addDirectUserDialog,
            icon: const Icon(Icons.add),
            label: const Text('Start Direct Chat'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .where('participants', arrayContains: _auth.currentUser!.uid)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final otherUserId = (data['participants'] as List)
                        .firstWhere((id) => id != _auth.currentUser!.uid);
                    return FutureBuilder<String>(
                        future: _getUserName(otherUserId),
                        builder: (_, userSnapshot) {
                          if (!userSnapshot.hasData) return const SizedBox();
                          final name = userSnapshot.data!;
                          return _buildDirectChatTile(otherUserId, name, docs[i]);
                        });
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

  // Doctor chat tab
  Widget _doctorTab() {
    final doctorId = 'doctor1';
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctor_chats')
                .doc(doctorId)
                .collection('messages')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return FutureBuilder<String>(
                    future: _getUserName(data['senderId'] ?? ''),
                    builder: (_, nameSnapshot) {
                      final senderName = nameSnapshot.data ?? 'Unknown';
                      return _buildMessageCard(
                          senderName,
                          data['message'] ?? '',
                          data['senderId'] == _auth.currentUser!.uid,
                          docs[i].reference);
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
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                  onPressed: _sendDoctorMessage, icon: const Icon(Icons.send))
            ],
          ),
        ),
      ],
    );
  }

  // Main widget build
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return const Center(child: Text('Log in to access chat.'));
    }
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
        children: [
          _communityTab(),
          _directTab(),
          _doctorTab(),
        ],
      ),
    );
  }
}
