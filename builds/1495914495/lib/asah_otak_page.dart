import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AsahOtakPage extends StatefulWidget {
  const AsahOtakPage({super.key});

  @override
  State<AsahOtakPage> createState() => _AsahOtakPageState();
}

class _AsahOtakPageState extends State<AsahOtakPage> {
  // Warna tema
  final Color primaryDark = Colors.black;
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color primaryWhite = Colors.white;
  final Color cardDark = const Color(0xFF1A1A1A);

  String currentSoal = "Klik 'ASAH OTAK BEGO LU' untuk memulai";
  String currentJawaban = "";
  final TextEditingController answerController = TextEditingController();
  String feedbackMessage = "";
  bool isLoading = false;
  bool hasSoal = false;

  Future<void> fetchSoal() async {
    setState(() {
      isLoading = true;
      feedbackMessage = "";
      answerController.clear();
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.siputzx.my.id/api/games/asahotak"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            currentSoal = data['data']['soal'];
            currentJawaban = data['data']['jawaban'].toString().toLowerCase().trim();
            hasSoal = true;
            isLoading = false;
          });
        } else {
          setState(() {
            currentSoal = "Gagal mengambil soal";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          currentSoal = "Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        currentSoal = "Error: $e";
        isLoading = false;
      });
    }
  }

  void cekJawaban() {
    if (!hasSoal) {
      setState(() {
        feedbackMessage = "Ambil soal dulu bang!";
      });
      return;
    }

    String userAnswer = answerController.text.toLowerCase().trim();
    
    if (userAnswer.isEmpty) {
      setState(() {
        feedbackMessage = "Isi jawaban dulu tod!";
      });
      return;
    }

    if (userAnswer == currentJawaban) {
      setState(() {
        feedbackMessage = "✅ OTAK LU ENAK! Jawaban benar!";
      });
    } else {
      setState(() {
        feedbackMessage = "❌ OTAK LU BEGO! Jawaban salah!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "ASAH OTAK",
          style: TextStyle(
            color: primaryWhite,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple, accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card Soal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryPurple.withOpacity(0.2),
                    accentPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryPurple.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_alt,
                    color: lightPurple,
                    size: 40,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "SOAL:",
                    style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentSoal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryWhite,
                      fontFamily: 'ShareTechMono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(lightPurple),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Input Jawaban
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: primaryPurple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: answerController,
                style: TextStyle(color: primaryWhite, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "Masukkan jawaban...",
                  hintStyle: TextStyle(
                    color: primaryWhite.withOpacity(0.5),
                    fontFamily: 'ShareTechMono',
                  ),
                  prefixIcon: Icon(Icons.edit, color: lightPurple),
                  filled: true,
                  fillColor: cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Feedback Message
            if (feedbackMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: feedbackMessage.contains("✅")
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: feedbackMessage.contains("✅")
                        ? Colors.green
                        : Colors.red,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  feedbackMessage,
                  style: TextStyle(
                    color: feedbackMessage.contains("✅")
                        ? Colors.green
                        : Colors.red,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // Button Row
            Row(
              children: [
                // Button ASAH OTAK BEGO LU
                Expanded(
                  child: _buildGradientButton(
                    label: "ASAH OTAK BEGO LU",
                    icon: Icons.psychology,
                    onTap: fetchSoal,
                    gradient: [primaryPurple, accentPurple],
                  ),
                ),
                const SizedBox(width: 10),
                // Button CEK OTAK
                Expanded(
                  child: _buildGradientButton(
                    label: "CEK OTAK",
                    icon: Icons.check_circle,
                    onTap: cekJawaban,
                    gradient: [accentPurple, primaryPurple],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: lightPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tebak jawaban dari soal yang diberikan. Klik 'ASAH OTAK BEGO LU' untuk mendapatkan soal baru!",
                      style: TextStyle(
                        color: primaryWhite.withOpacity(0.7),
                        fontFamily: 'ShareTechMono',
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
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: lightPurple.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryWhite, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryWhite,
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}