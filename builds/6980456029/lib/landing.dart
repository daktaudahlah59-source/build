// landing.dart
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

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);
  static const Color glassPrimary = Color(0x1ABB86FC);
  static const Color glassSecondary = Color(0x0DBB86FC);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
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
      backgroundColor: bgDark,
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // ========== LOGO & TITLE ==========
                        _buildHeader(),

                        const SizedBox(height: 40),

                        // ========== FITUR CARD (HORIZONTAL - 4 CARD) ==========
                        _buildFeatureRow(),

                        const SizedBox(height: 40),

                        // ========== TOMBOL SIGN IN ==========
                        _buildSignInButton(),

                        const SizedBox(height: 16),

                        // ========== TOMBOL BUY ACCESS ==========
                        _buildBuyButton(),

                        const SizedBox(height: 40),

                        // ========== CONTACT SECTION ==========
                        _buildContactSection(),

                        const SizedBox(height: 30),

                        // ========== FOOTER ==========
                        _buildFooter(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo dengan gradient
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: purpleGradient,
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/logo.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.person, size: 50, color: primaryWhite),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Title ATOMIC dengan ShaderMask
        ShaderMask(
          shaderCallback: (bounds) => purpleGradient.createShader(bounds),
          child: const Text(
            "ATOMIC",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: primaryWhite,
              letterSpacing: 3,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: glassSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
          ),
          child: Text(
            "Advanced Security System",
            style: TextStyle(
              fontSize: 12,
              color: softGrey,
              letterSpacing: 0.8,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Powered by
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentPurple,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accentPurple, blurRadius: 5)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Powered by @maklowhngmis",
              style: TextStyle(
                fontSize: 10,
                color: softGrey.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentPurple,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accentPurple, blurRadius: 5)],
              ),
            ),
          ],
        ),
      ],
    );
  }

 // ==================== FEATURE ROW (HORIZONTAL - 4 CARD DI TENGAH) ====================
Widget _buildFeatureRow() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "WHY CHOOSE US",
            style: TextStyle(
              color: softGrey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Horizontal Scroll - TAPI DI TENGAH
      Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              _buildFeatureCard(
                icon: Icons.security_rounded,
                title: "SECURE",
                desc: "Encryption",
                delay: 0,
              ),
              const SizedBox(width: 12),
              _buildFeatureCard(
                icon: Icons.speed_rounded,
                title: "FAST",
                desc: "Response",
                delay: 100,
              ),
              const SizedBox(width: 12),
              _buildFeatureCard(
                icon: Icons.verified_rounded,
                title: "TRUSTED",
                desc: "Reliable",
                delay: 200,
              ),
              const SizedBox(width: 12),
              _buildFeatureCard(
                icon: Icons.support_agent_rounded,
                title: "24/7",
                desc: "Support",
                delay: 300,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + delay),
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
        width: 90, 
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: glassPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryWhite.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: purpleGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: primaryWhite, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryWhite,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                fontSize: 8,
                color: softGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SIGN IN BUTTON ====================
  Widget _buildSignInButton() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
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
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/login");
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: primaryWhite, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "SIGN IN",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryWhite,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== BUY ACCESS BUTTON ====================
  Widget _buildBuyButton() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
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
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: GestureDetector(
          onTap: () => _openUrl("https://t.me/RyzzNotHuman"),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentPurple.withOpacity(0.5), width: 1.5),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.telegram, color: accentPurple, size: 18),
                  SizedBox(width: 12),
                  Text(
                    "BUY ACCESS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentPurple,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== CONTACT SECTION ====================
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: purpleGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "CONTACT US",
              style: TextStyle(
                color: softGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildContactCard(
                icon: FontAwesomeIcons.telegram,
                label: "Telegram",
                url: "https://t.me/RyzzNotHuman",
                color: const Color(0xFF0088cc),
                delay: 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildContactCard(
                icon: FontAwesomeIcons.whatsapp,
                label: "WhatsApp",
                url: "https://wa.me/6281234567890",
                color: const Color(0xFF25D366),
                delay: 100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + delay),
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
      child: GestureDetector(
        onTap: () => _openUrl(url),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: glassPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: purpleGradient,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "© 2026 ATOMIC",
          style: TextStyle(
            color: softGrey.withOpacity(0.5),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
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