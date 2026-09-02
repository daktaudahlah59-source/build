import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // ── TEMA HIJAU-BIRU MENYALA ─────────────────────────────────────────────
  final Color bgDark = const Color(0xFF060A0F);
  final Color bgSecondary = const Color(0xFF0A1620);
  final Color neonBlue = const Color(0xFF00D4FF);
  final Color neonGreen = const Color(0xFF39FF14);
  final Color accentCyan = const Color(0xFF00E5FF);
  final Color primaryWhite = Colors.white;
  final Color glassBorder = Colors.white.withOpacity(0.1);
  final Color cardBg = const Color(0xFF0A1620).withOpacity(0.5);

  final LinearGradient neonGradient = const LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: const Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    )..addListener(() {
        if (_animationController.isCompleted) {
          _animationController.repeat(reverse: true);
        }
      });

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception("Could not launch $uri");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: neonBlue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
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
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),

                    // ── ANIMATED GLOW ORB ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                neonBlue.withOpacity(0.1 + _glowAnimation.value * 0.1),
                                neonGreen.withOpacity(0.05 + _glowAnimation.value * 0.05),
                                Colors.transparent,
                              ],
                              radius: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.2 + _glowAnimation.value * 0.2),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                              BoxShadow(
                                color: neonGreen.withOpacity(0.1 + _glowAnimation.value * 0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    neonBlue.withOpacity(0.3),
                                    neonGreen.withOpacity(0.15),
                                  ],
                                ),
                                border: Border.all(
                                  color: neonBlue.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: neonBlue.withOpacity(0.5),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/images/logo.jpg",
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

                    const SizedBox(height: 20),

                    // ── TITLE ──────────────────────────────────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
                      ).createShader(bounds),
                      child: Text(
                        "VipX",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                          fontFamily: 'Orbitron',
                          shadows: [
                            Shadow(
                              color: neonBlue.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: neonGreen.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── SUBTITLE ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        "VipX",
                        style: TextStyle(
                          color: neonBlue.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── DESKRIPSI ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0A1620).withOpacity(0.8),
                            const Color(0xFF0D1A2B).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: neonBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(neonGreen),
                              const SizedBox(width: 8),
                              _buildDot(neonBlue),
                              const SizedBox(width: 8),
                              _buildDot(neonGreen),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please Login or Buy Access to Continue",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: neonBlue.withOpacity(0.7),
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── TOMBOL LOGIN ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 60,
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, "/login");
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "SIGN IN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── TOMBOL BUY ACCESS ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: neonBlue.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonBlue.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openUrl("https://t.me/abityzreall"),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              color: neonGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "BUY ACCESS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: neonGreen,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── TOMBOL CONTACT ─────────────────────────────────────
                    Row(
                      children: [
                        // Telegram
                        Expanded(
                          child: _buildContactButton(
                            icon: FontAwesomeIcons.telegram,
                            label: "Telegram",
                            url: "https://t.me/abityzreall",
                            color: const Color(0xFF0088cc),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // WhatsApp
                        Expanded(
                          child: _buildContactButton(
                            icon: FontAwesomeIcons.whatsapp,
                            label: "WhatsApp",
                            url: "https://wa.me/ke tele aja",
                            color: const Color(0xFF25D366),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── FOOTER ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: neonBlue.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        "© 2026 VipX • rYuuVip",
                        style: TextStyle(
                          color: neonBlue.withOpacity(0.3),
                          fontSize: 10,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A1620).withOpacity(0.7),
              const Color(0xFF0D1A2B).withOpacity(0.3),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}