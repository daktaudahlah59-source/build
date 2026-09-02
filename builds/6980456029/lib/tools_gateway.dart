// tools_page.dart
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'shortlink_page.dart';
import 'ip_scanner_page.dart';
import 'phone_lookup_page.dart';

class ToolsPage extends StatelessWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  // --- MODERN RED THEME ---
  static const Color bgDark = Color(0xFF000000);
  static const Color accentRed = Color(0xFF9E9E9E);
  static const Color darkRed = Color(0xFF212121);
  static const Color softRed = Color(0xFF424242);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF9E9E9E);
  static const Color glassPrimary = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x0DFFFFFF);

  LinearGradient get redGradient => const LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF424242)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => const LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF424242)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              accentRed.withOpacity(0.15),
              bgDark,
              bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: SafeArea(
            child: Column(
              children: [
                // === GLASS HEADER ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, double scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: redGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentRed.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.build_circle_outlined,
                                  color: primaryWhite,
                                  size: 42,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => redGradient.createShader(bounds),
                        child: const Text(
                          "Tools Dashboard",
                          style: TextStyle(
                            color: primaryWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryWhite.withOpacity(0.08)),
                        ),
                        child: Text(
                          "Advanced Security & OSINT Tools",
                          style: TextStyle(color: softGrey, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // === GLASS CATEGORY CARDS ===
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.1,
                      children: [
                        _buildGlassToolCard(
                          icon: Icons.flash_on_rounded,
                          title: "DDoS Tools",
                          subtitle: "Attack Panel",
                          gradient: redGradient,
                          onTap: () => _showDDoSTools(context),
                        ),
                        _buildGlassToolCard(
                          icon: Icons.wifi_rounded,
                          title: "Network",
                          subtitle: "WiFi & Spam",
                          gradient: secondaryGradient,
                          onTap: () => _showNetworkTools(context),
                        ),
                        _buildGlassToolCard(
                          icon: Icons.search_rounded,
                          title: "OSINT",
                          subtitle: "Investigation",
                          gradient: redGradient,
                          onTap: () => _showOSINTTools(context),
                        ),
                        _buildGlassToolCard(
                          icon: Icons.download_rounded,
                          title: "Downloader",
                          subtitle: "Social Media",
                          gradient: secondaryGradient,
                          onTap: () => _showDownloaderTools(context),
                        ),
                        _buildGlassToolCard(
                          icon: Icons.build_rounded,
                          title: "Utilities",
                          subtitle: "Extra Tools",
                          gradient: redGradient,
                          onTap: () => _showUtilityTools(context),
                        ),
                        _buildGlassToolCard(
                          icon: Icons.rocket_launch_rounded,
                          title: "Quick Access",
                          subtitle: "Favorites",
                          gradient: secondaryGradient,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
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

  Widget _buildGlassToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, double scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: glassPrimary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: accentRed.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // KE BAWAH (BOTTOM)
              crossAxisAlignment: CrossAxisAlignment.start, // KE KIRI (LEFT)
              children: [
                const Spacer(), // Mendorong ke bawah
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentRed.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: primaryWhite, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: softGrey, fontSize: 11, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGlassBottomSheet(BuildContext context, String title, IconData icon, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(color: primaryWhite.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: glassPrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: redGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentRed.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: primaryWhite, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: primaryWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDDoSTools(BuildContext context) {
    _showGlassBottomSheet(
      context,
      "DDoS Tools",
      Icons.flash_on_rounded,
      [
        _buildGlassToolOption(
          icon: Icons.flash_on_rounded,
          label: "Attack Panel",
          description: "Launch DDoS attacks with power",
          color: accentRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttackPanel(
                  sessionKey: sessionKey,
                  listDoos: listDoos,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGlassToolOption(
          icon: Icons.dns_rounded,
          label: "Manage Server",
          description: "Configure server settings",
          color: softRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageServerPage(keyToken: sessionKey),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNetworkTools(BuildContext context) {
    List<Widget> options = [
      _buildGlassToolOption(
        icon: Icons.message_rounded,
        label: "Spam NGL",
        description: "Anonymous message spam",
        color: accentRed,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NglPage()),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildGlassToolOption(
        icon: Icons.wifi_off_rounded,
        label: "WiFi Killer (Internal)",
        description: "Internal network attacks",
        color: softRed,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WifiKillerPage()),
          );
        },
      ),
    ];

    if (userRole == "vip" || userRole == "owner" || userRole == "reseller") {
      options.addAll([
        const SizedBox(height: 12),
        _buildGlassToolOption(
          icon: Icons.router_rounded,
          label: "WiFi Killer (External)",
          description: "External network attacks",
          color: darkRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WifiInternalPage(sessionKey: sessionKey),
              ),
            );
          },
        ),
      ]);
    }

    _showGlassBottomSheet(context, "Network Tools", Icons.wifi_rounded, options);
  }

  void _showOSINTTools(BuildContext context) {
    _showGlassBottomSheet(
      context,
      "OSINT Tools",
      Icons.search_rounded,
      [
        _buildGlassToolOption(
          icon: Icons.badge_rounded,
          label: "NIK Detail",
          description: "Indonesian ID card lookup",
          color: accentRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NikCheckerPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGlassToolOption(
          icon: Icons.domain_rounded,
          label: "Domain OSINT",
          description: "Domain information gathering",
          color: softRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DomainOsintPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGlassToolOption(
  icon: Icons.phone_android_rounded,
  label: "Phone Lookup",
  description: "Cek informasi nomor telepon",
  color: accentRed,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneLookupPage(
          sessionKey: sessionKey,
        ),
      ),
    );
  },
),
      ],
    );
  }

  void _showDownloaderTools(BuildContext context) {
    _showGlassBottomSheet(
      context,
      "Media Downloader",
      Icons.download_rounded,
      [
        _buildGlassToolOption(
          icon: Icons.video_library_rounded,
          label: "TikTok Downloader",
          description: "Download TikTok videos without watermark",
          color: accentRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TiktokDownloaderPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGlassToolOption(
          icon: Icons.camera_alt_rounded,
          label: "Instagram Downloader",
          description: "Download Instagram content",
          color: softRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InstagramDownloaderPage()),
            );
          },
        ),
      ],
    );
  }

  void _showUtilityTools(BuildContext context) {
    _showGlassBottomSheet(
      context,
      "Utility Tools",
      Icons.build_rounded,
      [
        _buildGlassToolOption(
          icon: Icons.qr_code_rounded,
          label: "QR Generator",
          description: "Generate QR codes instantly",
          color: accentRed,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrGeneratorPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGlassToolOption(
  icon: Icons.link_rounded,
  label: "Shortlink URL",
  description: "Pendekkan URL panjangmu",
  color: accentRed,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShortlinkPage(
          sessionKey: sessionKey,
        ),
      ),
    );
  },
),
const SizedBox(height: 12),
  _buildGlassToolOption(
  icon: Icons.dns_rounded,
  label: "IP Scanner",
  description: "Cek informasi alamat IP",
  color: accentRed,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IpScannerPage(
          sessionKey: sessionKey,
        ),
      ),
    );
  },
),
      ],
    );
  }

  Widget _buildGlassToolOption({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
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
        decoration: BoxDecoration(
          color: glassSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryWhite, size: 20),
          ),
          title: Text(
            label,
            style: const TextStyle(
              color: primaryWhite,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              color: softGrey,
              fontSize: 12,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: redGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: primaryWhite, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Coming Soon!',
              style: TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: glassPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryWhite.withOpacity(0.08)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Custom Grid Painter for background
class _GridPainter extends CustomPainter {
  static const Color accentRed = Color(0xFF9E9E9E);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw accent grid lines (every 5th line)
    final accentPaint = Paint()
      ..color = accentRed.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    // Draw dots at grid intersections
    final dotPaint = Paint()
      ..color = accentRed.withOpacity(0.1)
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