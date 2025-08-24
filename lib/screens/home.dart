import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tracker/dialysis_schedule.dart';
import 'tracker/blood_pressure.dart';
import 'tracker/fluid_intake.dart';
import 'tracker/medications.dart';

// Main homepage widget
class HomePage extends StatefulWidget {
  final bool isLoggedIn; // Flag to check if user is logged in
  const HomePage({super.key, required this.isLoggedIn});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName; // Stores user's first name

  @override
  void initState() {
    super.initState();
    // Load user first name if logged in
    if (widget.isLoggedIn) {
      _loadUserName();
    }
  }

  // Fetch user first name from Firestore
  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          firstName = doc.data()?['firstName'] ?? 'User';
        });
      }
    }
  }

  // Return greeting based on current hour
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // Simple top bar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section
            Text(
              widget.isLoggedIn
                  ? '${_greeting()}, ${firstName ?? ''}!'
                  : 'Welcome to RenalPal!',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLoggedIn
                  ? 'Here’s your update for today.'
                  : 'Browse facts and diets freely.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Dashboard 2x2 grid for quick navigation
            GridView(
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling inside grid
              shrinkWrap: true, // Wrap height to content
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two cards per row
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2),
              children: [
                // Next dialysis card
                _buildStatCard(
                  context,
                  'Next Dialysis',
                  'Tomorrow 09:00',
                  Colors.teal,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DialysisSchedulePage()),
                  ),
                ),
                // Last blood pressure card
                _buildStatCard(
                  context,
                  'Last BP',
                  '120/80',
                  Colors.orange,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BloodPressurePage()),
                  ),
                ),
                // Fluid intake card
                _buildStatCard(
                  context,
                  'Fluid Intake',
                  '1.2 L',
                  Colors.blue,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FluidIntakePage()),
                  ),
                ),
                // Medications card
                _buildStatCard(
                  context,
                  'Medications',
                  '2 Today',
                  Colors.purple,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MedicationsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daily health tip section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.health_and_safety, color: Colors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip of the Day: Stay hydrated but monitor your fluid intake according to your plan.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Motivational quote
            Center(
              child: Text(
                '"Healthy kidneys, Healthy life."',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build dashboard cards
  Widget _buildStatCard(BuildContext context, String title, String value,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Navigate to relevant tracker page
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
