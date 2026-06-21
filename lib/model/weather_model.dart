class WeatherLocation {
  final String name;
  final String country;
  final String region;
  final String localtime;
  final String timezoneId;
  final double lat;
  final double lon;

  WeatherLocation({
    required this.name,
    required this.country,
    required this.region,
    required this.localtime,
    required this.timezoneId,
    required this.lat,
    required this.lon,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      region: json['region'] ?? '',
      localtime: json['localtime'] ?? '',
      timezoneId: json['timezone_id'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'region': region,
      'localtime': localtime,
      'timezone_id': timezoneId,
      'lat': lat,
      'lon': lon,
    };
  }
}

class WeatherCurrent {
  final int temperature;
  final int feelslike;
  final int humidity;
  final int windSpeed;
  final String windDir;
  final int uvIndex;
  final int visibility;
  final int cloudcover;
  final int pressure;
  final bool isDay;
  final List<String> weatherDescriptions;
  final List<String> weatherIcons;

  WeatherCurrent({
    required this.temperature,
    required this.feelslike,
    required this.humidity,
    required this.windSpeed,
    required this.windDir,
    required this.uvIndex,
    required this.visibility,
    required this.cloudcover,
    required this.pressure,
    required this.isDay,
    required this.weatherDescriptions,
    required this.weatherIcons,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      temperature: json['temperature'] ?? 0,
      feelslike: json['feelslike'] ?? 0,
      humidity: json['humidity'] ?? 0,
      windSpeed: json['wind_speed'] ?? 0,
      windDir: json['wind_dir'] ?? '',
      uvIndex: json['uv_index'] ?? 0,
      visibility: json['visibility'] ?? 0,
      cloudcover: json['cloudcover'] ?? 0,
      pressure: json['pressure'] ?? 0,
      isDay: (json['is_day'] ?? 'yes') == 'yes',
      weatherDescriptions: List<String>.from(json['weather_descriptions'] ?? []),
      weatherIcons: List<String>.from(json['weather_icons'] ?? []),
    );
  }

  String get primaryDescription =>
      weatherDescriptions.isNotEmpty ? weatherDescriptions.first : 'Unknown';

  String get primaryIcon =>
      weatherIcons.isNotEmpty ? weatherIcons.first : '';

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'feelslike': feelslike,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'wind_dir': windDir,
      'uv_index': uvIndex,
      'visibility': visibility,
      'cloudcover': cloudcover,
      'pressure': pressure,
      'is_day': isDay ? 'yes' : 'no',
      'weather_descriptions': weatherDescriptions,
      'weather_icons': weatherIcons,
    };
  }
}

class WeatherModel {
  final WeatherLocation location;
  final WeatherCurrent current;

  WeatherModel({required this.location, required this.current});

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      location: WeatherLocation.fromJson(json['location'] ?? {}),
      current: WeatherCurrent.fromJson(json['current'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location.toMap(),
      'current': current.toMap(),
    };
  }
}
