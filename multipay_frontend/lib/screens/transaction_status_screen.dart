import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import nécessaire pour la redirection

class TransactionStatusScreen extends StatefulWidget {
  final String operator; // MTN, MOOV, CELTIIS
  final String service;  // Dépôt, Retrait, etc.
  final bool isSuccess;

  const TransactionStatusScreen({
    super.key,
    required this.operator,
    required this.service,
    required this.isSuccess,
  });

  @override
  State<TransactionStatusScreen> createState() => _TransactionStatusScreenState();
}

class _TransactionStatusScreenState extends State<TransactionStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Redirection automatique vers le Dashboard après 3 secondes
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        // --- CORRECTION ICI ---
        // On remplace le retour à la racine par une redirection propre vers le Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false, // On vide toute la pile pour éviter les retours en arrière
        );
      }
    });
  }

  // Couleurs de fond clarifiées (Pastels) pour le confort visuel
  Color _getSoftBgColor() {
    if (widget.operator == 'MTN') return const Color(0xFFFFF9C4); // Jaune très clair
    if (widget.operator == 'MOOV') return const Color(0xFFE8F5E9); // Vert très clair
    if (widget.operator == 'CELTIIS') return const Color(0xFFE3F2FD); // Bleu très clair
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getSoftBgColor(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de l'icône
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    widget.isSuccess ? Icons.check_circle : Icons.error,
                    color: widget.isSuccess ? Colors.green : Colors.red,
                    size: 100,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              widget.isSuccess ? "OPÉRATION RÉUSSIE" : "ÉCHEC DE L'OPÉRATION",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              "${widget.service} ${widget.operator}",
              style: TextStyle(
                  fontSize: 16, color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black26),
            ),
            const SizedBox(height: 20),
            const Text("Retour au dashboard...",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}