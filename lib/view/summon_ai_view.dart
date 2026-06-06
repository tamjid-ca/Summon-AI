import 'package:flutter/material.dart';
import 'package:summon_ai/view_model/ai_view_model.dart';

class SummonAIView extends StatelessWidget {
  final AIViewModel viewModel;

  const SummonAIView({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AI API Tester'),
        elevation: 0,
      ),
      body: Center(
        // Reviewing Flutter Widgets: Column for vertical layout
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 40),
            
            // ListenableBuilder updates the UI only when the ViewModel changes
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, child) {
                return ElevatedButton(
                  // Disable the button if the app is currently loading
                  onPressed: viewModel.isLoading
                      ? null
                      : () async {
                          await viewModel.fetchAIResponse();
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Summon AI'),
                );
              },
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Check the Debug Console for the answer!',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}