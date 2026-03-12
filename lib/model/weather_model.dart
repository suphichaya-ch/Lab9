class WeatherData {
  final double currentTemp;
  final int currentWeatherCode;
  final List<DailyForecast> dailyForecasts;

  WeatherData({
    required this.currentTemp,
    required this.currentWeatherCode,
    required this.dailyForecasts,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];

    List<DailyForecast> forecasts = [];
    final times = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final weatherCodes = daily['weathercode'] as List;

    for (int i = 0; i < times.length; i++) {
      forecasts.add(
        DailyForecast(
          date: DateTime.parse(times[i]),
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
          weatherCode: (weatherCodes[i] as num).toInt(),
        ),
      );
    }

    return WeatherData(
      currentTemp: (current['temperature_2m'] as num).toDouble(),
      currentWeatherCode: (current['weathercode'] as num).toInt(),
      dailyForecasts: forecasts,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });
}