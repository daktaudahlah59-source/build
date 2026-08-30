import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'vip_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'chat_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listGroupBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listGroupBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  // --- State Variabel ---
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listGroupBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  // --- Fitur Profil & Menu Baru ---
  String androidId = "unknown";
  File? _profileImage;
  VideoPlayerController? _menuVideoController;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;

  // --- Fitur Jadwal Sholat ---
  bool isLoadingPrayer = true;
  String? prayerError;
  String currentLocation = "Mendeteksi lokasi...";
  String currentCity = "";
  String currentProvince = "";
  Map<String, String> prayerTimes = {
    'subuh': '--:--',
    'dzuhur': '--:--',
    'ashar': '--:--',
    'maghrib': '--:--',
    'isya': '--:--',
  };
  String currentDate = "";

  // --- TEMA WARNA UNGU (KONSISTEN) ---
  final Color bgDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFEA80FC);
  final Color lightPurple = const Color(0xFFB388FF);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listGroupBug = widget.listGroupBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    _initMenuVideo();
    _getPrayerSchedule();
  }

  // ==================== JADWAL SHOLAT REAL-TIME (FIXED NULL SAFETY) ====================
  Future<void> _getPrayerSchedule() async {
    setState(() {
      isLoadingPrayer = true;
      prayerError = null;
    });

    final now = DateTime.now();
    setState(() {
      currentDate = "${now.day} ${_getMonthName(now.month)} ${now.year}";
    });

    await _checkAndRequestLocationPermission();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isDenied) {
      setState(() {
        prayerError = "Izin lokasi diperlukan untuk jadwal sholat. Silakan izinkan akses lokasi.";
        isLoadingPrayer = false;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        prayerError = "Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan aplikasi.";
        isLoadingPrayer = false;
      });
    }
  }

  // ==================== FUNGSI _getCurrentLocation YANG SUDAH DIPERBAIKI ====================
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          prayerError = "Layanan lokasi tidak aktif. Silakan aktifkan GPS Anda.";
          isLoadingPrayer = false;
        });
        return;
      }

      // 1. Coba ambil lokasi terakhir yang tersimpan (Sangat Cepat & Anti Timeout)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Jika lokasi terakhir tidak ada, baru minta lokasi baru
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          // Gunakan accuracy medium agar lebih cepat mengunci sinyal daripada high
          desiredAccuracy: LocationAccuracy.medium, 
          // Naikkan limit waktu ke 15 detik agar lebih toleran
          timeLimit: const Duration(seconds: 15),
        );
      }
      
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      // Jika masih timeout, kita beri pesan yang lebih user-friendly
      String errorMsg = e.toString();
      if (errorMsg.contains("TimeoutException")) {
        setState(() {
          prayerError = "Gagal mengunci GPS. Pastikan Anda berada di area terbuka atau aktifkan WiFi/Data.";
          isLoadingPrayer = false;
        });
      } else {
        setState(() {
          prayerError = "Gagal mendapatkan lokasi: $e";
          isLoadingPrayer = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1"
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'DewaVerseApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        
        // FIX: Menggunakan ?? dan toString() untuk null safety
        String city = "";
        String province = "";
        
        if (address != null) {
          city = (address['city'] ?? 
                  address['town'] ?? 
                  address['village'] ?? 
                  address['county'] ?? 
                  address['regency'] ?? 
                  "Kota tidak terdeteksi").toString();
          province = (address['state'] ?? "Provinsi tidak terdeteksi").toString();
        } else {
          city = "Kota tidak terdeteksi";
          province = "Provinsi tidak terdeteksi";
        }
        
        setState(() {
          currentCity = city;
          currentProvince = province;
          currentLocation = "$city, $province";
        });
        
        await _fetchPrayerTimes(currentProvince, currentCity);
      } else {
        await _fetchPrayerTimesByCoordinate(lat, lon);
      }
    } catch (e) {
      await _fetchPrayerTimesByCoordinate(lat, lon);
    }
  }

  Future<void> _fetchPrayerTimesByCoordinate(double lat, double lon) async {
    try {
      final url = Uri.parse(
        "https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=id"
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // FIX: Menggunakan ?? dan toString() untuk null safety
        String city = (data['city'] ?? data['locality'] ?? "Kota tidak terdeteksi").toString();
        String province = (data['principalSubdivision'] ?? "Provinsi tidak terdeteksi").toString();
        
        setState(() {
          currentCity = city;
          currentProvince = province;
          currentLocation = "$city, $province";
        });
        
        await _fetchPrayerTimes(province, city);
      } else {
        setState(() {
          prayerError = "Gagal mendeteksi lokasi. Silakan coba lagi.";
          isLoadingPrayer = false;
        });
      }
    } catch (e) {
      setState(() {
        prayerError = "Error mendeteksi lokasi: ${e.toString()}";
        isLoadingPrayer = false;
      });
    }
  }

  Future<void> _fetchPrayerTimes(String province, String city) async {
    try {
      final now = DateTime.now();
      
      final provincesUrl = Uri.parse("https://equran.id/api/v2/shalat/provinsi");
      final provincesResponse = await http.get(provincesUrl).timeout(const Duration(seconds: 10));
      
      if (provincesResponse.statusCode != 200) {
        throw Exception("Gagal mengambil daftar provinsi");
      }
      
      final provincesData = jsonDecode(provincesResponse.body);
      if (provincesData['code'] != 200) {
        throw Exception(provincesData['message'] ?? "Gagal mengambil daftar provinsi");
      }
      
      // FIX: Cast ke List<String> dan handle null
      List<String> provinceList = [];
      if (provincesData['data'] != null && provincesData['data'] is List) {
        provinceList = (provincesData['data'] as List).map((e) => e.toString()).toList();
      }
      
      String matchedProvince = "";
      for (String p in provinceList) {
        if (p.toLowerCase().contains(province.toLowerCase()) || 
            province.toLowerCase().contains(p.toLowerCase())) {
          matchedProvince = p;
          break;
        }
      }
      
      if (matchedProvince.isEmpty && provinceList.isNotEmpty) {
        matchedProvince = provinceList[0];
      }
      
      if (matchedProvince.isEmpty) {
        throw Exception("Tidak ada provinsi yang ditemukan");
      }
      
      final citiesUrl = Uri.parse("https://equran.id/api/v2/shalat/kabkota");
      final citiesResponse = await http.post(
        citiesUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"provinsi": matchedProvince}),
      ).timeout(const Duration(seconds: 10));
      
      if (citiesResponse.statusCode != 200) {
        throw Exception("Gagal mengambil daftar kabupaten/kota");
      }
      
      final citiesData = jsonDecode(citiesResponse.body);
      if (citiesData['code'] != 200) {
        throw Exception(citiesData['message'] ?? "Gagal mengambil daftar kabupaten/kota");
      }
      
      // FIX: Cast ke List<String> dan handle null
      List<String> cityList = [];
      if (citiesData['data'] != null && citiesData['data'] is List) {
        cityList = (citiesData['data'] as List).map((e) => e.toString()).toList();
      }
      
      String matchedCity = "";
      for (String c in cityList) {
        if (c.toLowerCase().contains(city.toLowerCase()) || 
            city.toLowerCase().contains(c.toLowerCase())) {
          matchedCity = c;
          break;
        }
      }
      
      if (matchedCity.isEmpty && cityList.isNotEmpty) {
        matchedCity = cityList[0];
      }
      
      if (matchedCity.isEmpty) {
        throw Exception("Tidak ada kota yang ditemukan");
      }
      
      final prayerUrl = Uri.parse("https://equran.id/api/v2/shalat");
      final prayerResponse = await http.post(
        prayerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "provinsi": matchedProvince,
          "kabkota": matchedCity,
          "bulan": now.month,
          "tahun": now.year,
        }),
      ).timeout(const Duration(seconds: 15));

      if (prayerResponse.statusCode == 200) {
        final data = jsonDecode(prayerResponse.body);
        
        if (data['code'] == 200) {
          final jadwalList = data['data']['jadwal'] as List?;
          
          if (jadwalList == null) {
            throw Exception("Data jadwal tidak ditemukan");
          }
          
          dynamic todaySchedule;
          for (var item in jadwalList) {
            if (item['tanggal'] == now.day) {
              todaySchedule = item;
              break;
            }
          }
          
          if (todaySchedule != null) {
            setState(() {
              prayerTimes = {
                'subuh': todaySchedule['subuh']?.toString() ?? '--:--',
                'dzuhur': todaySchedule['dzuhur']?.toString() ?? '--:--',
                'ashar': todaySchedule['ashar']?.toString() ?? '--:--',
                'maghrib': todaySchedule['maghrib']?.toString() ?? '--:--',
                'isya': todaySchedule['isya']?.toString() ?? '--:--',
              };
              currentProvince = matchedProvince;
              currentCity = matchedCity;
              currentLocation = "$matchedCity, $matchedProvince";
              isLoadingPrayer = false;
            });
          } else {
            setState(() {
              prayerError = "Jadwal tidak ditemukan untuk hari ini";
              isLoadingPrayer = false;
            });
          }
        } else {
          setState(() {
            prayerError = data['message']?.toString() ?? "Gagal mengambil jadwal sholat";
            isLoadingPrayer = false;
          });
        }
      } else {
        setState(() {
          prayerError = "Gagal terhubung ke server. Periksa koneksi internet Anda.";
          isLoadingPrayer = false;
        });
      }
    } catch (e) {
      setState(() {
        prayerError = "Error: ${e.toString()}";
        isLoadingPrayer = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return months[month - 1];
  }

  Widget _buildPrayerScheduleWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryPurple.withOpacity(0.3),
            primaryPurple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentPurple.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  FontAwesomeIcons.mosque,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jadwal Sholat",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: accentPurple, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentLocation,
                            style: TextStyle(
                              color: accentPurple,
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentPurple.withOpacity(0.3)),
                ),
                child: Text(
                  currentDate,
                  style: TextStyle(
                    color: accentPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (isLoadingPrayer)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFEA80FC),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Mendapatkan jadwal sholat...",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (prayerError != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    prayerError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _getPrayerSchedule,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Coba Lagi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPrayerItem("🌙", "Subuh", prayerTimes['subuh'] ?? '--:--'),
                    _buildPrayerItem("☀️", "Dzuhur", prayerTimes['dzuhur'] ?? '--:--'),
                    _buildPrayerItem("🌅", "Ashar", prayerTimes['ashar'] ?? '--:--'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPrayerItem("🌇", "Maghrib", prayerTimes['maghrib'] ?? '--:--'),
                    _buildPrayerItem("🌙", "Isya", prayerTimes['isya'] ?? '--:--'),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String icon, String name, String time) {
    bool isPast = false;
    try {
      final now = TimeOfDay.now();
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final prayerHour = int.parse(timeParts[0]);
        final prayerMinute = int.parse(timeParts[1]);
        final currentHour = now.hour;
        final currentMinute = now.minute;
        
        if (prayerHour < currentHour || 
            (prayerHour == currentHour && prayerMinute < currentMinute)) {
          isPast = true;
        }
      }
    } catch (e) {
      // Jika parsing gagal, abaikan
    }
    
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            color: accentGrey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPast 
                ? Colors.grey.withOpacity(0.3) 
                : primaryPurple.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: isPast ? null : Border.all(color: accentPurple.withOpacity(0.5)),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: isPast ? accentGrey : accentPurple,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
      ],
    );
  }

  // ==================== FUNGSI LAINNYA (TIDAK BERUBAH) ====================
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  void _initMenuVideo() {
    _menuVideoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {});
        _menuVideoController?.setLooping(true);
        _menuVideoController?.play();
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('http://yogzzpublik-legal.panelyogzzstr.my.id:3325'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            _handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            _handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
      if (data['type'] == 'stats') {
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConnections = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("⚠️ Session Expired", style: TextStyle(color: accentPurple, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: accentGrey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: Text("OK", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          listGroupBug: listGroupBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = InfoPage(
          sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = ToolsPage(
            sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      } else if (index == 4) {
        _selectedPage = ChatPage(
          sessionKey: sessionKey,
          username: username,
        );
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (index == 2) {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
      } else if (index == 4) {
        _selectedPage = VipPage(sessionKey: sessionKey);
      }
    });
    Navigator.pop(context);
  }

  // ==================== BUILD NEWS PAGE (TANPA TOMBOL SUPPORT) ====================
  Widget _buildNewsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardGlass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderGlass, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactInfoItem(
                      icon: Icons.people,
                      label: "Online",
                      value: "$onlineUsers",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactInfoItem(
                      icon: Icons.link,
                      label: "Connections",
                      value: "$activeConnections",
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: 190,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final item = newsList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardGlass,
                    border: Border.all(color: borderGlass),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item['image'] != null && item['image'].toString().isNotEmpty)
                          NewsMedia(url: item['image'].toString()),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                                primaryPurple.withOpacity(0.1),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']?.toString() ?? 'No Title',
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontSize: 16,
                                  fontFamily: "Orbitron",
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: primaryPurple.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc']?.toString() ?? '',
                                style: TextStyle(
                                  color: accentPurple,
                                  fontFamily: "ShareTechMono",
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          _buildPrayerScheduleWidget(),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: cardGlass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderGlass, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.telegram, color: Colors.white, size: 22),
                label: const Text(
                  "Join To Information",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  _openUrl("https://t.me/rikzxMD_real");
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPurple, accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                label: const Text(
                  "MANAGE BUG SENDER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BugSenderPage(
                        sessionKey: sessionKey,
                        username: username,
                        role: role,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 250,
            color: Colors.black,
            child: Stack(
              children: [
                if (_menuVideoController != null && _menuVideoController!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _menuVideoController!.value.size.width,
                        height: _menuVideoController!.value.size.height,
                        child: VideoPlayer(_menuVideoController!),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentPurple,
                              width: 3
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            )
                                : Icon(
                              FontAwesomeIcons.userAstronaut,
                              size: 50,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: accentPurple,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "reseller")
                    _buildDrawerMenuItem(
                      icon: Icons.storefront,
                      label: "Seller Page",
                      onTap: () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildDrawerMenuItem(
                      icon: Icons.admin_panel_settings,
                      label: "Admin Page",
                      onTap: () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildDrawerMenuItem(
                      icon: Icons.workspace_premium,
                      label: "Owner Page",
                      onTap: () => _onSidebarTabSelected(3),
                    ),
                  if (role == "vip")
                    _buildDrawerMenuItem(
                      icon: Icons.star,
                      label: "VIP Page",
                      iconColor: accentPurple,
                      textColor: accentPurple,
                      onTap: () => _onSidebarTabSelected(4),
                    ),
                  _buildDrawerMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPage(
                            sessionKey: sessionKey,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerMenuItem(
                    icon: Icons.logout,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
    Color? iconColor,
    Color? textColor,
  }) {
    final Color finalIconColor = iconColor ?? (isLogout ? Colors.redAccent : accentPurple);
    final Color finalTextColor = textColor ?? (isLogout ? Colors.redAccent : primaryWhite);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLogout
            ? Colors.red.withOpacity(0.2)
            : cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout 
            ? Colors.red.withOpacity(0.5) 
            : borderGlass,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: finalIconColor,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: finalTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: finalIconColor.withOpacity(0.5),
          size: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Hai, $username",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: primaryPurple.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              Icons.headset_mic_outlined, 
              color: accentPurple,
            ),
            tooltip: 'Customer Service',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ContactPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              FontAwesomeIcons.userCircle, 
              color: accentPurple,
            ),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    username: username,
                    password: password,
                    role: role,
                    expiredDate: expiredDate,
                    sessionKey: sessionKey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildCustomDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              primaryPurple.withOpacity(0.1),
              bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(opacity: _animation, child: _selectedPage),
        ),
      ),
      // ==================== BOTTOM NAVIGATION BAR DENGAN EFEK LONJONG ====================
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              color: cardGlass,
              border: Border(
                top: BorderSide(color: borderGlass),
                bottom: BorderSide(color: borderGlass),
                left: BorderSide(color: borderGlass),
                right: BorderSide(color: borderGlass),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              selectedItemColor: accentPurple,
              unselectedItemColor: accentGrey,
              currentIndex: _bottomNavIndex,
              onTap: _onBottomNavTapped,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home), 
                  label: "Home"
                ),
                BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.whatsapp), 
                  label: "WhatsApp"
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none), 
                  label: "Info"
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.build_circle_outlined), 
                  label: "Tools"
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline), 
                  label: "Chat Public"
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _menuVideoController?.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFEA80FC),
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.error, color: Color(0xFFEA80FC)),
        ),
      );
    }
  }
}