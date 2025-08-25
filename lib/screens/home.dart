import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tracker/dialysis_schedule.dart';
import 'tracker/blood_pressure.dart';
import 'tracker/fluid_intake.dart';
import 'tracker/medications.dart';

class HomePage extends StatefulWidget {
  final bool isLoggedIn;
  const HomePage({super.key, required this.isLoggedIn});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  String lastBP = '--';
  String avgBP = '--';
  String fluidToday = '--';
  String medsToday = '--';
  String nextDialysisStr = '--';
  String tipOfTheDay = 'Loading...';

  // For daily tip
  DateTime? _lastTipDate;
  String? _lastTip;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadUserName();
      _loadDashboardData();
      _loadTipOfTheDay();
    }
  }

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

  Future<void> _loadDashboardData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();

    // --- Blood Pressure ---
    final bpSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blood_pressure')
        .orderBy('timestamp', descending: true)
        .get();

    if (bpSnap.docs.isNotEmpty) {
      final latest = bpSnap.docs.first.data();
      lastBP = '${latest['systolic'] ?? 0}/${latest['diastolic'] ?? 0}';
      int totalSystolic = 0;
      int totalDiastolic = 0;
      for (var doc in bpSnap.docs) {
        final data = doc.data();
        totalSystolic += (data['systolic'] as num?)?.toInt() ?? 0;
        totalDiastolic += (data['diastolic'] as num?)?.toInt() ?? 0;
      }
      avgBP =
      '${(totalSystolic / bpSnap.docs.length).round()}/${(totalDiastolic / bpSnap.docs.length).round()}';
    }

    // --- Fluid Intake Today ---
    final fluidSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fluid_intake')
        .get();

    double totalFluid = 0;
    for (var doc in fluidSnap.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null &&
          timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day) {
        totalFluid += double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
      }
    }
    fluidToday = '${(totalFluid / 1000).toStringAsFixed(1)} L';

    // --- Medications Today ---
    final medsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medications')
        .get();

    int medsCount = 0;
    for (var doc in medsSnap.docs) {
      final data = doc.data();
      final timeStr = data['time'];
      if (timeStr != null) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final medDate = DateTime(now.year, now.month, now.day, hour, minute);
          if (medDate.isAfter(DateTime(now.year, now.month, now.day, 0, 0)) &&
              medDate.isBefore(DateTime(now.year, now.month, now.day, 23, 59))) {
            medsCount++;
          }
        }
      }
    }
    medsToday = '$medsCount Today';

    // --- Next Dialysis ---
    final dialysisSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dialysis_schedule')
        .get();

    if (dialysisSnap.docs.isNotEmpty) {
      DateTime? nextSession;
      int todayWeekday = now.weekday;
      Map<String, int> dayMap = {
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7
      };
      for (var doc in dialysisSnap.docs) {
        final data = doc.data();
        String dayStr = data['day'] ?? '';
        String startTimeStr = data['startTime'] ?? '00:00';
        final dayNum = dayMap[dayStr] ?? 0;
        if (dayNum == 0) continue;
        final parts = startTimeStr.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        int daysAhead = (dayNum - todayWeekday + 7) % 7;
        DateTime sessionDate = DateTime(now.year, now.month, now.day + daysAhead, hour, minute);
        if (daysAhead == 0 && sessionDate.isBefore(now)) {
          sessionDate = sessionDate.add(const Duration(days: 7));
        }
        if (nextSession == null || sessionDate.isBefore(nextSession)) {
          nextSession = sessionDate;
        }
      }
      if (nextSession != null) {
        final weekdayStr = ['','Mon','Tue','Wed','Thu','Fri','Sat','Sun'][nextSession.weekday];
        nextDialysisStr =
        '$weekdayStr ${nextSession.hour.toString().padLeft(2,'0')}:${nextSession.minute.toString().padLeft(2,'0')}';
      }
    }

    setState(() {});
  }

  Future<void> _loadTipOfTheDay() async {
    final now = DateTime.now();
    // If tip already loaded today, reuse it
    if (_lastTipDate != null &&
        _lastTip != null &&
        _lastTipDate!.year == now.year &&
        _lastTipDate!.month == now.month &&
        _lastTipDate!.day == now.day) {
      setState(() {
        tipOfTheDay = _lastTip!;
      });
      return;
    }

    // Fetch all tips
    final snap = await FirebaseFirestore.instance
        .collection('tips_of_the_day')
        .get();

    if (snap.docs.isNotEmpty) {
      final random = Random();
      final doc = snap.docs[random.nextInt(snap.docs.length)];
      final data = doc.data();
      final tip = data['tip'] ?? 'Stay healthy and hydrated!';

      setState(() {
        tipOfTheDay = tip;
        _lastTip = tip;
        _lastTipDate = now;
      });
    } else {
      setState(() {
        tipOfTheDay = 'Stay healthy and hydrated!';
        _lastTip = tipOfTheDay;
        _lastTipDate = now;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isLoggedIn
                  ? '${_greeting()}, ${firstName ?? ''}!'
                  : 'Welcome to RenalPal!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLoggedIn
                  ? 'Here’s your update for today.'
                  : 'Browse facts and diets freely.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            GridView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
              children: [
                _buildStatCard(context, 'Next Dialysis', nextDialysisStr, Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DialysisSchedulePage()),
                    )),
                _buildStatCard(context, 'Last BP', lastBP, Colors.orange, showAvg: avgBP,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BloodPressurePage()),
                    )),
                _buildStatCard(context, 'Fluid Intake', fluidToday, Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FluidIntakePage()),
                    )),
                _buildStatCard(context, 'Medications', medsToday, Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicationsPage()),
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // --- Tip of the Day Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tip of the Day',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    tipOfTheDay,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                '"Healthy kidneys, Healthy life."',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color,
      {String? showAvg, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
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
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (showAvg != null && showAvg != '--') ...[
              const SizedBox(height: 4),
              Text('Avg: $showAvg', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
