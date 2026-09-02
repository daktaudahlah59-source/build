// phone_lookup_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class PhoneLookupPage extends StatefulWidget {
  final String sessionKey;

  const PhoneLookupPage({
    super.key,
    required this.sessionKey,
  });

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, String>? _phoneData;
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

  Future<void> _lookupPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan nomor telepon";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _phoneData = null;
    });

    try {
      final url = Uri.parse("https://free-lookup.net/$phone");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;
        
        // Ekstrak data menggunakan RegExp
        Map<String, String> info = {};
        
        // Pattern untuk mencari div dengan class tertentu
        final divPattern = RegExp(r'<div class="report-summary__item">[\s\S]*?<div class="report-summary__label">(.*?)<\/div>[\s\S]*?<div class="report-summary__value">(.*?)<\/div>', caseSensitive: false);
        
        final matches = divPattern.allMatches(body);
        for (var match in matches) {
          if (match.groupCount >= 2) {
            String key = _cleanHtml(match.group(1) ?? '');
            String value = _cleanHtml(match.group(2) ?? '');
            if (key.isNotEmpty && value.isNotEmpty && value != "Not found" && value != "-") {
              info[key] = value;
            }
          }
        }
        
        // Pattern alternatif untuk tabel
        if (info.isEmpty) {
          final tablePattern = RegExp(r'<tr>[\s\S]*?<td>(.*?)<\/td>[\s\S]*?<td>(.*?)<\/td>[\s\S]*?<\/tr>', caseSensitive: false);
          final tableMatches = tablePattern.allMatches(body);
          for (var match in tableMatches) {
            if (match.groupCount >= 2) {
              String key = _cleanHtml(match.group(1) ?? '');
              String value = _cleanHtml(match.group(2) ?? '');
              if (key.isNotEmpty && value.isNotEmpty && value != "Not found" && value != "-") {
                info[key] = value;
              }
            }
          }
        }
        
        if (info.isNotEmpty) {
          setState(() {
            _phoneData = info;
          });
        } else {
          setState(() {
            _errorMessage = "Data tidak ditemukan untuk nomor ini";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _cleanHtml(String text) {
    // Hapus tag HTML
    String cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Hapus entity HTML
    cleaned = cleaned.replaceAll('&nbsp;', ' ');
    cleaned = cleaned.replaceAll('&amp;', '&');
    cleaned = cleaned.replaceAll('&lt;', '<');
    cleaned = cleaned.replaceAll('&gt;', '>');
    cleaned = cleaned.replaceAll('&quot;', '"');
    cleaned = cleaned.replaceAll('&#39;', "'");
    // Trim spasi berlebih
    cleaned = cleaned.trim();
    return cleaned;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("$label disalin ke clipboard");
  }

  void _copyAllData() {
    if (_phoneData == null) return;
    final allData = _phoneData!.entries.map((e) => "${e.key}: ${e.value}").join('\n');
    Clipboard.setData(ClipboardData(text: allData));
    _showSnackBar("Semua data disalin");
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: primaryWhite)),
        backgroundColor: darkPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentPurple.withOpacity(0.5)),
        ),
      ),
    );
  }

  IconData _getInfoIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('phone') || lower.contains('number')) return Icons.phone_android;
    if (lower.contains('country')) return Icons.public;
    if (lower.contains('city') || lower.contains('location')) return Icons.location_city;
    if (lower.contains('carrier') || lower.contains('operator')) return Icons.signal_cellular_alt;
    if (lower.contains('type')) return Icons.devices;
    if (lower.contains('valid')) return Icons.check_circle;
    if (lower.contains('spam')) return Icons.warning;
    if (lower.contains('time') || lower.contains('zone')) return Icons.access_time;
    return Icons.info;
  }

  Color _getInfoColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('valid')) return Colors.green;
    if (lower.contains('spam') || lower.contains('fraud')) return Colors.red.shade300;
    return accentPurple;
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
            "PHONE LOOKUP",
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
        actions: [
          if (_phoneData != null)
            IconButton(
              icon: const Icon(Icons.copy_all, color: accentPurple),
              onPressed: _copyAllData,
            ),
        ],
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
                  // Input Card
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
                          controller: _phoneController,
                          style: const TextStyle(color: primaryWhite, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Masukkan Nomor Telepon',
                            labelStyle: const TextStyle(color: softGrey),
                            hintText: 'Contoh: 6281234567890 atau +6281234567890',
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
                            prefixIcon: const Icon(Icons.phone_android, color: accentPurple),
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
                          keyboardType: TextInputType.phone,
                          onSubmitted: (_) => _lookupPhone(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _lookupPhone,
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
                                      _isLoading ? 'MEMPROSES...' : 'LOOKUP PHONE',
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

                  // Error Message
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

                  // Result Card
                  if (_phoneData != null && _phoneData!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: darkPurple,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentPurple.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                                    ),
                                    child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DATA DITEMUKAN',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        '${_phoneData!.length} informasi ditemukan',
                                        style: TextStyle(color: softGrey.withOpacity(0.7), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ..._phoneData!.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final icon = _getInfoIcon(label);
    final color = _getInfoColor(label);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
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
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: color, size: 18),
            onPressed: () => _copyToClipboard(value, label),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
        ],
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