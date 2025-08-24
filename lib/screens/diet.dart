import 'package:flutter/material.dart';

class DietPage extends StatelessWidget {
  final bool isLoggedIn;
  const DietPage({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet')),
      body: const Center(
        child: Text(
          'Explore renal-friendly diets and meal plans.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
