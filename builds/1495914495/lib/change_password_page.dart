import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'config_github.dart';

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool configLoaded = false;

  // --- TEMA WARNA UNGU (Sama dengan Login Page) ---
  final Color bgDark = const Color(0xFF0D0221);
  final Color bgSecondary = const Color(0xFF1A0533);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFEA80FC);
  final Color whiteText = Colors.white;
  final Color grayText = Colors.white70;

  // Gradients
  final LinearGradient purpleGradient = const LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFEA80FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  // Fungsi untuk load config dari GitHub raw terlebih dahulu
  Future<void> _loadConfig() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load konfigurasi 100% dari GitHub RAW
      await ConfigGithub.loadConfig();
      
      setState(() {
        configLoaded = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      _showMessage(
        "Gagal mengambil konfigurasi server dari GitHub.\n\nError: $e\n\nPastikan koneksi internet Anda stabil.",
        isSuccess: false,
      );
    }
  }

  Future<void> _changePassword() async {
    if (!configLoaded) {
      _showMessage("Konfigurasi server belum siap. Tunggu sebentar atau restart aplikasi.");
      return;
    }

    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("Semua field harus diisi.");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("Password baru tidak cocok dengan konfirmasi.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("http://capekkenaoanyak.onlinepanel.my.id:2002/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "sessionKey": widget.sessionKey,
        },
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage("Password berhasil diubah!", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
        
        // Update password di SharedPreferences jika ada
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("password", newPass);
      } else {
        _showMessage(data['message'] ?? "Gagal mengubah password");
      }
    } catch (e) {
      _showMessage("Koneksi error: $e");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12002C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: accentPurple,
            ),
            const SizedBox(width: 10),
            Text(
              isSuccess ? "Sukses" : "Peringatan",
              style: TextStyle(
                color: whiteText,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(msg, style: TextStyle(color: grayText, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(
                color: accentPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET INPUT (SAMA PERSIS DENGAN LOGIN PAGE) ---
  Widget _buildInput(TextEditingController controller, String label, IconData icon, [bool isPassword = false]) {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: accentPurple),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentPurple),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "CHANGE PASSWORD",
          style: TextStyle(
            color: whiteText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header Icon dengan Glow Effect
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: purpleGradient,
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.lock_reset, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                "SECURITY UPDATE",
                style: TextStyle(
                  color: whiteText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: accentPurple.withOpacity(0.5),
                      blurRadius: 15,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Masukkan password lama dan baru.",
                style: TextStyle(
                  color: grayText,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Form Inputs
            _buildInput(oldPassCtrl, "Old Password", Icons.lock_outline, true),
            _buildInput(newPassCtrl, "New Password", Icons.vpn_key, true),
            _buildInput(confirmPassCtrl, "Confirm Password", Icons.enhanced_encryption, true),

            const SizedBox(height: 30),

            // Button dengan efek loading dan lebar dinamis
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: purpleGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : _changePassword,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "UPDATE PASSWORD",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }
}