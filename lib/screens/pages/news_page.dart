import 'package:flutter/material.dart';

class MainNews extends StatelessWidget {
  const MainNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Main News Feed")),
      body: const Center(child: Text("News Page Content Here")),
    );
  }
}
