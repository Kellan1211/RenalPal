import 'package:flutter/material.dart';

// Dialysis Schedule page
class DialysisSchedulePage extends StatelessWidget {
  const DialysisSchedulePage({super.key});

  // Example recurring dialysis sessions
  final List<Map<String, String>> recurringSessions = const [
    {'day': 'Tuesday', 'time': '09:00', 'clinic': 'Renal Clinic A'},
    {'day': 'Thursday', 'time': '09:00', 'clinic': 'Renal Clinic A'},
    {'day': 'Sunday', 'time': '09:00', 'clinic': 'Renal Clinic A'},
  ];

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Sessions',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // List of scheduled sessions
            Expanded(
              child: ListView(
                children: recurringSessions
                    .map((session) => _buildSessionCard(
                  session['day']!,
                  session['time']!,
                  session['clinic']!,
                  Colors.teal,
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Button to add a new dialysis session
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add session functionality
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Session',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a card for each dialysis session
  Widget _buildSessionCard(
      String day, String time, String clinic, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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
                Text('$day - $time',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(clinic,
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}