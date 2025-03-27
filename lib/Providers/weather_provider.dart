import 'package:flutter/material.dart';
import 'package:agribot/Models/weather.dart';
import 'package:agribot/Services/weather_services.dart';

class WeatherProvider with ChangeNotifier {
  Weather? _weather;
  bool _isLoading = false;
  final WeatherService _weatherService = WeatherService();

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;

  Future<void> fetchWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      String city = await _weatherService.getCurrentCity();
      final data = await _weatherService.getWeather(city);
      _weather = Weather.fromJson(data);
    } catch (e) {
      _weather = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
