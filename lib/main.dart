import 'package:flutter/material.dart';
import 'package:summon_ai/view/summon_ai_view.dart';
import 'package:summon_ai/view_model/ai_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Summon AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B2FBE),
          secondary: Color(0xFF4776E6),
          surface: Color(0xFF1A1A35),
        ),
        useMaterial3: true,
      ),
      home: SummonAIView(viewModel: AIViewModel()),
    );
  }
}