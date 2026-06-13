import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const JokeApp());
}

class JokeApp extends StatelessWidget {
  const JokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: JokeScreen(),
    );
  }
}

class JokeScreen extends StatefulWidget {
  const JokeScreen({super.key});

  @override
  State<JokeScreen> createState() => _JokeScreenState();
}

class _JokeScreenState extends State<JokeScreen> {
  String joke = "Press the button for a joke!";

  Future<void> getJoke() async {
    final response = await http.get(
      Uri.parse(
        "https://api.freeapi.app/api/v1/public/randomjokes/joke/random",
      ),
    );

    final data = jsonDecode(response.body);

    setState(() {
      joke = data["data"]["content"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("😂 Joke App"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            joke,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getJoke,
        child: const Icon(Icons.casino),
      ),
    );
  }
}