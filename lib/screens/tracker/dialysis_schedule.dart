import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DialysisSchedulePage extends StatefulWidget {
  const DialysisSchedulePage({super.key});

  @override
  State<DialysisSchedulePage> createState() => _DialysisSchedulePageState();
}

class _DialysisSchedulePageState extends State<DialysisSchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dialysis Schedule',
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
                  'Sessions',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddSessionPopup(user.uid),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

            // List of sessions
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('dialysis_schedule')
                    .orderBy('day') // optional sorting
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No sessions yet."));
                  }

                  return ListView(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final day = data['day'] ?? '';
                      final start = data['startTime'] ?? '';
                      final end = data['endTime'] ?? '';

                      return _buildSessionCard(doc.id, day, start, end, Colors.teal);
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

  Widget _buildSessionCard(
      String docId, String day, String start, String end, Color color) {
    final user = _auth.currentUser!;
    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Session"),
            content: const Text("Are you sure you want to delete this session?"),
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
            .collection('dialysis_schedule')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session deleted")),
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
          color: color.withAlpha(50), // subtle teal highlight
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day of the week
                  Text(
                    day,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  // Start and End times with labels
                  Row(
                    children: [
                      Text(
                        'Start: ',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                      Text(
                        start,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'End: ',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                      Text(
                        end,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSessionPopup(String userId) async {
    String? selectedDay;
    TimeOfDay? _startTime;
    TimeOfDay? _endTime;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Dialysis Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day of the week dropdown
              DropdownButtonFormField<String>(
                value: selectedDay,
                hint: const Text("Select Day"),
                items: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ].map((day) => DropdownMenuItem(
                  value: day,
                  child: Text(day),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDay = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Start time picker
              InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _startTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _startTime != null
                        ? 'Start: ${_startTime!.format(context)}'
                        : 'Pick Start Time',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // End time picker
              InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _endTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _endTime != null
                        ? 'End: ${_endTime!.format(context)}'
                        : 'Pick End Time',
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
                if (selectedDay == null ||
                    _startTime == null ||
                    _endTime == null) return;

                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('dialysis_schedule')
                    .add({
                  'day': selectedDay,
                  'startTime':
                  '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                  'endTime':
                  '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
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
