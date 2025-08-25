import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DietPage extends StatefulWidget {
  final bool isLoggedIn;
  const DietPage({super.key, required this.isLoggedIn});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  // Current search query
  String searchQuery = "";

  // Controller for the search TextField
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text("Diet Information"),
        ),
      ),

      // Body
      body: widget.isLoggedIn
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for a food (e.g. Orange)",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            // Food List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('foods')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  // Filter foods based on search query
                  final docs = snapshot.data!.docs.where((doc) {
                    final foodName = doc['name'].toString().toLowerCase();
                    return foodName.contains(searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No matching foods found."),
                    );
                  }

                  // Display food list
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final food = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            food['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(food['description']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                food['isFriendly']
                                    ? "Friendly "
                                    : "Not Friendly ",
                                style: TextStyle(
                                  color: food['isFriendly']
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                food['isFriendly']
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: food['isFriendly']
                                    ? Colors.green
                                    : Colors.red,
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
            const Text("Please log in to view diet info."),
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
