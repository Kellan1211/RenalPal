import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  final bool isLoggedIn;
  const SettingsPage({super.key, required this.isLoggedIn});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User information fields
  String? firstName;
  String? lastName;
  String? email;
  String? role;

  // App version
  String appVersion = "Loading...";

  // Init state: load user info & app version
  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadUserInfo();
    }
    _loadAppVersion();
  }

  // Load app version dynamically from pubspec.yaml
  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version}+${info.buildNumber}";
    });
  }

  // Load user information from Firestore
  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          firstName = data['firstName'] ?? 'User';
          lastName = data['lastName'] ?? 'User';
          email = data['email'] ?? user.email;
          role = data['role'] ?? 'User';
        });
      } else {
        setState(() {
          firstName = "User";
          lastName = "";
          email = user.email;
          role = "User";
        });
      }
    }
  }

  // Sign out user and navigate to login
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar
      appBar: AppBar(title: const Text('Settings')),

      // Main content
      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          // Intro text
          Text(
            widget.isLoggedIn
                ? 'Manage your account.'
                : 'Settings available without login.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          if (widget.isLoggedIn) ...[
            // Personal Information section
            ExpansionTile(
              title: const Text("Personal Information"),
              children: [
                // Full name
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    (firstName == null && lastName == null)
                        ? "Loading..."
                        : "${firstName ?? ""} ${lastName ?? ""}".trim(),
                  ),
                ),
                // Email
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(email ?? "Loading..."),
                ),
                // Role
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(role ?? "User"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // About section
            ExpansionTile(
              title: const Text("About"),
              children: [
                ListTile(
                  title: Text("RenalPal v$appVersion"),
                  subtitle: const Text("Your trusted kidney health companion."),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Sign out button
            ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
