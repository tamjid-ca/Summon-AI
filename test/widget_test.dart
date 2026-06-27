// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:summon_ai/model/ai_model.dart';
import 'package:summon_ai/model/weather_model.dart';

void main() {
  test('AIResponseModel stores setup and punchline', () {
    final joke = AIResponseModel.fromJson({
      'setup': 'Why did the developer use Firebase?',
      'punchline': 'To stop rebuilding the backend for every class project.',
    });

    expect(joke.setup, 'Why did the developer use Firebase?');
    expect(joke.punchline, 'To stop rebuilding the backend for every class project.');
  });

  test('WeatherModel converts API data into app data', () {
    final weather = WeatherModel.fromJson({
      'location': {
        'name': 'Dhaka',
        'country': 'Bangladesh',
        'region': 'Dhaka',
        'localtime': '2026-06-20 10:00',
        'timezone_id': 'Asia/Dhaka',
        'lat': 23.81,
        'lon': 90.41,
      },
      'current': {
        'temperature': 31,
        'feelslike': 36,
        'humidity': 70,
        'wind_speed': 10,
        'wind_dir': 'S',
        'uv_index': 6,
        'visibility': 10,
        'cloudcover': 30,
        'pressure': 1008,
        'is_day': 'yes',
        'weather_descriptions': ['Partly cloudy'],
        'weather_icons': ['https://example.com/icon.png'],
      },
    });

    expect(weather.location.name, 'Dhaka');
    expect(weather.current.primaryDescription, 'Partly cloudy');
    expect(weather.toMap()['location']['country'], 'Bangladesh');
  });
}
