import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FactsPage extends StatefulWidget {
  final bool isLoggedIn;
  const FactsPage({super.key, required this.isLoggedIn});

  @override
  State<FactsPage> createState() => _FactsPageState();
}

class _FactsPageState extends State<FactsPage> {
  // Tracks the expanded/collapsed state of each fact
  final Map<String, bool> _expandedMap = {};

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar
      appBar: AppBar(
        title: const Text("Health Facts"),
        centerTitle: true,
      ),

      // Body
      body: widget.isLoggedIn
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List of facts
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('health_facts')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No facts added yet."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final fact = docs[index];
                      final title = fact['title'] ?? '';
                      final bullets = List<String>.from(fact['bullets'] ?? []);
                      final isExpanded = _expandedMap[fact.id] ?? false;

                      return Card(
                        child: ExpansionTile(
                          key: Key(fact.id),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expandedMap[fact.id] = expanded;
                            });
                          },
                          children: bullets
                              .map((bullet) => ListTile(
                            leading: const Icon(Icons.circle, size: 8),
                            title: Text(bullet),
                          ))
                              .toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )
          : Center(
        // Show login prompt if user is not logged in
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Please log in to view health facts."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
