class AIResponseModel {
  final String setup;
  final String punchline;

  AIResponseModel({required this.setup, required this.punchline});

  // Factory constructor to parse JSON data into our Model
  factory AIResponseModel.fromJson(Map<String, dynamic> json) {
    return AIResponseModel(
      setup: json['setup'] ?? 'No setup provided',
      punchline: json['punchline'] ?? 'No punchline provided',
    );
  }
}