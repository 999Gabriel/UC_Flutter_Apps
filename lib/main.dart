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

  // OpenWeatherMap API Key
  final String apiKey = '711b0df3e461b3c35e8ca67b28920759';

  // Geocoding API to get coordinates from city name
  Future<void> searchCity(String cityName) async {
    if (cityName.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$cityName&limit=1&appid=$apiKey');

      print('Geocoding URL: $url');
      final response = await http.get(url);
      print('Geocoding Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          setState(() {
            latitude = result['lat'];
            longitude = result['lon'];
            this.cityName = result['name'];
          });
          await fetchWeatherData();
        } else {
          print('No results found for city: $cityName');
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        print('Geocoding API Error: ${response.statusCode}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Geocoding Exception: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchWeatherData() async {
    try {
      // Fetch current weather
      final currentUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&lang=de&appid=$apiKey');

      // Fetch 5-day forecast (3-hour intervals)
      final forecastUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&lang=de&appid=$apiKey');

      print('Current Weather URL: $currentUrl');
      print('Forecast URL: $forecastUrl');

      final currentResponse = await http.get(currentUrl);
      final forecastResponse = await http.get(forecastUrl);

      print('Current Response: ${currentResponse.statusCode}');
      print('Forecast Response: ${forecastResponse.statusCode}');

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        // Convert to One Call API format for compatibility
        final convertedData = _convertToOneCallFormat(currentData, forecastData);

        setState(() {
          weatherData = convertedData;
          isLoading = false;
        });
      } else {
        print('Weather API Error: Current=${currentResponse.statusCode}, Forecast=${forecastResponse.statusCode}');
        print('Current Body: ${currentResponse.body}');
        print('Forecast Body: ${forecastResponse.body}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Weather API Exception: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // Convert free API data to One Call API format
  Map<String, dynamic> _convertToOneCallFormat(Map<String, dynamic> current, Map<String, dynamic> forecast) {
    final forecastList = forecast['list'] as List;

    // Group by day for daily forecast
    final dailyMap = <String, Map<String, dynamic>>{};
    final hourlyList = <Map<String, dynamic>>[];

    for (var item in forecastList) {
      final dt = item['dt'];
      final date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Add to hourly (take first 24 hours = 8 items since they're 3-hour intervals)
      if (hourlyList.length < 24) {
        hourlyList.add({
          'dt': dt,
          'temp': item['main']['temp'],
          'weather': item['weather'],
        });
      }

      // Group for daily
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = {
          'dt': dt,
          'temp': {'min': item['main']['temp_min'], 'max': item['main']['temp_max']},
          'weather': item['weather'],
        };
      } else {
        // Update min/max temps
        if (item['main']['temp_min'] < dailyMap[dateKey]!['temp']['min']) {
          dailyMap[dateKey]!['temp']['min'] = item['main']['temp_min'];
        }
        if (item['main']['temp_max'] > dailyMap[dateKey]!['temp']['max']) {
          dailyMap[dateKey]!['temp']['max'] = item['main']['temp_max'];
        }
      }
    }

    return {
      'current': {
        'dt': current['dt'],
        'temp': current['main']['temp'],
        'weather': current['weather'],
      },
      'hourly': hourlyList,
      'daily': dailyMap.values.toList(),
    };
  }

  // Helper to interpret OpenWeatherMap Weather condition IDs
  // Reference: https://openweathermap.org/weather-conditions
  String getWeatherDescription(int id) {
    if (id >= 200 && id < 300) return 'Gewitter';
    if (id >= 300 && id < 400) return 'Nieselregen';
    if (id >= 500 && id < 600) return 'Regen';
    if (id >= 600 && id < 700) return 'Schnee';
    if (id >= 700 && id < 800) return 'Nebel';
    if (id == 800) return 'Klar';
    if (id == 801) return 'Leicht bewölkt';
    if (id == 802) return 'Teils bewölkt';
    if (id == 803) return 'Überwiegend bewölkt';
    if (id == 804) return 'Bedeckt';
    return 'Klar';
  }

  IconData getWeatherIcon(int id) {
    if (id >= 200 && id < 300) return Icons.flash_on;
    if (id >= 300 && id < 400) return Icons.grain;
    if (id >= 500 && id < 600) return Icons.water_drop;
    if (id >= 600 && id < 700) return Icons.ac_unit;
    if (id >= 700 && id < 800) return Icons.blur_on;
    if (id == 800) return Icons.wb_sunny_rounded;
    if (id == 801) return Icons.wb_sunny_outlined;
    if (id == 802) return Icons.cloud_queue_rounded;
    if (id >= 803) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
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
    final currentWeather = current['weather'][0];
    final currentTemp = current['temp'].round();
    final description = currentWeather['description'];
    final weatherId = currentWeather['id'];
    final highTemp = daily[0]['temp']['max'].round();
    final lowTemp = daily[0]['temp']['min'].round();

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
                      getWeatherIcon(weatherId),
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

    if (index >= hourly.length) {
      return const SizedBox();
    }

    final hourData = hourly[index];
    final timestamp = hourData['dt'];
    final temp = hourData['temp'];
    final weatherId = hourData['weather'][0]['id'];
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

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
          Icon(getWeatherIcon(weatherId), color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text("${temp.round()}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDailyItem(int index) {
    final daily = weatherData!['daily'];

    if (index >= daily.length) {
      return const SizedBox();
    }

    final dayData = daily[index];
    final timestamp = dayData['dt'];
    final minC = dayData['temp']['min'];
    final maxC = dayData['temp']['max'];
    final weatherId = dayData['weather'][0]['id'];
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

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
          Icon(getWeatherIcon(weatherId), color: Colors.blueAccent, size: 24),
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
