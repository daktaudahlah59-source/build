// ngl_page.dart
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;

  // --- Warna Tema Merah (Sama dengan halaman lain) ---
  final Color primaryDark = Colors.black;
  final Color primaryRed = const Color(0xFF424242);
  final Color accentRed = const Color(0xFF303030);
  final Color lightRed = const Color(0xFF616161);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardDark = const Color(0xFF0D0D0D);

  // Gradients
  final LinearGradient redGradient = const LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF424242)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // generate deviceId random
  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          counter++;
          statusLog = "✅ [$counter] Pesan terkirim";
        });
      } else {
        setState(() {
          statusLog = "❌ Ratelimit (${response.statusCode}), tunggu 5 detik...";
        });
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        statusLog = "⚠️ Error: $e";
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        statusLog = "⚠️ Harap isi username & pesan!";
      });
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      statusLog = "▶️ Mulai mengirim...";
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isRunning) {
        sendMessage(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "⏹️ Dihentikan.";
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "NGL Auto Sender",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: primaryWhite,
          ),
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryWhite),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryRed.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: primaryWhite, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Username NGL",
                        labelStyle: TextStyle(color: lightRed),
                        hintText: "contoh: username_ngl",
                        hintStyle: TextStyle(color: accentGrey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryRed.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: lightRed, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        prefixIcon: Icon(Icons.person, color: lightRed),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      style: TextStyle(color: primaryWhite, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Pesan",
                        labelStyle: TextStyle(color: lightRed),
                        hintText: "Masukkan pesan yang ingin dikirim...",
                        hintStyle: TextStyle(color: accentGrey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryRed.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: lightRed, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        prefixIcon: Icon(Icons.message, color: lightRed),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Control Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? null : startLoop,
                        icon: Icon(Icons.play_arrow, color: primaryWhite),
                        label: Text(
                          "START",
                          style: TextStyle(
                            color: primaryWhite,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: primaryRed.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? stopLoop : null,
                        icon: Icon(Icons.stop, color: primaryWhite),
                        label: Text(
                          "STOP",
                          style: TextStyle(
                            color: primaryWhite,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: accentRed.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: redGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: primaryWhite, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "STATUS LOG",
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Log
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryRed.withOpacity(0.2)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLog.isEmpty ? "Menunggu perintah..." : statusLog,
                                  style: TextStyle(
                                    color: _getStatusColor(statusLog),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'ShareTechMono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Counter
                      if (counter > 0)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: lightRed, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "Total terkirim: ",
                                style: TextStyle(
                                  color: lightRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$counter",
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Info Box
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryRed.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: lightRed, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Auto send setiap 2 detik. Stop manual jika sudah cukup.",
                                style: TextStyle(
                                  color: accentGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('✅')) return Colors.greenAccent;
    if (status.contains('❌')) return Colors.white70;
    if (status.contains('⚠️')) return Colors.orangeAccent;
    if (status.contains('▶️')) return Colors.greenAccent;
    if (status.contains('⏹️')) return Colors.orangeAccent;
    return primaryWhite;
  }
}