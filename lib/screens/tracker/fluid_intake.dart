import 'package:flutter/material.dart';

// Fluid Intake tracking page
class FluidIntakePage extends StatelessWidget {
  const FluidIntakePage({super.key});

  @override
  Widget build(BuildContext context) {
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
            // Title for today's intake section
            const Text(
              'Today\'s Intake',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // List of fluid intake entries
            Expanded(
              child: ListView(
                children: [
                  _buildIntakeCard('200 ml', '08:00', Colors.blue),
                  _buildIntakeCard('500 ml', '12:00', Colors.blue),
                  // Additional entries can be added here
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Button to add new fluid intake entry
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add intake functionality
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Intake',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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

  // Helper method to build a card for each fluid intake entry
  Widget _buildIntakeCard(String amount, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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
                Text(amount,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Recorded at $time',
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}