import 'package:flutter/material.dart';

class InfoPageScaffold extends StatelessWidget {
  const InfoPageScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: body),
      ),
    );
  }
}
