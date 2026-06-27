import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:summon_ai/model/ai_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:summon_ai/service/user_data_service.dart';

class AIViewModel extends ChangeNotifier {
  final UserDataService _userDataService = UserDataService();

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY'),
    );
    return _model!;
  }

  bool isLoading = false;
  String? errorMessage;

  AIResponseModel? currentJoke;

  final List<AIResponseModel> jokeHistory = [];

  Future<void> loadUserHistory() async {
    try {
      final jokes = await _userDataService.loadJokes();
      jokeHistory
        ..clear()
        ..addAll(jokes);
      currentJoke = jokeHistory.isNotEmpty ? jokeHistory.first : null;
      notifyListeners();
    } catch (_) {
      errorMessage = 'Could not load saved jokes.';
      notifyListeners();
    }
  }

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
        unawaited(_userDataService.saveJoke(aiData));
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
      unawaited(_userDataService.saveJoke(aiData));

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
    unawaited(_userDataService.clearJokes());
    notifyListeners();
  }
}
