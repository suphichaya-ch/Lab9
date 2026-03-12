import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui'; // สำหรับ BackdropFilter
import 'data/thai_provinces.dart';
import 'model/weather_model.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'พยากรณ์อากาศ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Sukhumvit', // หรือฟอนต์ที่คุณมี
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent, brightness: Brightness.dark),
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
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  Province _selectedProvince = thaiProvinces.first;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  List<Province> _filteredProvinces = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _weatherService.getWeather(
        _selectedProvince.latitude, _selectedProvince.longitude,
      );
      setState(() { _weatherData = data; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล'; _isLoading = false; });
    }
  }

  void _searchProvince(String query) {
    if (query.isEmpty) {
      setState(() { _filteredProvinces = []; _showSearchResults = false; });
      return;
    }
    final results = thaiProvinces.where((p) =>
        p.nameTh.contains(query) || p.nameEn.toLowerCase().contains(query.toLowerCase())).toList();
    setState(() { _filteredProvinces = results; _showSearchResults = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Weather Forecast', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // ปรับสี Gradient ตามสภาพอากาศได้ที่นี่
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: Stack(
                  children: [
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _buildMainContent(),
                    if (_showSearchResults) _buildSearchResultsOverlay(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _searchProvince,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ค้นหาจังหวัด...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    return Positioned(
      left: 20, right: 20, top: 0,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _filteredProvinces.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = _filteredProvinces[index];
            return ListTile(
              title: Text(p.nameTh, style: const TextStyle(color: Colors.black)),
              onTap: () {
                setState(() { _selectedProvince = p; _showSearchResults = false; _searchController.clear(); });
                _loadWeather();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)));
    if (_weatherData == null) return const SizedBox();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCurrentWeather(),
          const SizedBox(height: 30),
          _buildForecastSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Column(
      children: [
        Text(_selectedProvince.nameTh, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(DateFormat('EEEE d MMMM', 'th').format(DateTime.now()), style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 20),
        // ไอคอนอากาศ (ใส่ URL ของไอคอนจริงจะสวยมาก)
        const Icon(Icons.cloud_queue, size: 100, color: Colors.white), 
        Text('${_weatherData!.currentTemp.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200, color: Colors.white)),
        Text(_getWeatherDescription(_weatherData!.currentWeatherCode), style: const TextStyle(fontSize: 22, color: Colors.white)),
      ],
    );
  }

  Widget _buildForecastSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('พยากรณ์ 7 วัน', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 25),
          ..._weatherData!.dailyForecasts.map((forecast) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 100, child: Text(DateFormat('EEEE', 'th').format(forecast.date), style: const TextStyle(color: Colors.white, fontSize: 16))),
                  _getWeatherIcon(forecast.weatherCode),
                  Text('${forecast.maxTemp.toStringAsFixed(0)}° / ${forecast.minTemp.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(int code) {
    IconData icon = Icons.wb_sunny_rounded;
    if (code >= 61) icon = Icons.umbrella_rounded;
    if (code >= 3) icon = Icons.cloud_rounded;
    return Icon(icon, color: Colors.white, size: 24);
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'ท้องฟ้าแจ่มใส';
    if (code <= 3) return 'มีเมฆบางส่วน';
    if (code >= 61 && code <= 65) return 'ฝนตก';
    if (code == 95) return 'พายุฝนฟ้าคะนอง';
    return 'เมฆมาก';
  }
}