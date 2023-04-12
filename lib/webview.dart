
import 'package:flutter/material.dart';

class MyWebView extends StatelessWidget {
  final List<String> nouns;
  MyWebView({Key? key, required this.nouns}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('webview'),
      ),
       body: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var noun in nouns)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(noun),
            ),
        ],
      ),
    );
  }
}
