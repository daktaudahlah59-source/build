// nik_check.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NikCheckerPage extends StatefulWidget {
  const NikCheckerPage({super.key});

  @override
  State<NikCheckerPage> createState() => _NikCheckerPageState();
}

class _NikCheckerPageState extends State<NikCheckerPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkNik() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      setState(() {
        _errorMessage = "NIK tidak boleh kosong.";
        _data = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _data = null;
    });

    final url = Uri.parse("https://api.siputzx.my.id/api/tools/nik-checker?nik=$nik");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _data = json['data'];
            _errorMessage = null;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            _errorMessage = "Data tidak ditemukan atau NIK tidak valid.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data dari server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: darkPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentPurple.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryWhite, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveInfoRow({
    required String label,
    required String? value,
    IconData? copyIcon = Icons.copy,
    VoidCallback? onCopy,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryWhite.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            Container(
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: accentPurple.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: Icon(copyIcon, color: accentPurple, size: 18),
                onPressed: onCopy,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Salin $label',
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label disalin ke clipboard',
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentPurple.withOpacity(0.5)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: purpleGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "NIK CHECKER",
            style: TextStyle(
              color: primaryWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryWhite),
      ),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkPurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentPurple.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nikController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: primaryWhite, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Masukkan NIK',
                            labelStyle: const TextStyle(color: softGrey),
                            hintText: 'Contoh: 5206085405880001',
                            hintStyle: TextStyle(color: softGrey.withOpacity(0.5)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accentPurple.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: accentPurple, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: bgDark,
                            suffixIcon: _isLoading
                                ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: accentPurple,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : null,
                          ),
                          onSubmitted: (_) => _checkNik(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _checkNik,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: purpleGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentPurple.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_isLoading ? Icons.hourglass_top : Icons.search, color: primaryWhite, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLoading ? 'MEMPROSES...' : 'CEK DATA NIK',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                        color: primaryWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkPurple,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade200, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (_data != null)
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCategoryCard(
                                title: "IDENTITAS DIRI",
                                icon: Icons.person,
                                children: [
                                  _buildInteractiveInfoRow(
                                    label: "NIK",
                                    value: _data!["nik"]?.toString(),
                                    onCopy: () => _copyToClipboard(_data!["nik"]?.toString() ?? "", "NIK"),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Nama Lengkap",
                                    value: _data!["data"]["nama"]?.toString(),
                                    onCopy: () => _copyToClipboard(_data!["data"]["nama"]?.toString() ?? "", "Nama"),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Jenis Kelamin",
                                    value: _data!["data"]["kelamin"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Tempat Lahir",
                                    value: _data!["data"]["tempat_lahir"]?.toString(),
                                    onCopy: () => _copyToClipboard(_data!["data"]["tempat_lahir"]?.toString() ?? "", "Tempat Lahir"),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Usia",
                                    value: _data!["data"]["usia"]?.toString(),
                                  ),
                                ],
                              ),

                              _buildCategoryCard(
                                title: "DATA DOMISILI",
                                icon: Icons.location_on,
                                children: [
                                  _buildInteractiveInfoRow(
                                    label: "Provinsi",
                                    value: _data!["data"]["provinsi"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Kabupaten/Kota",
                                    value: _data!["data"]["kabupaten"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Kecamatan",
                                    value: _data!["data"]["kecamatan"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Kelurahan/Desa",
                                    value: _data!["data"]["kelurahan"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Alamat Lengkap",
                                    value: _data!["data"]["alamat"]?.toString(),
                                    onCopy: () => _copyToClipboard(_data!["data"]["alamat"]?.toString() ?? "", "Alamat"),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "TPS",
                                    value: _data!["data"]["tps"]?.toString(),
                                  ),
                                ],
                              ),

                              _buildCategoryCard(
                                title: "INFORMASI TAMBAHAN",
                                icon: Icons.info,
                                children: [
                                  _buildInteractiveInfoRow(
                                    label: "Zodiak",
                                    value: _data!["data"]["zodiak"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Ultah Mendatang",
                                    value: _data!["data"]["ultah_mendatang"]?.toString(),
                                  ),
                                  _buildInteractiveInfoRow(
                                    label: "Pasaran",
                                    value: _data!["data"]["pasaran"]?.toString(),
                                  ),
                                ],
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
        ),
      ),
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}