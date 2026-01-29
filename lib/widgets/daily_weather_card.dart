import 'package:flutter/material.dart';
import '../models/weather.dart';

/// Widget für tägliche Wettervorhersage (WSJ-Style)
class DailyWeatherCard extends StatelessWidget {
  final DailyWeather dailyWeather;
  final String dayLabel;
  final bool isToday;
  final IconData weatherIcon;

  const DailyWeatherCard({
    super.key,
    required this.dailyWeather,
    required this.dayLabel,
    required this.isToday,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white.withOpacity(isToday ? 0.25 : 0.12),
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
                color: Colors.white.withOpacity(isToday ? 1 : 0.8),
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
              weatherIcon,
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
                  "${dailyWeather.minTemp.round()}°",
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
                  "${dailyWeather.maxTemp.round()}°",
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
