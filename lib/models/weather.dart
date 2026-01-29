/// Datenmodell für Wetterdaten von OpenWeatherMap API
class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final int weatherId;
  final int humidity;
  final double windSpeed;
  final DateTime timestamp;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.weatherId,
    required this.humidity,
    required this.windSpeed,
    required this.timestamp,
  });

  /// Erstellt ein Weather-Objekt aus JSON-Daten der API
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      weatherId: json['weather'][0]['id'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }

  /// Konvertiert Weather-Objekt zu JSON
  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {
        'temp': temperature,
        'humidity': humidity,
      },
      'weather': [
        {
          'description': description,
          'id': weatherId,
        }
      ],
      'wind': {
        'speed': windSpeed,
      },
      'dt': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

/// Datenmodell für stündliche Wettervorhersage
class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int weatherId;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherId,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: json['temp'].toDouble(),
      weatherId: json['weather'][0]['id'],
    );
  }
}

/// Datenmodell für tägliche Wettervorhersage
class DailyWeather {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int weatherId;

  DailyWeather({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherId,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      minTemp: json['temp']['min'].toDouble(),
      maxTemp: json['temp']['max'].toDouble(),
      weatherId: json['weather'][0]['id'],
    );
  }
}
