import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:summon_ai/model/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'http://api.weatherstack.com/current';

  String get _apiKey => dotenv.env['WEATHERSTACK_API_KEY'] ?? '';

  /// Fetch weather by latitude and longitude (for current location).
  Future<WeatherModel> fetchWeatherByCoords(double lat, double lon) async {
    final query = '$lat,$lon';
    return _fetch(query);
  }

  /// Fetch weather by city name (for custom locations).
  Future<WeatherModel> fetchWeatherByCity(String city) async {
    return _fetch(city);
  }

  Future<WeatherModel> _fetch(String query) async {
    final uri = Uri.parse(
      '$_baseUrl?access_key=$_apiKey&query=${Uri.encodeComponent(query)}&units=m',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Weatherstack returns success:false on API errors
    if (data['success'] == false) {
      final error = data['error'] as Map<String, dynamic>?;
      final info = error?['info'] ?? 'Unknown API error.';
      throw Exception(info);
    }

    return WeatherModel.fromJson(data);
  }
}
