import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class FluidIntakePage extends StatefulWidget {
  const FluidIntakePage({super.key});

  @override
  State<FluidIntakePage> createState() => _FluidIntakePageState();
}

class _FluidIntakePageState extends State<FluidIntakePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _amountController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Fluid Tracker',
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
                  "Today's Intake",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddIntakePopup(user.uid),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

            // List of fluid intake entries
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('fluid_intake')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No intake recorded yet."));
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = data['amount'] ?? '';
                      final time = data['time'] ?? '';

                      return _buildIntakeCard(doc.id, amount, time, Colors.blue);
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

  Widget _buildIntakeCard(String docId, String amount, String time, Color color) {
    final user = _auth.currentUser!;
    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Entry"),
            content: const Text("Are you sure you want to delete this intake?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                const Text("Delete", style: TextStyle(color: Colors.red)),
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
            .collection('fluid_intake')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry deleted")),
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
            Icon(Icons.local_drink, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$amount ml', // always show ml
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recorded at $time',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddIntakePopup(String userId) async {
    _amountController.clear();
    _selectedTime = null;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Fluid Intake"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount input
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Quantity Consumed",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Only allow digits
                ],
              ),

              const SizedBox(height: 12),
              // Time picker
              InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? 'Time: ${_selectedTime!.format(context)}'
                        : 'Pick Time (optional)',
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
                final amountText = _amountController.text.trim();
                if (amountText.isEmpty) return;

                final pickedTime = _selectedTime ?? TimeOfDay.now();

                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('fluid_intake')
                    .add({
                  'amount': amountText, // store number only
                  'time':
                  '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}',
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
