// weather_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const WeatherPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  String? _errorMessage;

  // --- MODERN RED THEME ---
  static const Color bgDark = Color(0xFF000000);
  static const Color accentRed = Color(0xFF9E9E9E);
  static const Color darkRed = Color(0xFF212121);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF9E9E9E);
  static const Color glassPrimary = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x0DFFFFFF);

  LinearGradient get redGradient => const LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF424242)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Future<void> _fetchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan nama kota";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
    });

    try {
      final url = Uri.parse("https://api.siputzx.my.id/api/info/cuaca?q=$city");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _weatherData = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = "Kota tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data cuaca";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getWeatherIconData(String weatherDesc) {
    if (weatherDesc.contains("Cerah")) return Icons.wb_sunny;
    if (weatherDesc.contains("Berawan")) return Icons.cloud;
    if (weatherDesc.contains("Hujan")) return Icons.beach_access;
    if (weatherDesc.contains("Petir")) return Icons.flash_on;
    if (weatherDesc.contains("Kabut")) return Icons.cloud_queue;
    if (weatherDesc.contains("Angin")) return Icons.air;
    return Icons.help_outline;
  }

  IconData _getWindDirectionIcon(String wd) {
    if (wd == "U") return Icons.navigation;
    if (wd == "S") return Icons.south;
    if (wd == "T") return Icons.east;
    if (wd == "B") return Icons.west;
    if (wd == "TL") return Icons.north_east;
    if (wd == "TG") return Icons.south_east;
    if (wd == "BL") return Icons.north_west;
    if (wd == "BG") return Icons.south_west;
    return Icons.compass_calibration;
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data cuaca pertama (current weather)
    Map<dynamic, dynamic>? currentWeather;
    String? locationName;
    String? provinsi;
    String? kotkab;

    if (_weatherData != null) {
      final weatherList = _weatherData!['weather'] as List?;
      if (weatherList != null && weatherList.isNotEmpty) {
        final firstWeather = weatherList[0];
        final lokasi = firstWeather['lokasi'] as Map?;
        if (lokasi != null) {
          provinsi = lokasi['provinsi'];
          kotkab = lokasi['kotkab'];
          locationName = lokasi['desa'] ?? lokasi['kecamatan'];
        }
        
        final cuacaList = firstWeather['cuaca'] as List?;
        if (cuacaList != null && cuacaList.isNotEmpty) {
          final firstCuaca = cuacaList[0] as List?;
          if (firstCuaca != null && firstCuaca.isNotEmpty) {
            currentWeather = firstCuaca[0] as Map?;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: redGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentRed.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "CEK CUACA",
            style: TextStyle(
              color: primaryWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: accentRed, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [accentRed.withOpacity(0.15), bgDark, bgDark],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: glassSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryWhite.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _cityController,
                    style: const TextStyle(color: primaryWhite),
                    decoration: InputDecoration(
                      hintText: "Cari kota...",
                      hintStyle: TextStyle(color: softGrey.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: accentRed),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: accentRed),
                        onPressed: _fetchWeather,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _fetchWeather(),
                  ),
                ),

                const SizedBox(height: 24),

                // Loading
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: accentRed),
                  ),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Weather Data
                if (_weatherData != null && currentWeather != null) ...[
                  // Lokasi Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: glassPrimary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryWhite.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.location_on_rounded, color: accentRed, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          locationName ?? "Tidak diketahui",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (provinsi != null)
                          Text(
                            "$provinsi, $kotkab",
                            style: TextStyle(color: softGrey, fontSize: 13),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cuaca Sekarang Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: redGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accentRed.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon cuaca
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryWhite.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getWeatherIconData(currentWeather['weather_desc'] ?? ""),
                            color: primaryWhite,
                            size: 48,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Suhu
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${currentWeather['t']?.toString() ?? "?"}°C",
                              style: const TextStyle(
                                color: primaryWhite,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentWeather['weather_desc'] ?? "Tidak diketahui",
                              style: const TextStyle(
                                color: primaryWhite,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detail Cuaca (Info tambahan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: glassPrimary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryWhite.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                icon: Icons.water_drop,
                                label: "Kelembaban",
                                value: "${currentWeather['hu'] ?? "?"}%",
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                icon: Icons.air,
                                label: "Kecepatan Angin",
                                value: "${currentWeather['ws'] ?? "?"} km/h",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                icon: _getWindDirectionIcon(currentWeather['wd'] ?? ""),
                                label: "Arah Angin",
                                value: currentWeather['wd'] ?? "?",
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                icon: Icons.visibility,
                                label: "Visibilitas",
                                value: currentWeather['vs_text'] ?? "?",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Prakiraan 5 Jam ke Depan
                  const Text(
                    "PRAKIRAAN 5 JAM KE DEPAN",
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _getNext5Weather().length,
                      itemBuilder: (context, index) {
                        final weather = _getNext5Weather()[index];
                        return Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: glassPrimary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryWhite.withOpacity(0.08)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weather['time'] ?? "",
                                style: const TextStyle(
                                  color: accentRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Icon(
                                _getWeatherIconData(weather['weather_desc'] ?? ""),
                                color: primaryWhite,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${weather['t']?.toString() ?? "?"}°C",
                                style: const TextStyle(
                                  color: primaryWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: accentRed, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: primaryWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: softGrey, fontSize: 11),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getNext5Weather() {
    if (_weatherData == null) return [];
    
    final weatherList = _weatherData!['weather'] as List?;
    if (weatherList == null || weatherList.isEmpty) return [];
    
    final firstWeather = weatherList[0];
    final cuacaList = firstWeather['cuaca'] as List?;
    if (cuacaList == null || cuacaList.isEmpty) return [];
    
    final firstCuaca = cuacaList[0] as List?;
    if (firstCuaca == null) return [];
    
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < firstCuaca.length && i < 5; i++) {
      final item = firstCuaca[i] as Map;
      result.add({
        'time': _formatTime(item['local_datetime']),
        't': item['t'],
        'weather_desc': item['weather_desc'],
      });
    }
    return result;
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return "";
    try {
      final parts = datetime.split(' ');
      if (parts.length > 1) {
        return parts[1].substring(0, 5);
      }
      return datetime;
    } catch (e) {
      return datetime;
    }
  }
}

// Custom Grid Painter for background
class _GridPainter extends CustomPainter {
  static const Color accentRed = Color(0xFF9E9E9E);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accentPaint = Paint()
      ..color = accentRed.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentRed.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}