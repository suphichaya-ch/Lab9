import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> getWeather(double latitude, double longitude) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weathercode'
      '&daily=temperature_2m_max,temperature_2m_min,weathercode'
      '&timezone=Asia/Bangkok'
      '&forecast_days=7',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return WeatherData.fromJson(json);
    } else {
      throw Exception('ไม่สามารถโหลดข้อมูลสภาพอากาศได้');
    }
  }
}
