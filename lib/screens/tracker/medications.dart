import 'package:flutter/material.dart';

// Medications tracking page
class MedicationsPage extends StatelessWidget {
  const MedicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Page background

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
            // Title for today's medications
            const Text(
              'Medications Today',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // List of medication entries
            Expanded(
              child: ListView(
                children: [
                  _buildMedicationCard('Pill A', '08:00', Colors.purple),
                  _buildMedicationCard('Pill B', '20:00', Colors.purple),
                  // Additional medications can be added here
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Button to add new medication entry
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to add medication page/dialog
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Medication',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[300],
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

  // Helper method to build each medication card
  Widget _buildMedicationCard(String name, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: color, size: 36),
          const SizedBox(width: 16),

          // Medication info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Take at $time',
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),

          // Check button to mark as taken
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
            onPressed: () {
              // TODO: Mark medication as taken
            },
          ),
        ],
      ),
    );
  }
}
