// dashboard_page.dart
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
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
import 'ucapan_page.dart';
import 'toko_page.dart';
import 'public_chat_page.dart';
import 'weather_page.dart';
import 'jadwal_sholat_page.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late WebSocketChannel? _channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File? _profileImage;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const SizedBox();

  int onlineUsers = 0;
  int activeConnections = 0;

  Timer? _statsTimer;
  Timer? _onlineTimer;

  // === TEMA UNGU MODERN ===
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);
  
  Color get glassPrimary => const Color(0x1ABB86FC);
  Color get glassSecondary => const Color(0x0DBB86FC);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)], // Gradien ungu elegan
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => const LinearGradient(
        colors: [Color(0xFF2A004E), Color(0xFF45006A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

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

    _initAnimations();
    _selectedPage = _buildHomePage();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    _startStatsTimer();
    
    _fetchOnlineUsers();
    _startOnlinePolling();
  }

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_channel != null) {
        _channel?.sink.add(jsonEncode({"type": "stats"}));
      }
    });
  }

  Future<void> _fetchOnlineUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/getOnlineUsers?key=$sessionKey'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            onlineUsers = data['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching online users: $e');
    }
  }

  void _startOnlinePolling() {
    _onlineTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOnlineUsers();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('$apiBaseUrl'));
    _channel?.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    _channel?.sink.add(jsonEncode({"type": "stats"}));

    _channel?.stream.listen((event) {
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
        if (!mounted) return;
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
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryWhite.withOpacity(0.1), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Session Expired",
              style: TextStyle(
                color: accentPurple,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: softGrey, fontSize: 14),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildHomePage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = InfoPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
        );
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (index == 1) {
          _selectedPage = SellerPage(keyToken: sessionKey);
        } else if (index == 2) {
          _selectedPage = AdminPage(sessionKey: sessionKey);
        } else if (index == 3) {
          _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
        }
      });
    });
  }

  // ===================== HOME PAGE =====================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentPurple.withOpacity(0.1),
                  darkPurple.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: 'Orbitron',
                    ),
                    children: [
                      const TextSpan(
                        text: "Welcome Back, ",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      TextSpan(
                        text: username,
                        style: const TextStyle(
                          color: accentPurple, // Warna ungu untuk username
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: secondaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: primaryWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernStatsCard(
                    icon: Icons.people_rounded,
                    label: "Online Users",
                    value: "$onlineUsers",
                    color: accentPurple, // Ungu
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernStatsCard(
                    icon: Icons.link_rounded,
                    label: "Active Connections",
                    value: "$activeConnections",
                    color: softPurple, // Ungu lembut
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Expiration Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentPurple.withOpacity(0.15),
                      darkPurple.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accentPurple.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: purpleGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: primaryWhite,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Expiration Date",
                            style: TextStyle(color: softGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            expiredDate,
                            style: const TextStyle(
                              color: primaryWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: purpleGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        "ACTIVE",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // News Section
          if (newsList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: purpleGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "BERITA TERBARU",
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${newsList.length} Artikel",
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  final item = newsList[index];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildNewsCard(item, index),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: purpleGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "QUICK ACTIONS",
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _buildModernQuickAction(
                  icon: FontAwesomeIcons.telegram,
                  label: "Info Channel",
                  color: const Color(0xFF0088cc),
                  onTap: () => _openUrl("https://t.me/renzzxxofficial"),
                ),
                _buildModernQuickAction(
                  icon: Icons.wifi_tethering_rounded,
                  label: "Bug Sender",
                  color: accentPurple, // Ungu
                  onTap: () {
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
                _buildModernQuickAction(
                  icon: Icons.card_giftcard_rounded,
                  label: "Ucapan",
                  color: const Color(0xFFFFC107), // Kuning
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UcapanPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
                _buildModernQuickAction(
                  icon: Icons.shopping_bag_rounded,
                  label: "Toko",
                  color: const Color(0xFF00695C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TokoPage(),
                      ),
                    );
                  },
                ),
                _buildModernQuickAction(
                  icon: Icons.public_rounded,
                  label: "Public Chat",
                  color: const Color(0xFFE91E63), // Pink
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PublicChatPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
                _buildModernQuickAction(
                  icon: Icons.history_rounded,
                  label: "Riwayat",
                  color: const Color(0xFF9C27B0), // Ungu gelap
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiwayatPage(
                          sessionKey: sessionKey,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
                _buildModernQuickAction(
                  icon: Icons.wb_sunny_rounded,
                  label: "Cek Cuaca",
                  color: const Color(0xFF03A9F4), // Biru cerah
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeatherPage(
                          sessionKey: sessionKey,
                          username: username,
                        ),
                      ),
                    );
                  },
                ),
                _buildModernQuickAction(
                  icon: Icons.mosque_rounded,
                  label: "Jadwal Sholat",
                  color: const Color(0xFF4CAF50), // Hijau
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JadwalSholatPage(
                          sessionKey: sessionKey,
                          username: username,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===================== NEWS CARD =====================
  Widget _buildNewsCard(dynamic item, int index) {
    if (item == null) return const SizedBox();
    
    return GestureDetector(
      onTap: () {
        // Optional: Navigate to news detail page
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [glassPrimary, glassSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: primaryWhite.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (item['image'] != null && item['image'].toString().isNotEmpty)
                      Image.network(
                        item['image'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: darkPurple.withOpacity(0.5),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: primaryWhite,
                              size: 40,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: darkPurple.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: accentPurple,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: darkPurple.withOpacity(0.5),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: primaryWhite,
                            size: 40,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "NEWS ${index + 1}",
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'No Title',
                      style: const TextStyle(
                        color: primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['desc'] ?? '',
                      style: TextStyle(
                        color: primaryWhite.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: accentPurple,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item['created_at']),
                          style: TextStyle(
                            color: softGrey,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentPurple.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            "Baca",
                            style: TextStyle(
                              color: accentPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Baru saja";
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return "${diff.inDays} hari lalu";
      } else if (diff.inHours > 0) {
        return "${diff.inHours} jam lalu";
      } else if (diff.inMinutes > 0) {
        return "${diff.inMinutes} menit lalu";
      } else {
        return "Baru saja";
      }
    } catch (e) {
      return dateString;
    }
  }

  // ===================== MODERN STATS CARD =====================
  Widget _buildModernStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [glassPrimary, glassSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryWhite.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primaryWhite, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MODERN QUICK ACTION =====================
  Widget _buildModernQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [glassPrimary, glassSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== DRAWER =====================
  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(gradient: purpleGradient),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryWhite, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: secondaryGradient,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 45,
                                  color: primaryWhite.withOpacity(0.9),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        color: primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryWhite.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: primaryWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "reseller")
                    _buildGlassMenuItem(
                      icon: Icons.storefront_rounded,
                      label: "Seller Page",
                      onTap: () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildGlassMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Admin Page",
                      onTap: () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildGlassMenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: "Owner Page",
                      onTap: () => _onSidebarTabSelected(3),
                    ),
                  _buildGlassMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RiwayatPage(sessionKey: sessionKey, role: role),
                        ),
                      );
                    },
                  ),
                  _buildGlassMenuItem(
                    icon: Icons.send_rounded,
                    label: "Manage Sender",
                    onTap: () {
                      Navigator.pop(context);
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
                  _buildGlassMenuItem(
                    icon: Icons.shopping_bag_rounded,
                    label: "Toko",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TokoPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    color: Colors.white10,
                    height: 32,
                    thickness: 0.5,
                  ),
                  _buildGlassMenuItem(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
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

  Widget _buildGlassMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout ? Colors.grey.withOpacity(0.1) : glassSecondary,
        borderRadius: BorderRadius.circular(16),
        border: isLogout
            ? null
            : Border.all(color: primaryWhite.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.grey.withOpacity(0.15)
                : accentPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.white70 : accentPurple,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.white70 : primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        trailing: isLogout
            ? null
            : Icon(Icons.chevron_right_rounded, color: softGrey, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: purpleGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "ATOMIC",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryWhite),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.headset_mic_rounded,
                color: accentPurple,
                size: 20,
              ),
              tooltip: 'Customer Service',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: Icon(
                FontAwesomeIcons.circleUser,
                color: accentPurple,
                size: 20,
              ),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
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
          ),
        ],
      ),
      drawer: _buildCustomDrawer(),
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
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _selectedPage,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: glassPrimary,
          border: Border(
            top: BorderSide(color: primaryWhite.withOpacity(0.08)),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: accentPurple,
          unselectedItemColor: softGrey,
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.whatsapp),
              label: "WhatsApp",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_rounded),
              label: "Info",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_rounded),
              label: "Tools",
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _onlineTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _animationController.dispose();
    super.dispose();
  }
}

// ===================== GRID PAINTER =====================
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}