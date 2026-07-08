import 'package:flutter/material.dart';

class TermsViewerScreen extends StatelessWidget {
  const TermsViewerScreen({required this.doc, super.key});

  final String doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('약관: $doc')));
  }
}
