import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LaughPro());
}

class LaughPro extends StatelessWidget {
  const LaughPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String joke = "🎲 Tap the dice!";
  double turns = 0;

  int xp = 0;
  int level = 1;

  List<String> favorites = [];

  late ConfettiController confetti;

  @override
  void initState() {
    super.initState();
    confetti = ConfettiController(duration: const Duration(seconds: 1));
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList("fav") ?? [];
      xp = prefs.getInt("xp") ?? 0;
      level = prefs.getInt("level") ?? 1;
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("fav", favorites);
    prefs.setInt("xp", xp);
    prefs.setInt("level", level);
  }

  Future<void> roll() async {
    setState(() {
      turns += 4;
    });

    final res = await http.get(
      Uri.parse("https://api.freeapi.app/api/v1/public/randomjokes/joke/random"),
    );

    final data = jsonDecode(res.body);
    String newJoke = data['data']['content'];

    setState(() {
      joke = "$newJoke 😂🤣😆";
      xp += 10;

      if (xp >= level * 100) {
        level++;
        xp = 0;
      }
    });

    confetti.play();
    saveData();
  }

  void addFavorite() {
    setState(() {
      if (!favorites.contains(joke)) {
        favorites.add(joke);
      }
    });
    saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text("😂 Laugh PRO"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(favorites),
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🏆 Level $level  |  XP: $xp/100"),

              const SizedBox(height: 20),

              AnimatedRotation(
                turns: turns,
                duration: const Duration(milliseconds: 700),
                child: GestureDetector(
                  onTap: roll,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.casino,
                      size: 90,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  joke,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),

              ElevatedButton(
                onPressed: addFavorite,
                child: const Text("⭐ Add Favorite"),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<String> favorites;

  const FavoritesScreen(this.favorites, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⭐ Favorites")),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(favorites[index]),
          );
        },
      ),
    );
  }
}