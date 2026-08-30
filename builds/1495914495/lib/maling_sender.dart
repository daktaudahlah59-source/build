import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config_github.dart';

class MalingSenderPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const MalingSenderPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<MalingSenderPage> createState() => _MalingSenderPageState();
}

class _MalingSenderPageState extends State<MalingSenderPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  Color _statusColor = Colors.white;
  Map<String, dynamic>? _credsData;
  final TextEditingController _credsController = TextEditingController();
  String? _phoneNumber;
  bool _isConnected = false;
  bool _configLoaded = false;

  // Warna tema
  final Color primaryDark = Colors.black;
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color primaryWhite = Colors.white;
  final Color cardDark = const Color(0xFF1A1A1A);
  final Color successGreen = const Color(0xFF4CAF50);
  final Color errorRed = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  // Load config dari GitHub terlebih dahulu
  Future<void> _loadConfig() async {
    try {
      await ConfigGithub.loadConfig();
      setState(() => _configLoaded = true);
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mengambil konfigurasi server.\nError: $e';
        _statusColor = errorRed;
      });
    }
  }

  @override
  void dispose() {
    _credsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MALING SENDER',
          style: TextStyle(
            color: primaryWhite,
            fontSize: 18,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPurple, accentPurple],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            _buildInfoCard(),

            const SizedBox(height: 25),

            // TextArea Input
            _buildTextArea(),

            const SizedBox(height: 20),

            // Tombol Parse & Clear
            Row(
              children: [
                // Tombol Parse
                Expanded(
                  child: _buildActionButton(
                    onTap: _parseCredsText,
                    label: 'VALIDATE',
                    icon: Icons.check_circle_outline,
                    color: lightPurple,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 10),
                // Tombol Clear
                Expanded(
                  child: _buildActionButton(
                    onTap: _clearData,
                    label: 'CLEAR',
                    icon: Icons.clear,
                    color: errorRed,
                    isLoading: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Preview Area (jika sudah di-parse)
            if (_credsData != null) _buildCredsPreview(),

            const SizedBox(height: 25),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _statusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusColor == successGreen
                          ? Icons.check_circle
                          : Icons.error,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusColor,
                          fontFamily: 'ShareTechMono',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tombol Cek Koneksi
            if (_credsData != null && !_isConnected)
              _buildFullWidthButton(
                onTap: _checkConnection,
                label: 'CEK KONEKSI WHATSAPP',
                icon: Icons.sensors,
                color: lightPurple,
                isLoading: _isLoading,
              ),

            const SizedBox(height: 12),

            // Success Result
            if (_isConnected) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      successGreen.withOpacity(0.2),
                      successGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: successGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: successGreen, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      '✓ SENDER AKTIF',
                      style: TextStyle(
                        color: successGreen,
                        fontSize: 18,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phoneNumber ?? 'Unknown',
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 20,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berhasil ditambahkan ke akun Anda',
                      style: TextStyle(
                        color: lightPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryPurple.withOpacity(0.3),
            accentPurple.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: lightPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'INFORMASI',
                style: TextStyle(
                  color: lightPurple,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '📌 Cara Penggunaan:\n'
            '1. Copy isi file creds.json dari WhatsApp session\n'
            '2. Paste ke text area di bawah\n'
            '3. Klik VALIDATE untuk memeriksa format\n'
            '4. Jika valid, klik CEK KONEKSI WHATSAPP\n'
            '5. Tunggu 10-30 detik\n'
            '6. Jika berhasil, sender akan aktif',
            style: TextStyle(
              color: primaryWhite.withOpacity(0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _credsData != null
              ? successGreen.withOpacity(0.5)
              : primaryPurple.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _credsController,
        maxLines: 12,
        style: TextStyle(
          color: primaryWhite,
          fontFamily: 'ShareTechMono',
          fontSize: 11,
        ),
        decoration: InputDecoration(
          hintText: 'Paste isi creds.json di sini...\n\nContoh:\n{\n  "noiseKey": {\n    "private": {\n      "type": "Buffer",\n      "data": "mORmp+QkRIQnP0V4PrsK4/Hpuz9iLxViv/0SENuJZmY="\n    },\n    ...\n  }\n}',
          hintStyle: TextStyle(
            color: primaryWhite.withOpacity(0.3),
            fontFamily: 'ShareTechMono',
            fontSize: 10,
          ),
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (text) {
          if (_credsData != null) {
            setState(() {
              _credsData = null;
              _isConnected = false;
              _statusMessage = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildCredsPreview() {
    String phoneNumber = _extractPhoneNumber();
    String platform = _credsData?['platform'] ?? 'Unknown';
    String name = _credsData?['me']?['name'] ?? 'Unknown';
    String deviceId = _credsData?['deviceId'] ?? '-';
    String registrationId = _credsData?['registrationId']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: lightPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                'PREVIEW CREDS.JSON',
                style: TextStyle(
                  color: lightPurple,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewRow('Nomor', phoneNumber, Icons.phone_android),
          _buildPreviewRow('Nama', name, Icons.person),
          _buildPreviewRow('Platform', platform, Icons.devices),
          _buildPreviewRow('Device ID', deviceId, Icons.fingerprint),
          _buildPreviewRow('Registration ID', registrationId, Icons.numbers),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: lightPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: primaryWhite.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 14,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryPurple, accentPurple],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryWhite),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryWhite, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFullWidthButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryPurple, accentPurple],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryWhite),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryWhite, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 16,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _extractPhoneNumber() {
    try {
      if (_credsData == null) return '-';
      String? meId = _credsData?['me']?['id'];
      if (meId != null) {
        return meId.split(':')[0];
      }
      return '-';
    } catch (e) {
      return '-';
    }
  }

  void _parseCredsText() {
    if (!_configLoaded) {
      setState(() {
        _statusMessage = 'Konfigurasi server belum siap. Tunggu sebentar.';
        _statusColor = errorRed;
      });
      return;
    }
    
    final text = _credsController.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Masukkan isi creds.json terlebih dahulu';
        _statusColor = errorRed;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Memvalidasi creds.json...';
      _statusColor = lightPurple;
    });

    try {
      // Bersihkan teks dari karakter yang tidak diinginkan
      String cleanText = text.trim();
      
      // Hapus ```json atau ``` jika ada (format code block)
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      
      cleanText = cleanText.trim();

      final Map<String, dynamic> jsonData = json.decode(cleanText);

      // Validasi minimal struktur creds.json
      if (!jsonData.containsKey('me') || !jsonData.containsKey('registered')) {
        throw Exception('File bukan creds.json yang valid (me atau registered tidak ditemukan)');
      }

      // Validasi me.id harus ada
      if (jsonData['me'] == null || jsonData['me']['id'] == null) {
        throw Exception('me.id tidak ditemukan dalam creds');
      }

      setState(() {
        _credsData = jsonData;
        _phoneNumber = _extractPhoneNumber();
        _statusMessage = '✓ Creds valid! Silahkan cek koneksi.';
        _statusColor = successGreen;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Format tidak valid: ${e.toString()}';
        _statusColor = errorRed;
        _isLoading = false;
        _credsData = null;
      });
    }
  }

  void _clearData() {
    setState(() {
      _credsController.clear();
      _credsData = null;
      _isConnected = false;
      _phoneNumber = null;
      _statusMessage = '';
    });
  }

  Future<void> _checkConnection() async {
    if (!_configLoaded) {
      setState(() {
        _statusMessage = 'Konfigurasi server belum siap. Tunggu sebentar.';
        _statusColor = errorRed;
      });
      return;
    }
    
    if (_credsData == null) {
      setState(() {
        _statusMessage = 'Validasi creds.json terlebih dahulu';
        _statusColor = errorRed;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Mengecek koneksi WhatsApp...\nIni bisa memakan waktu 10-30 detik';
      _statusColor = lightPurple;
    });

    try {
      final phoneNumber = _extractPhoneNumber();
      
      // Ganti URL dengan endpoint server Anda - menggunakan ConfigGithub
      final response = await http.post(
        Uri.parse('http://capekkenaoanyak.onlinepanel.my.id:2002/api/check-sender-connection'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sessionKey': widget.sessionKey,
          'creds': _credsData,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 35));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isConnected = true;
          _phoneNumber = phoneNumber;
          _statusMessage = '✓ Koneksi berhasil! Sender aktif.';
          _statusColor = successGreen;
          _isLoading = false;
        });

        _showSuccessDialog();
      } else {
        throw Exception(data['message'] ?? 'Gagal connect ke WhatsApp');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Gagal connect: ${e.toString()}';
        _statusColor = errorRed;
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: successGreen),
            const SizedBox(width: 8),
            Text(
              'BERHASIL!',
              style: TextStyle(
                color: primaryWhite,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sender berhasil ditambahkan:',
              style: TextStyle(color: primaryWhite.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successGreen.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _phoneNumber ?? 'Unknown',
                    style: TextStyle(
                      color: lightPurple,
                      fontSize: 24,
                      fontFamily: 'ShareTechMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _credsData?['me']?['name'] ?? '',
                    style: TextStyle(
                      color: primaryWhite.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '✓ Sender sekarang aktif\n'
              '✓ Siap digunakan untuk mengirim bug\n'
              '✓ Tersimpan di akun Anda',
              style: TextStyle(color: successGreen, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: primaryWhite,
              backgroundColor: primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: primaryPurple.withOpacity(0.3)),
        ),
      ),
    );
  }
}