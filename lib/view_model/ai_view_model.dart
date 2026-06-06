import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:summon_ai/model/ai_model.dart';

class AIViewModel extends ChangeNotifier {
  bool isLoading = false;

  // The core logic: Fetching the data and printing to the console
  Future<void> fetchAIResponse() async {
    isLoading = true;
    notifyListeners(); // Tells the UI to show a loading state

    try {
      // The 'Restaurant Waiter' analogy in action
      final url = Uri.parse('https://official-joke-api.appspot.com/random_joke');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parsing the JSON data
        final data = jsonDecode(response.body);
        final aiData = AIResponseModel.fromJson(data);

        // Fulfilling the mini-task: Printing the response to the console
        print('\n--- 🤖 AI SUMMONED SUCCESSFULLY ---');
        print('AI Setup: ${aiData.setup}');
        print('AI Punchline: ${aiData.punchline}');
        print('----------------------------------\n');
      } else {
        print('Error: The Waiter dropped the food! (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error: Could not reach the kitchen! ($e)');
    } finally {
      isLoading = false;
      notifyListeners(); // Tells the UI to stop loading
    }
  }
}