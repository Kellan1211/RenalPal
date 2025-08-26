import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Medications Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Add button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Medications Today",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMedicationPopup,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[300],
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // List of medications
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('medications')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No medications recorded yet."));
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      final instructions = data['instructions'] ?? '';
                      final time = data['time'] ?? '';
                      return _buildMedicationCard(doc.id, name, instructions, time, Colors.purple);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(String docId, String name, String instructions, String time, Color color) {
    final user = _auth.currentUser!;
    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Medication"),
            content: const Text("Are you sure you want to delete this medication?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (direction) async {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medication deleted")),
        );
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.medication, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(instructions,
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('Take at $time',
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMedicationPopup() async {
    _nameController.clear();
    _instructionsController.clear();
    _selectedTime = null;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Medication"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Medication name input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Medication Name"),
              ),
              const SizedBox(height: 12),
              // Instructions input
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(labelText: "How to take it"),
              ),
              const SizedBox(height: 12),
              // Time picker (required)
              InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? 'Take at ${_selectedTime!.format(context)}'
                        : 'Pick Time',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final instructions = _instructionsController.text.trim();
                if (name.isEmpty || instructions.isEmpty || _selectedTime == null) return;

                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('medications')
                    .add({
                  'name': name,
                  'instructions': instructions,
                  'time':
                  '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                  'timestamp': DateTime.now(),
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
