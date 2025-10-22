import 'package:flutter/material.dart';

class SosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SosButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        child: Text(label),
      ),
    );
  }
}
