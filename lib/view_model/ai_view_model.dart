import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:summon_ai/model/ai_model.dart';

class AIViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  // Holds the most recently fetched joke
  AIResponseModel? currentJoke;

  // History of all fetched jokes in this session
  final List<AIResponseModel> jokeHistory = [];

  /// Fetches a random joke from the API and updates state.
  Future<void> fetchAIResponse() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://official-joke-api.appspot.com/random_joke');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiData = AIResponseModel.fromJson(data);

        currentJoke = aiData;
        jokeHistory.insert(0, aiData); // newest first
      } else {
        errorMessage = 'Server error (${response.statusCode}). Please try again.';
      }
    } catch (e) {
      errorMessage = 'Could not connect. Check your internet connection.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the current joke and history.
  void clearHistory() {
    currentJoke = null;
    jokeHistory.clear();
    errorMessage = null;
    notifyListeners();
  }
}