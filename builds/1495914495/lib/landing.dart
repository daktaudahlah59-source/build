import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- TEMA WARNA UNGU ---
  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFEA80FC);
  final Color glassBorder = Colors.white.withOpacity(0.15);
  final Color cardBg = Colors.white.withOpacity(0.08);

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryDark,
              primaryPurple.withOpacity(0.4),
              primaryDark,
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
                    const SizedBox(height: 40),

                    // --- AVATAR REZE (TANPA OVAL, BENTUK ASLI) ---
                    // --- STACK (TEKS NUMPUK DI FOTO) ---
                    Container(
                      width: 320,
                      height: 400, // Tinggi area gabungan foto & teks
                      child: Stack(
                        alignment: Alignment.bottomCenter, // Posisi teks di bagian bawah
                        children: [
                          // LAYER 1: FOTO (Di bawah)
                          Positioned.fill(
                            child: Image.asset(
                              "assets/images/reze.png",
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: primaryPurple);
                              },
                            ),
                          ),

                          // LAYER 2: TEKS (Di atas foto)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30), // Geser teks sedikit ke atas dari bawah
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [accentPurple, Colors.white],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "OFF LIGHT",
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Please Log in or Buy Access to continue",
                                  style: TextStyle(
                                    color: Colors.white70, // Sedikit lebih terang agar terbaca di foto
                                    fontSize: 12,
                                    shadows: [
                                      Shadow( // Bayangan agar teks terbaca jelas di atas gambar
                                        blurRadius: 4,
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40), // Jarak ke tombol di bawahnya

                    // --- TOMBOL LOGIN ---
                    Container(
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Sign In",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- TOMBOL BUY ACCESS ---
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryPurple.withOpacity(0.5)),
                      ),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openUrl("https://t.me/rikzxMD_real"),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag, color: accentPurple, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Buy Access",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentPurple),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- TOMBOL CONTACT (SEJAJAR KANAN KIRI) ---
                    Row(
                      children: [
                        // Tombol Telegram
                        Expanded(
                          child: _buildContactButton(
                            icon: FontAwesomeIcons.telegram,
                            label: "Telegram",
                            url: "https://t.me/rikzxMD_real",
                            color: const Color(0xFF0088cc),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Tombol WhatsApp
                        Expanded(
                          child: _buildContactButton(
                            icon: FontAwesomeIcons.whatsapp,
                            label: "WhatsApp",
                            url: "https://wa.me/6287732756731",
                            color: const Color(0xFF25D366),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- FOOTER ---
                    Text(
                      "© 2026 OFF LIGHT",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
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

  Widget _buildContactButton({required IconData icon, required String label, required String url, required Color color}) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}