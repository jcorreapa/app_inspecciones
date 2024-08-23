import 'package:flutter/material.dart';

class PreguntaCard extends StatelessWidget {
  final Widget child;
  final String titulo;

  const PreguntaCard({
    super.key,
    required this.child,
    required this.titulo,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
