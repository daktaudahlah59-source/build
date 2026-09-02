import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';
import '.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  // ── TEMA HIJAU-BIRU MENYALA ─────────────────────────────────────────────
  static const Color bgDark = Color(0xFF060A0F);
  static const Color bgSecondary = Color(0xFF0A1620);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color primaryWhite = Colors.white;
  static const Color grayText = Colors.white70;
  static const Color cardGlass = Color(0xFF0A1620);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    )..addListener(() {
        if (_animationController.isCompleted) {
          _animationController.repeat(reverse: true);
        }
      });

    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> initLogin() async {
    try {
      androidId = await getAndroidId();

      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString("username");
      final savedPass = prefs.getString("password");
      final savedKey = prefs.getString("key");

      if (savedUser != null && savedPass != null && savedKey != null) {
        final uri = Uri.parse(
            "$BaseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");

        try {
          final res = await http.get(uri);
          final data = jsonDecode(res.body);

          if (data['valid'] == true && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SplashScreen(
                  username: savedUser,
                  password: savedPass,
                  role: data['role'],
                  sessionKey: data['key'],
                  expiredDate: data['expiredDate'],
                  listBug: (data['listBug'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  listDoos: (data['listDDoS'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  news: (data['news'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                ),
              ),
            );
          }
        } catch (_) {
          // Silent error, biarkan user login manual
        }
      }
    } catch (e) {
      print('Error in initLogin: $e');
    }
  }

  Future<String> getAndroidId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      return android.id ?? "unknown_device";
    } catch (e) {
      return "unknown_device";
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showPopup(
        title: "⚠️ Invalid Input",
        message: "Username dan password tidak boleh kosong!",
        color: neonBlue,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$BaseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      ).timeout(const Duration(seconds: 30));

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();

        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "⚠️ Active Session",
            message:
                "Akun ini sedang login di perangkat lain.\nSilakan logout terlebih dahulu.",
            color: Colors.orangeAccent,
          );
        } else {
          _showPopup(
            title: "❌ Login Failed",
            message: "Username atau password salah.",
            color: neonBlue,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", username);
        await prefs.setString("password", password);
        await prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: username,
                password: password,
                role: validData['role'],
                sessionKey: validData['key'],
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Gagal terhubung ke server.\nPeriksa koneksi internet Anda.",
        color: neonBlue,
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = neonBlue,
    bool showContact = false,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Orbitron',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: grayText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          if (showContact)
            Container(
              decoration: BoxDecoration(
                gradient: neonGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () async {
                  try {
                    await launchUrl(
                      Uri.parse("https://t.me/abityzreall"),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    // Silent error
                  }
                },
                child: Text(
                  "Contact Admin",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: cardGlass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: neonBlue.withOpacity(0.3)),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(
                  color: neonBlue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              const Color(0xFF0A1620),
              const Color(0xFF061020),
              bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── SCROLLABLE CONTENT ──
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── LOGO dengan efek glow ──
                          AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (context, child) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      neonBlue.withOpacity(0.1 + _glowAnim.value * 0.15),
                                      neonGreen.withOpacity(0.05 + _glowAnim.value * 0.05),
                                      Colors.transparent,
                                    ],
                                    radius: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: neonBlue.withOpacity(0.2 + _glowAnim.value * 0.3),
                                      blurRadius: 50,
                                      spreadRadius: 15,
                                    ),
                                    BoxShadow(
                                      color: neonGreen.withOpacity(0.1 + _glowAnim.value * 0.1),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ScaleTransition(
                                  scale: _pulseAnim,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          neonBlue.withOpacity(0.2),
                                          neonGreen.withOpacity(0.1),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: neonBlue.withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: neonBlue.withOpacity(0.3),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/reze.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF0A1620),
                                            child: Icon(
                                              Icons.person,
                                              color: neonBlue,
                                              size: 50,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── JUDUL ──
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF39FF14)],
                            ).createShader(bounds),
                            child: Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: neonBlue.withOpacity(0.4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  neonBlue.withOpacity(0.15),
                                  neonGreen.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: neonBlue.withOpacity(0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              "VipX",
                              style: TextStyle(
                                color: neonBlue.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── FORM INPUT ──
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInput(
                                  userController,
                                  "USERNAME",
                                  Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  passController,
                                  "PASSWORD",
                                  Icons.lock_outline_rounded,
                                  true,
                                ),
                                const SizedBox(height: 24),

                                // ── "Buy Access" Link ──
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have access? ",
                                      style: TextStyle(
                                        color: grayText,
                                        fontSize: 13,
                                        fontFamily: 'ShareTechMono',
                                      ),
                                      children: [
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap: () async {
                                              try {
                                                await launchUrl(
                                                  Uri.parse("https://t.me/abityzreall"),
                                                  mode: LaunchMode.externalApplication,
                                                );
                                              } catch (e) {
                                                // Silent error
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: neonGradient,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: neonBlue.withOpacity(0.2),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                "BUY HERE",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Orbitron',
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── TOMBOL SIGN IN ──
                                _buildButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── FOOTER ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: neonBlue.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    "© VipX • V1.0",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: neonBlue.withOpacity(0.3),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool isPassword = false,
  ]) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardGlass,
            const Color(0xFF0D1A2B).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'ShareTechMono',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: neonBlue.withOpacity(0.6),
            fontSize: 11,
            fontFamily: 'Orbitron',
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(
            icon,
            color: neonBlue,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: neonBlue.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          errorStyle: TextStyle(
            color: neonBlue,
            fontFamily: 'Orbitron',
            fontSize: 10,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$label tidak boleh kosong";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildButton() {
    final double fullButtonWidth = MediaQuery.of(context).size.width - 48;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isLoading ? 60 : fullButtonWidth,
      height: 58,
      decoration: BoxDecoration(
        gradient: neonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: neonGreen.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : login,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    "SIGN IN",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}