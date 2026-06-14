import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:summon_ai/model/ai_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIViewModel extends ChangeNotifier {

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  );

  bool isLoading = false;
  String? errorMessage;

  AIResponseModel? currentJoke;

  final List<AIResponseModel> jokeHistory = [];

  // =========================
  // RANDOM JOKE API (OLD FEATURE)
  // =========================
  Future<void> fetchAIResponse() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://official-joke-api.appspot.com/random_joke',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiData = AIResponseModel.fromJson(data);

        currentJoke = aiData;
        jokeHistory.insert(0, aiData);
      } else {
        errorMessage =
            'Server error (${response.statusCode}). Please try again.';
      }
    } catch (e) {
      errorMessage = 'Could not connect. Check your internet connection.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // GEMINI AI CHAT (NEW)
  // =========================
  Future<void> askGemini(String prompt) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final content = [Content.text(prompt)];

      final response = await model.generateContent(content);

      final text = response.text ?? "No response from Gemini";

      final aiData = AIResponseModel(
        setup: prompt,
        punchline: text,
      );

      currentJoke = aiData;
      jokeHistory.insert(0, aiData);

    } catch (e) {
      errorMessage = "Gemini error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // CLEAR HISTORY
  // =========================
  void clearHistory() {
    currentJoke = null;
    jokeHistory.clear();
    errorMessage = null;
    notifyListeners();
  }
}