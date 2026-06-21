class AIResponseModel {
  final String setup;
  final String punchline;
  final DateTime? createdAt;

  AIResponseModel({
    required this.setup,
    required this.punchline,
    this.createdAt,
  });

  factory AIResponseModel.fromJson(Map<String, dynamic> json) {
    return AIResponseModel(
      setup: json['setup'] ?? 'No setup provided',
      punchline: json['punchline'] ?? 'No punchline provided',
    );
  }

  factory AIResponseModel.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    return AIResponseModel(
      setup: map['setup'] ?? 'No setup provided',
      punchline: map['punchline'] ?? 'No punchline provided',
      createdAt: createdAtValue is DateTime ? createdAtValue : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setup': setup,
      'punchline': punchline,
      'createdAt': createdAt,
    };
  }
}
