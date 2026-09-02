// splash.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  bool _fadeOutStarted = false;

  // Tema Merah CERAH (bukan gelap)
  final Color redBright = const Color(0xFF616161);  // merah cerah
  final Color redLight = const Color(0xFF757575);   // merah lebih terang
  final Color redGlow = const Color(0x66757575);    // glow merah terang

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(false);
        _videoController.play();

        _fadeController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );

        _videoController.addListener(() {
          final position = _videoController.value.position;
          final duration = _videoController.value.duration;

          if (duration != null &&
              position >= duration - const Duration(seconds: 1) &&
              !_fadeOutStarted) {
            _fadeOutStarted = true;
            _fadeController.forward();
          }

          if (position >= duration) {
            _navigateToDashboard();
          }
        });
      });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
          news: widget.news,
        ),
      ),
    );
  }

  void _skipSplash() {
    _videoController.pause();
    _navigateToDashboard();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- VIDEO BACKGROUND FULL SCREEN ---
          if (_videoController.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF616161)),
              ),
            ),

          // --- TOMBOL SKIP DI POJOK KANAN ATAS ---
          Positioned(
            top: 50,
            right: 16,
            child: GestureDetector(
              onTap: _skipSplash,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: redBright.withOpacity(0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: redBright.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "SKIP",
                      style: TextStyle(
                        color: redLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- TEKS DENGAN TULISAN KECIL DI ATAS (warna merah cerah) ---
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Selamat datang di Apps ATOMIC",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: redLight.withOpacity(0.9),
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(1, 1),
                        ),
                        Shadow(
                          color: redBright.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  "ATOMIC",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: redBright,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: redGlow,
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: redLight.withOpacity(0.8),
                        blurRadius: 15,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- FADE OUT OVERLAY ---
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController.drive(Tween(begin: 1.0, end: 0.0)),
              child: Container(color: Colors.black),
            ),
        ],
      ),
    );
  }
}