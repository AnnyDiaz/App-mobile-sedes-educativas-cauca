import 'package:flutter/material.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Supervisor")),
      body: const Center(child: Text("Pantalla de dashboard para supervisor")),
    );
  }
}
