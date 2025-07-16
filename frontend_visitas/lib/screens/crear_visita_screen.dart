import 'package:flutter/material.dart';

class CrearVisitaScreen extends StatelessWidget {
  const CrearVisitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Visita")),
      body: const Center(child: Text("Formulario para crear una visita")),
    );
  }
}
