import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';

/// Widget für stündliche Wettervorhersage (WSJ-Style)
class HourlyWeatherCard extends StatelessWidget {
  final HourlyWeather hourlyWeather;
  final bool isNow;
  final IconData weatherIcon;

  const HourlyWeatherCard({
    super.key,
    required this.hourlyWeather,
    required this.isNow,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    String hourLabel = isNow ? "JETZT" : DateFormat('HH:mm').format(hourlyWeather.time);

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white.withOpacity(isNow ? 0.3 : 0.15),
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
              color: Colors.white.withOpacity(isNow ? 1 : 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            weatherIcon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            "${hourlyWeather.temperature.round()}°",
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
}
