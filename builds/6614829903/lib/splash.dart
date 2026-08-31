import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  // ── Video Player ─────────────────────────────────────────────────────────
  late VideoPlayerController _videoController;
  late AnimationController _fadeInController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _fadeInAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  bool _canSkip = false;
  bool _isVideoInitialized = false;

  // ── TEMA WARNA HIJAU-BIRU MENYALA ──────────────────────────────────────
  final Color neonBlue = const Color(0xFF00D4FF);
  final Color neonGreen = const Color(0xFF39FF14);
  final Color bgDark = const Color(0xFF060A0F);

  @override
  void initState() {
    super.initState();

    // Sembunyikan status bar untuk full immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inisialisasi video player dengan error handling
    try {
      _videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.setVolume(0.5);
            _videoController.play();
          }
        }).catchError((error) {
          print('Error loading splash video: $error');
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
            });
          }
        });
    } catch (e) {
      print('Error initializing video: $e');
      _isVideoInitialized = false;
    }

    // Fade-in semua elemen
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeInAnim = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );
    _fadeInController.forward();

    // Pulse logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Izinkan skip setelah 1.5 detik
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _canSkip = true);
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    } catch (e) {
      print('Error navigating to dashboard: $e');
    }
  }

  @override
  void dispose() {
    try {
      _videoController.dispose();
    } catch (e) {
      print('Error disposing video: $e');
    }
    _fadeInController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // ── 1. Background dengan gradient ───────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgDark,
                  const Color(0xFF0A1620),
                  const Color(0xFF061020),
                ],
              ),
            ),
          ),

          // ── 2. Background Video ──────────────────────────────────────────
          if (_isVideoInitialized)
            Positioned.fill(
              child: VideoPlayer(_videoController),
            ),

          // ── 3. Animated Gradient Overlay ─────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.5 + _glowAnim.value * 0.2),
                        Colors.black.withOpacity(0.3 + _glowAnim.value * 0.1),
                        const Color(0xFF00D4FF).withOpacity(_glowAnim.value * 0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── 4. Tombol SKIP di kanan atas ────────────────────────────────
          Positioned(
            top: 50,
            right: 24,
            child: FadeTransition(
              opacity: _fadeInAnim,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _canSkip ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: _canSkip ? _navigateToDashboard : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          neonBlue.withOpacity(0.2),
                          neonGreen.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: neonGreen.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.skip_next_rounded,
                          color: neonBlue.withOpacity(0.9),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "SKIP",
                          style: TextStyle(
                            color: neonBlue.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: neonBlue.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Konten utama ──────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeInAnim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo dengan efek glow
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, child) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                neonBlue.withOpacity(0.3 + _glowAnim.value * 0.2),
                                neonGreen.withOpacity(0.2 + _glowAnim.value * 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.4 + _glowAnim.value * 0.3),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: neonGreen.withOpacity(0.2 + _glowAnim.value * 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/logo.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Judul dengan gradient dan glow
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
                    ).createShader(bounds),
                    child: Text(
                      "VipX",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: neonBlue.withOpacity(0.8),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: neonGreen.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          neonBlue.withOpacity(0.15),
                          neonGreen.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "SECURE • STABLE • POWERFUL",
                      style: TextStyle(
                        color: neonBlue.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron',
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Deskripsi ─────────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A1620).withOpacity(0.9),
                          const Color(0xFF0D1A2B).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "VipX",
                          style: TextStyle(
                            color: neonGreen.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "VipX project•Zeiby",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: neonBlue.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.7,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── Loading indicator ─────────────────────────────────────
                  if (!_canSkip)
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: neonGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: neonBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: neonBlue.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: neonGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 6. Loading bar di bawah ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        neonBlue.withOpacity(0.3 + _glowAnim.value * 0.3),
                        neonGreen.withOpacity(0.3 + _glowAnim.value * 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}