import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  runApp(const LaughLauncher());
}

class LaughLauncher extends StatelessWidget {
  const LaughLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const JokeScreen(),
    );
  }
}

class JokeScreen extends StatefulWidget {
  const JokeScreen({super.key});

  @override
  State<JokeScreen> createState() => _JokeScreenState();
}

class _JokeScreenState extends State<JokeScreen> {
  final List<String> jokes = [
    "Why don't eggs tell jokes? 😂 They'd crack up!",
    "I used to hate facial hair. 😆 Then it grew on me!",
    "What has keys but can't open locks? 🤔 A piano!",
    "Why was the math book sad? 😂 Too many problems!",
    "What do you call fake spaghetti? 🤣 An impasta!"
  ];

  String currentJoke = "Tap the dice to roll for laughs!";
  double turns = 0;

  void rollDice() {
    setState(() {
      turns += 3;
      currentJoke = jokes[Random().nextInt(jokes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("😂 Laugh Launcher"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            AnimatedRotation(
              turns: turns,
              duration: const Duration(seconds: 1),
              child: GestureDetector(
                onTap: rollDice,
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.casino,
                    size: 100,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Tap the dice!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentJoke,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
              ),
            )
                .animate()
                .fade(duration: 500.ms)
                .scale(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("😂", style: TextStyle(fontSize: 30)),
                SizedBox(width: 10),
                Text("🤣", style: TextStyle(fontSize: 30)),
                SizedBox(width: 10),
                Text("😆", style: TextStyle(fontSize: 30)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}