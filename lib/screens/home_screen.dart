import 'package:flutter/material.dart';
import '../widgets/title_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starter Template Home'),
        centerTitle: true,
      ),
      // SafeArea schützt vor Notch und Home-Indicator
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Richtet die Elemente horizontal in der Mitte aus
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // unser Widget TitleText verwenden
              const TitelText(
                'Flutter Starter Template',
              ),
              const SizedBox(height: 20), // Abstandshalter
              const Text(
                'Dieses Template dient als Basis für unsere App!',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 18,),
              ),
              const Spacer(), // Schiebt die Buttons nach ganz unten
              // Zeige beide Button-Typen nebeneinander zum Vergleich
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('TextButton'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('ElevatedButton'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}