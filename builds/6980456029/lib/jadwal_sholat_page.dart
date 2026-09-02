// jadwal_sholat_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JadwalSholatPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const JadwalSholatPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<JadwalSholatPage> createState() => _JadwalSholatPageState();
}

class _JadwalSholatPageState extends State<JadwalSholatPage> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _sholatData;
  String? _errorMessage;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);
  static const Color glassPrimary = Color(0x1ABB86FC);
  static const Color glassSecondary = Color(0x0DBB86FC);
  static const Color successGreen = Color(0xFF22C55E);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Future<void> _fetchJadwalSholat() async {
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
      _sholatData = null;
    });

    try {
      final url = Uri.parse("https://api.deline.web.id/info/jadwalsholat?kota=$city");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _sholatData = data['result'];
          });
        } else {
          setState(() {
            _errorMessage = "Kota tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data jadwal sholat";
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

  IconData _getSholatIcon(String name) {
    switch (name) {
      case 'Imsak':
        return Icons.bedtime;
      case 'Fajr':
        return Icons.brightness_5;
      case 'Sunrise':
        return Icons.wb_sunny;
      case 'Dhuhr':
        return Icons.sunny;
      case 'Asr':
        return Icons.brightness_6;
      case 'Sunset':
        return Icons.nightlight;
      case 'Maghrib':
        return Icons.nightlight_round;
      case 'Isha':
        return Icons.nights_stay;
      case 'Midnight':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  String _formatSholatName(String name) {
    switch (name) {
      case 'Fajr': return 'Subuh';
      case 'Sunrise': return 'Terbit';
      case 'Dhuhr': return 'Dzuhur';
      case 'Asr': return 'Ashar';
      case 'Sunset': return 'Terbenam';
      case 'Maghrib': return 'Maghrib';
      case 'Isha': return 'Isya';
      case 'Imsak': return 'Imsak';
      case 'Midnight': return 'Tengah Malam';
      case 'Firstthird': return 'Sepertiga Malam';
      case 'Lastthird': return 'Sepertiga Akhir';
      default: return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: purpleGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "JADWAL SHOLAT",
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
            child: const Icon(Icons.arrow_back_ios_new, color: accentPurple, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [accentPurple.withOpacity(0.15), bgDark, bgDark],
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
                      prefixIcon: const Icon(Icons.search, color: accentPurple),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: accentPurple),
                        onPressed: _fetchJadwalSholat,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _fetchJadwalSholat(),
                  ),
                ),

                const SizedBox(height: 24),

                // Loading
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: accentPurple),
                  ),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkPurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade300),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade200),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Jadwal Sholat Data
                if (_sholatData != null) ...[
                  // Lokasi & Tanggal Card
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
                        const Icon(Icons.mosque, color: accentPurple, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _sholatData!['lokasi'] ?? "Tidak diketahui",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _sholatData!['tanggal'] ?? "",
                            style: TextStyle(color: softGrey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sholatData!['hijri'] ?? "",
                          style: TextStyle(color: successGreen, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Waktu Sholat Grid
                  const Text(
                    "WAKTU SHOLAT",
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: _buildSholatList(),
                  ),

                  const SizedBox(height: 20),

                  // Catatan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: glassSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryWhite.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: accentPurple, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Jadwal sholat berdasarkan lokasi yang dipilih",
                            style: TextStyle(color: softGrey, fontSize: 11),
                          ),
                        ),
                      ],
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

  List<Widget> _buildSholatList() {
    final waktu = _sholatData!['waktu'] as Map<String, dynamic>;
    final List<String> order = [
      'Imsak', 'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 
      'Sunset', 'Maghrib', 'Isha', 'Midnight'
    ];
    
    final List<Widget> widgets = [];
    
    for (String key in order) {
      if (waktu.containsKey(key)) {
        widgets.add(_buildSholatCard(
          name: _formatSholatName(key),
          time: waktu[key].toString(),
        ));
      }
    }
    
    return widgets;
  }

  Widget _buildSholatCard({
    required String name,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSholatIcon(name),
              color: primaryWhite,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: accentPurple,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Grid Painter for background
class _GridPainter extends CustomPainter {
  static const Color accentPurple = Color(0xFFBB86FC);

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
      ..color = accentPurple.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentPurple.withOpacity(0.1)
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