import 'package:flutter/material.dart';

class SymptomDetailScreen extends StatelessWidget {
  const SymptomDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('증상 상세: $slug')));
  }
}
