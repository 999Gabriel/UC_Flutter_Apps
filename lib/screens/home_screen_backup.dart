import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);

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
        fontFamily: 'Constantia',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          cityName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => _showSearchDialog(context),
              icon: const Icon(Icons.search_rounded, size: 22),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: fetchWeatherData,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF000000),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Stadt nicht gefunden",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _showSearchDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              "Neue Stadt suchen",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildModernLayout(),
      ),
    );
  }

  // Show search dialog
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Stadt suchen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: "z.B. Wien, Berlin, Paris...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.location_on_rounded, color: Colors.white38),
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                searchCity(value);
                _searchController.clear();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchController.clear();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Abbrechen",
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  searchCity(_searchController.text);
                  _searchController.clear();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.transparent,
                ),
                child: const Text(
                  "Suchen",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Weather Card - WSJ Style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cityName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, d MMM', 'de_DE').format(DateTime.now()).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Temperature Section
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temperature - Large and Bold
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$currentTemp",
                                  style: const TextStyle(
                                    fontSize: 96,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    height: 0.9,
                                    letterSpacing: -4,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    "°C",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              description.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Weather Icon - Minimal
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(
                          getWeatherIcon(weatherId),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // High/Low Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildWSJTempDetail("HOCH", "$highTemp°"),
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      Expanded(
                        child: _buildWSJTempDetail("TIEF", "$lowTemp°"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Section Divider
          Container(
            height: 0.5,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 24),

          Text(
            "STÜNDLICHE VORHERSAGE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

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

          const SizedBox(height: 48),

          Container(
            height: 0.5,
            color: Colors.white.withOpacity(0.2),
          ),

          const SizedBox(height: 24),

          Text(
            "7-TAGE-VORHERSAGE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Weekly List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              return _buildDailyItem(index);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWSJTempDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: -1,
          ),
        ),
      ],
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
      hourLabel = "JETZT";
    } else {
      hourLabel = DateFormat('HH:mm').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white.withOpacity(index == 0 ? 0.3 : 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hourLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(index == 0 ? 1 : 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            getWeatherIcon(weatherId),
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            "${temp.round()}°",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
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
      dayLabel = "HEUTE";
    } else {
      final weekdays = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
      dayLabel = weekdays[date.weekday - 1];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white.withOpacity(index == 0 ? 0.25 : 0.12),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              dayLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(index == 0 ? 1 : 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              getWeatherIcon(weatherId),
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  "${minC.round()}°",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                width: 0.5,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.15),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  "${maxC.round()}°",
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
