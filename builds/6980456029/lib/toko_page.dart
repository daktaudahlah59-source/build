// toko_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TokoPage extends StatelessWidget {
  const TokoPage({super.key});

  // --- MODERN RED THEME (sama dengan dashboard) ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: redGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentRed.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, color: primaryWhite, size: 18),
              const SizedBox(width: 8),
              const Text(
                "ATOMIC STORE",
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: accentRed, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [accentRed.withOpacity(0.15), bgDark, bgDark],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Empty state message
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        color: glassPrimary,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: primaryWhite.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentRed.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentRed.withOpacity(0.1), darkRed.withOpacity(0.1)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: accentRed.withOpacity(0.2)),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.boxOpen,
                              size: 48,
                              color: accentRed,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => redGradient.createShader(bounds),
                            child: const Text(
                              'BUY ROLE CHAT OWNER /n Telegram: RyzzNotHuman',
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada produk yang tersedia saat ini.\nSilakan cek kembali nanti.',
                            style: TextStyle(
                              color: softGrey,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Decorative dot pattern
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (index) => AnimatedContainer(
                                duration: Duration(milliseconds: 400 + (index * 100)),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: redGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentRed.withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
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

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

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