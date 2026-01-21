import "package:flutter/material.dart";

class TitelText extends StatelessWidget {
  final String inhalt;

  // Ein einfacher Konstruktor
  const TitelText(this.inhalt, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      inhalt,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}