import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

import 'admin_page.dart';
import 'owner_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'login_page.dart';
import 'device_dashboard.dart';
import 'public_chat_page.dart';
import 'spotify_music_player.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
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
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  // --- Fitur Profil & Menu ---
  String androidId = "unknown";
  File? _profileImage;
  VideoPlayerController? _menuVideoController;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int offlineUsers = 0;
  int totalDevices = 0;

  // --- Jadwal Sholat ---
  Map<String, dynamic>? _prayerTimes;
  bool _isLoadingPrayer = true;
  String _currentTime = '';
  String _currentDate = '';
  String _nextPrayer = '--';
  String _nextPrayerTime = '--:--';
  List<Map<String, String>> _allPrayerTimes = [];

  // --- TEMA WARNA HIJAU-BIRU MENYALA ---
  static const Color bgDark = Color(0xFF060A0F);
  static const Color primaryBlue = Color(0xFF00D4FF);
  static const Color primaryGreen = Color(0xFF00FF88);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00BFFF);
  static const Color cardGlass = Color(0xFF0A1620);
  static const Color borderGlass = Color(0xFF1A3A4A);
  static const Color primaryWhite = Colors.white;
  static const Color accentGrey = Colors.grey;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _selectedPage = _buildDashboardPage();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    _initMenuVideo();
    _fetchPrayerTimes();
    _startClock();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_$username');
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _profileImage = file;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  void _initMenuVideo() {
    try {
      _menuVideoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _menuVideoController?.setLooping(true);
            _menuVideoController?.play();
          }
        }).catchError((error) {
          print('Error loading video: $error');
        });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      androidId = deviceInfo.id;
      _connectToWebSocket();
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('http://elainakurumipanelpanel.xtxintax.my.id:2333')
      );
      
      channel.sink.add(jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }));
      channel.sink.add(jsonEncode({"type": "stats"}));

      channel.stream.listen(
        (event) {
          try {
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
              if (mounted) {
                setState(() {
                  onlineUsers = data['onlineUsers'] ?? 0;
                  offlineUsers = data['offlineUsers'] ?? 0;
                  totalDevices = data['totalDevices'] ?? 0;
                });
              }
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
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
        title: Text("⚠️ Session Expired", style: TextStyle(color: neonBlue, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: accentGrey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: Text("OK", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildDashboardPage();
      } else if (index == 1) {
        _selectedPage = DeviceDashboardPage(
          sessionKey: widget.sessionKey,
          username: widget.username,
          role: widget.role,
        );
      } else if (index == 2) {
        _selectedPage = PublicChatPage(
          username: widget.username,
          sessionKey: widget.sessionKey,
          role: widget.role,
        );
      } else if (index == 3) {
        _selectedPage = SpotifyMusicPlayer(
          sessionKey: widget.sessionKey,
          username: widget.username, 
        );
      }
    });
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // ==================== JADWAL SHOLAT ====================
  Future<void> _fetchPrayerTimes() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Jakarta&country=Indonesia&method=2'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          final timings = data['data']['timings'] as Map<String, dynamic>;
          
          // Ambil semua waktu sholat
          final prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
          List<Map<String, String>> tempList = [];
          
          for (var name in prayerNames) {
            if (timings.containsKey(name)) {
              String timeStr = timings[name].toString().split(' ')[0];
              tempList.add({
                'name': name,
                'time': timeStr,
              });
            }
          }
          
          setState(() {
            _prayerTimes = timings;
            _allPrayerTimes = tempList;
            _isLoadingPrayer = false;
            _updateNextPrayer();
          });
        }
      } else {
        setState(() {
          _isLoadingPrayer = false;
        });
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
      setState(() {
        _isLoadingPrayer = false;
      });
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    String next = '--';
    String nextTime = '--:--';
    
    for (var prayer in prayers) {
      if (_prayerTimes!.containsKey(prayer)) {
        final timeStr = _prayerTimes![prayer] as String;
        final time = timeStr.split(' ')[0];
        
        if (time.compareTo(currentTime) > 0) {
          next = prayer;
          nextTime = time;
          break;
        }
      }
    }
    
    // Jika tidak ada jadwal selanjutnya, set ke Fajr besok
    if (next == '--' && _prayerTimes!.containsKey('Fajr')) {
      next = 'Fajr';
      nextTime = _prayerTimes!['Fajr'].toString().split(' ')[0];
    }
    
    setState(() {
      _nextPrayer = next;
      _nextPrayerTime = nextTime;
    });
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          _currentDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        });
        _updateNextPrayer();
        _startClock();
      }
    });
  }

  // ==================== WIDGET BUILD ====================
  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===== JAM DIGITAL (KIRI) & JADWAL SHOLAT (KANAN) =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  const Color(0xFF0A1620),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: neonBlue.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Jam Digital - KIRI
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTime.isEmpty ? '--:--' : _currentTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                          shadows: [
                            Shadow(
                              color: Color(0xFF00D4FF),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentDate.isEmpty ? '--/--/----' : _currentDate,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Jadwal Sholat - KANAN
                Expanded(
                  flex: 3,
                  child: _isLoadingPrayer
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF39FF14),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [neonGreen.withOpacity(0.2), neonBlue.withOpacity(0.2)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: neonGreen.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '🕌 $_nextPrayer',
                                    style: TextStyle(
                                      color: neonGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nextPrayerTime,
                              style: TextStyle(
                                color: neonBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                                shadows: [
                                  Shadow(
                                    color: neonBlue.withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Next Prayer',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 9,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ===== STATISTIK USER ONLINE & OFFLINE =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // USER ONLINE - KIRI (HIJAU MENYALA)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "ONLINE",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                "$onlineUsers",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${onlineUsers > 0 ? onlineUsers : 0}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Active Devices",
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.6),
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // USER OFFLINE - KANAN (MERAH MENYALA)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.red.withOpacity(0.15),
                          Colors.red.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "OFFLINE",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                "$offlineUsers",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${offlineUsers > 0 ? offlineUsers : 0}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Offline Devices",
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.6),
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== TOTAL DEVICES =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    neonBlue.withOpacity(0.15),
                    neonGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: neonBlue.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: neonBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "TOTAL DEVICES",
                            style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$totalDevices",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [neonBlue, neonGreen],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.devices,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ===== MENU GRID =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                // Change Password
                _buildMenuCard(
                  icon: Icons.lock_outline,
                  label: "Change\nPassword",
                  color: neonBlue,
                  onTap: () => _navigateToPage(
                    ChangePasswordPage(
                      username: username,
                      sessionKey: sessionKey,
                    ),
                  ),
                ),
                // Admin Panel
                if (role == "admin" || role == "owner")
                  _buildMenuCard(
                    icon: Icons.admin_panel_settings,
                    label: "Admin\nPanel",
                    color: Colors.orangeAccent,
                    onTap: () => _navigateToPage(
                      AdminPage(sessionKey: sessionKey),
                    ),
                  ),
                // Owner Panel
                if (role == "owner")
                  _buildMenuCard(
                    icon: Icons.workspace_premium,
                    label: "Owner\nPanel",
                    color: Colors.purpleAccent,
                    onTap: () => _navigateToPage(
                      OwnerPage(sessionKey: sessionKey, username: username),
                    ),
                  ),
                // Seller Panel
                if (role == "reseller")
                  _buildMenuCard(
                    icon: Icons.storefront,
                    label: "Seller\nPanel",
                    color: Colors.lightGreenAccent,
                    onTap: () => _navigateToPage(
                      SellerPage(keyToken: sessionKey),
                    ),
                  ),
                // News
                _buildMenuCard(
                  icon: Icons.newspaper,
                  label: "News\nFeed",
                  color: neonGreen,
                  onTap: () {
                    setState(() {
                      _selectedPage = _buildNewsPage();
                      _bottomNavIndex = 0;
                    });
                  },
                ),
                // Music Player
                _buildMenuCard(
                  icon: Icons.music_note,
                  label: "Music\nPlayer",
                  color: Colors.pinkAccent,
                  onTap: () => _navigateToPage(
                    SpotifyMusicPlayer(
                      sessionKey: widget.sessionKey,
                      username: widget.username,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== NEWS SECTION (Preview) =====
          Container(
            width: double.infinity,
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: newsList.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A1620),
                          const Color(0xFF0D1A2B),
                        ],
                      ),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "No News Available",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    itemCount: newsList.length > 3 ? 3 : newsList.length,
                    itemBuilder: (context, index) {
                      final item = newsList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0A1620),
                              const Color(0xFF0D1A2B),
                            ],
                          ),
                          border: Border.all(
                            color: neonBlue.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonBlue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (item['image'] != null && item['image'].toString().isNotEmpty)
                                NewsMedia(url: item['image']),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                      neonBlue.withOpacity(0.1),
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
                                      item['title'] ?? 'No Title',
                                      style: TextStyle(
                                        color: primaryWhite,
                                        fontSize: 14,
                                        fontFamily: "Orbitron",
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: neonBlue.withOpacity(0.8),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] ?? '',
                                      style: TextStyle(
                                        color: neonBlue,
                                        fontFamily: "ShareTechMono",
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Orbitron',
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 400,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: newsList.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A1620),
                          const Color(0xFF0D1A2B),
                        ],
                      ),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "No News Available",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final item = newsList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0A1620),
                              const Color(0xFF0D1A2B),
                            ],
                          ),
                          border: Border.all(
                            color: neonBlue.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonBlue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (item['image'] != null && item['image'].toString().isNotEmpty)
                                NewsMedia(url: item['image']),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                      neonBlue.withOpacity(0.1),
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
                                      item['title'] ?? 'No Title',
                                      style: TextStyle(
                                        color: primaryWhite,
                                        fontSize: 18,
                                        fontFamily: "Orbitron",
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: neonBlue.withOpacity(0.8),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['desc'] ?? '',
                                      style: TextStyle(
                                        color: neonBlue,
                                        fontFamily: "ShareTechMono",
                                        fontSize: 14,
                                      ),
                                      maxLines: 3,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== DRAWER MENU ====================
  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER dengan foto profil di ATAS
          Container(
            height: 200,
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
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Foto Profil - DI ATAS
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [neonBlue, neonGreen],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
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
                                    size: 40,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            shadows: [
                              Shadow(
                                color: Color(0xFF00D4FF),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [neonBlue, neonGreen],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MENU LIST - DI BAWAH FOTO
          Expanded(
            child: Container(
              color: bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  // Change Password
                  _buildDrawerMenuItem(
                    icon: Icons.lock_outline,
                    label: "Change Password",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(
                        ChangePasswordPage(
                          username: username,
                          sessionKey: sessionKey,
                        ),
                      );
                    },
                  ),
                  
                  // Admin Panel
                  if (role == "admin" || role == "owner")
                    _buildDrawerMenuItem(
                      icon: Icons.admin_panel_settings,
                      label: "Admin Panel",
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(AdminPage(sessionKey: sessionKey));
                      },
                    ),
                    
                  // Owner Panel
                  if (role == "owner")
                    _buildDrawerMenuItem(
                      icon: Icons.workspace_premium,
                      label: "Owner Panel",
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(OwnerPage(sessionKey: sessionKey, username: username));
                      },
                    ),
                    
                  // Seller Panel
                  if (role == "reseller")
                    _buildDrawerMenuItem(
                      icon: Icons.storefront,
                      label: "Seller Panel",
                      color: Colors.lightGreenAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPage(SellerPage(keyToken: sessionKey));
                      },
                    ),
                    
                  // News Feed
                  _buildDrawerMenuItem(
                    icon: Icons.newspaper,
                    label: "News Feed",
                    color: Colors.greenAccent,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = _buildNewsPage();
                        _bottomNavIndex = 0;
                      });
                    },
                  ),

                  // Music Player
                  _buildDrawerMenuItem(
                    icon: Icons.music_note,
                    label: "Music Player",
                    color: Colors.pinkAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(
                        SpotifyMusicPlayer(
                          sessionKey: widget.sessionKey,
                          username: widget.username,
                        ),
                      );
                    },
                  ),

                  // Device Dashboard
                  _buildDrawerMenuItem(
                    icon: Icons.devices,
                    label: "Device Dashboard",
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(
                        DeviceDashboardPage(
                          sessionKey: widget.sessionKey,
                          username: widget.username,
                          role: widget.role,
                        ),
                      );
                    },
                  ),

                  // Public Chat
                  _buildDrawerMenuItem(
                    icon: Icons.public,
                    label: "Public Chat",
                    color: Colors.deepPurpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(
                        PublicChatPage(
                          username: widget.username,
                          sessionKey: widget.sessionKey,
                          role: widget.role,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  // ===== SEPARATOR =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.15),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== LOG OUT =====
                  _buildDrawerMenuItem(
                    icon: Icons.logout,
                    label: "Log Out",
                    color: Colors.redAccent,
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
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: BoxDecoration(
        color: isLogout 
            ? Colors.red.withOpacity(0.05) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : color,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isLogout 
              ? Colors.red.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2),
          size: 12,
        ),
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
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
          ).createShader(bounds),
          child: const Text(
            "VipX",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
              shadows: [
                Shadow(color: Color(0xFF00D4FF), blurRadius: 12),
                Shadow(color: Color(0xFF39FF14), blurRadius: 24),
              ],
            ),
          ),
        ),
        backgroundColor: const Color(0xFF060A0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00D4FF), size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF00D4FF)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF00D4FF), Color(0xFF39FF14), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildCustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060A0F),
              Color(0xFF0A1620),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(opacity: _animation, child: _selectedPage),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF060A0F),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A1620),
                const Color(0xFF0D1A2B),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: neonBlue.withOpacity(0.35),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: neonBlue.withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              final icons = [
                Icons.dashboard_rounded,
                Icons.devices,
                Icons.public_rounded,
                Icons.music_note
              ];
              final labels = ["Dashboard", "Device", "Chat", "Music"];
              final isActive = _bottomNavIndex == index;
              return GestureDetector(
                onTap: () => _onBottomNavTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 18 : 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              neonBlue.withOpacity(0.15),
                              neonGreen.withOpacity(0.05),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: isActive
                        ? Border.all(
                            color: neonBlue.withOpacity(0.6),
                            width: 0.8,
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: neonBlue.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        color: isActive ? neonBlue : Colors.grey.shade600,
                        size: 24,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: neonBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: neonBlue.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      channel.sink.close(status.goingAway);
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
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
      try {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _controller?.setLooping(true);
              _controller?.setVolume(0.0);
              _controller?.play();
            }
          }).catchError((error) {
            print('Error loading news video: $error');
          });
      } catch (e) {
        print('Error initializing video: $e');
      }
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
            color: Color(0xFF39FF14),
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.error, color: Color(0xFF39FF14)),
        ),
      );
    }
  }
}