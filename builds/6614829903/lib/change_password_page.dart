import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import '.dart';

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

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── TEMA HIJAU-BIRU MENYALA ─────────────────────────────────────────────
  static const Color bgDark = Color(0xFF060A0F);
  static const Color bgSecondary = Color(0xFF0A1620);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color primaryWhite = Colors.white;
  static const Color textGrey = Colors.grey;
  static const Color cardGlass = Color(0xFF0A1620);
  static const Color borderGlass = Color(0xFF1A3A4A);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    // Validasi dengan pesan yang lebih jelas
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("⚠️ Semua field harus diisi!", isError: true);
      return;
    }

    if (oldPass.length < 6) {
      _showMessage("⚠️ Password lama minimal 6 karakter!", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showMessage("⚠️ Password baru minimal 6 karakter!", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("⚠️ Password baru tidak cocok dengan konfirmasi!", isError: true);
      return;
    }

    if (oldPass == newPass) {
      _showMessage("⚠️ Password baru tidak boleh sama dengan password lama!", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("$BaseUrl/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "sessionKey": widget.sessionKey,
        },
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage(
          "✅ Password berhasil diubah!\nSilakan login dengan password baru.",
          isSuccess: true,
        );
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
        // Kembali ke halaman sebelumnya setelah sukses
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage(
          "❌ ${data['message'] ?? 'Gagal mengubah password'}",
          isError: true,
        );
      }
    } catch (e) {
      _showMessage(
        "❌ Koneksi error: ${e.toString().replaceAll('Exception: ', '')}",
        isError: true,
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSuccess ? neonGreen.withOpacity(0.5) : neonBlue.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? neonGreen : neonBlue,
            ),
            const SizedBox(width: 10),
            Text(
              isSuccess ? "SUKSES" : "PERINGATAN",
              style: TextStyle(
                color: isSuccess ? neonGreen : neonBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: textGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: isSuccess ? neonGradient : LinearGradient(
                  colors: [neonBlue.withOpacity(0.3), neonBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: isSuccess ? Colors.black : neonBlue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardGlass,
            const Color(0xFF0D1A2B).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'ShareTechMono',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: neonBlue.withOpacity(0.6),
            fontFamily: 'Orbitron',
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(
            icon,
            color: neonBlue,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: textGrey,
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          errorStyle: TextStyle(
            color: neonBlue,
            fontFamily: 'Orbitron',
            fontSize: 10,
          ),
        ),
        onFieldSubmitted: (_) => _changePassword(),
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: neonBlue, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF39FF14)],
          ).createShader(bounds),
          child: Text(
            "SECURITY",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: neonBlue.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  neonBlue.withOpacity(0.5),
                  neonGreen.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── Icon dengan pulse ──────────────────────────────────────────
            Center(
              child: ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 110,
                  height: 110,
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
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: neonGreen.withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: neonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.black,
                      size: 45,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────────
            Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
                ).createShader(bounds),
                child: Text(
                  "CHANGE PASSWORD",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: neonBlue.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                "Update your security credentials",
                style: TextStyle(
                  color: textGrey,
                  fontFamily: 'ShareTechMono',
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Form Inputs ──────────────────────────────────────────────
            _buildInput(
              oldPassCtrl,
              "OLD PASSWORD",
              Icons.lock_outline_rounded,
              true,
              _obscureOldPassword,
              () => setState(() => _obscureOldPassword = !_obscureOldPassword),
            ),

            _buildInput(
              newPassCtrl,
              "NEW PASSWORD",
              Icons.vpn_key_outlined,
              true,
              _obscureNewPassword,
              () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),

            _buildInput(
              confirmPassCtrl,
              "CONFIRM PASSWORD",
              Icons.enhanced_encryption_outlined,
              true,
              _obscureConfirmPassword,
              () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),

            // ── Password Strength Indicator ──────────────────────────────
            if (newPassCtrl.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(4, (index) {
                          final isFilled = newPassCtrl.text.length >= (index + 1) * 2;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: isFilled
                                    ? LinearGradient(
                                        colors: [
                                          newPassCtrl.text.length >= 6
                                              ? neonGreen
                                              : neonBlue,
                                          newPassCtrl.text.length >= 8
                                              ? neonGreen
                                              : neonBlue,
                                        ],
                                      )
                                    : null,
                                color: isFilled ? null : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newPassCtrl.text.length < 6
                          ? "🔒 Weak - min 6 characters"
                          : newPassCtrl.text.length < 8
                              ? "🔐 Medium - 6-7 characters"
                              : "🔑 Strong - 8+ characters",
                      style: TextStyle(
                        color: newPassCtrl.text.length < 6
                            ? neonBlue
                            : newPassCtrl.text.length < 8
                                ? Colors.orange
                                : neonGreen,
                        fontSize: 10,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ── Update Button ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: neonGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: neonGreen.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        "UPDATE PASSWORD",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          fontSize: 15,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Text ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1620).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: neonBlue.withOpacity(0.1),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: neonBlue.withOpacity(0.5), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Password must be at least 6 characters",
                      style: TextStyle(
                        color: textGrey.withOpacity(0.6),
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}