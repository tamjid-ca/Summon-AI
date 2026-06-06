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
      title: 'Session 1: AI APIs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Injecting the ViewModel into the View
      home: SummonAIView(viewModel: AIViewModel()),
    );
  }
}