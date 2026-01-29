import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Style Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: '.SF Pro Display', // iOS-like font if available, fallback to default
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  // Default location: Innsbruck, Tirol
  double latitude = 47.2692;
  double longitude = 11.4041;
  String cityName = "Innsbruck";

  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  bool hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Geocoding API to get coordinates from city name
  Future<void> searchCity(String cityName) async {
    if (cityName.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=de&format=json');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          setState(() {
            latitude = result['latitude'];
            longitude = result['longitude'];
            this.cityName = result['name'];
          });
          await fetchWeatherData();
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchWeatherData() async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // Helper to interpret WMO Weather codes
  // 0: Clear, 1-3: Cloudy, 45-48: Fog, 51-67: Rain/Drizzle, 71-77: Snow, 80-82: Showers, 95-99: Thunderstorm
  String getWeatherDescription(int code) {
    switch (code) {
      case 0: return 'Klar';
      case 1: return 'Überwiegend klar';
      case 2: return 'Teils bewölkt';
      case 3: return 'Bedeckt';
      case 45: case 48: return 'Nebel';
      case 51: case 53: case 55: return 'Nieselregen';
      case 61: case 63: case 65: return 'Regen';
      case 66: case 67: return 'Gefrierender Regen';
      case 71: case 73: case 75: return 'Schnee';
      case 77: return 'Schneegriesel';
      case 80: case 81: case 82: return 'Regenschauer';
      case 85: case 86: return 'Schneeschauer';
      case 95: return 'Gewitter';
      case 96: case 99: return 'Gewitter mit Hagel';
      default: return 'Klar';
    }
  }

  IconData getWeatherIcon(int code) {
    switch (code) {
      case 0: return Icons.wb_sunny_rounded;
      case 1: return Icons.wb_sunny_outlined;
      case 2: return Icons.cloud_queue_rounded;
      case 3: return Icons.cloud_rounded;
      case 45: case 48: return Icons.blur_on;
      case 51: case 53: case 55: return Icons.grain;
      case 61: case 63: case 65: return Icons.water_drop;
      case 66: case 67: return Icons.ac_unit;
      case 71: case 73: case 75: return Icons.ac_unit;
      case 80: case 81: case 82: return Icons.umbrella;
      case 95: case 96: case 99: return Icons.flash_on;
      default: return Icons.wb_sunny_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark matte background
      appBar: AppBar(
        title: Text(cityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: fetchWeatherData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Stadt nicht gefunden",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showSearchDialog(context),
                        child: const Text("Neue Stadt suchen"),
                      ),
                    ],
                  ),
                )
              : _buildModernLayout(),
    );
  }

  // Show search dialog
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Stadt suchen",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "z.B. Wien, Berlin, Paris...",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            searchCity(value);
            _searchController.clear();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
            },
            child: const Text("Abbrechen", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              searchCity(_searchController.text);
              _searchController.clear();
            },
            child: const Text("Suchen", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLayout() {
    final current = weatherData!['current'];
    final daily = weatherData!['daily'];
    final currentCode = current['weather_code'];
    final currentTemp = current['temperature_2m'].round();
    final description = getWeatherDescription(currentCode);
    final highTemp = daily['temperature_2m_max'][0].round();
    final lowTemp = daily['temperature_2m_min'][0].round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Weather Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$currentTemp°",
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      getWeatherIcon(currentCode),
                      size: 64,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "H: $highTemp°  T: $lowTemp°",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Vorhersage",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Hourly List
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 24,
              itemBuilder: (context, index) {
                return _buildHourlyItem(index);
              },
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Diese Woche",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Weekly List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              return _buildDailyItem(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyItem(int index) {
    final hourly = weatherData!['hourly'];
    final timeList = hourly['time'] as List;
    final now = DateTime.now();

    // Find the current hour in the list
    int currentHourIndex = 0;
    for (int i = 0; i < timeList.length; i++) {
      final time = DateTime.parse(timeList[i]);
      if (time.year == now.year &&
          time.month == now.month &&
          time.day == now.day &&
          time.hour == now.hour) {
        currentHourIndex = i;
        break;
      }
    }

    final targetIndex = currentHourIndex + index;

    if (targetIndex < 0 || targetIndex >= timeList.length) {
      return const SizedBox();
    }

    final timeStr = timeList[targetIndex];
    final temp = hourly['temperature_2m'][targetIndex];
    final code = hourly['weather_code'][targetIndex];
    final date = DateTime.parse(timeStr);

    String hourLabel;
    if (index == 0) {
      hourLabel = "Jetzt";
    } else {
      hourLabel = DateFormat('HH:mm').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF383838),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hourLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Icon(getWeatherIcon(code), color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text("${temp.round()}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDailyItem(int index) {
    final daily = weatherData!['daily'];
    final timeStr = daily['time'][index];
    final minC = daily['temperature_2m_min'][index];
    final maxC = daily['temperature_2m_max'][index];
    final code = daily['weather_code'][index];
    final date = DateTime.parse(timeStr);

    // German day names
    String dayLabel;
    if (index == 0) {
      dayLabel = "Heute";
    } else {
      final weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
      dayLabel = weekdays[date.weekday - 1];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(dayLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Icon(getWeatherIcon(code), color: Colors.blueAccent, size: 24),
          Expanded(
            flex: 2,
            child: Text(
              "${minC.round()}° / ${maxC.round()}°",
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
