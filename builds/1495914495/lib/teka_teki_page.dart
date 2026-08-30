import 'package:flutter/material.dart';

class TekaTekiPage extends StatefulWidget {
  const TekaTekiPage({super.key});

  @override
  State<TekaTekiPage> createState() => _TekaTekiPageState();
}

class _TekaTekiPageState extends State<TekaTekiPage> {
  // Warna tema
  final Color primaryDark = Colors.black;
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color primaryWhite = Colors.white;
  final Color cardDark = const Color(0xFF1A1A1A);

  // Daftar teka-teki
  final List<Map<String, String>> tekaTekiList = [
    {
      "soal": "Apa yang selalu datang, tapi tidak pernah tiba?",
      "jawaban": "Besok"
    },
    {
      "soal": "Kalau dipegang mati, kalau dilepas mati. Apakah itu?",
      "jawaban": "Pegangan tebing"
    },
    {
      "soal": "Benda apa yang kalau diinjak malah senyum?",
      "jawaban": "Karpet"
    },
    {
      "soal": "Ayam apa yang bikin sebel?",
      "jawaban": "Ayamnya habis, nasinya masih banyak"
    },
    {
      "soal": "Lemari apa yang bisa masuk kantong?",
      "jawaban": "Lema ribu (1000)"
    },
    {
      "soal": "Kecil, hijau, kalau dipencet jadi apa?",
      "jawaban": "Mati"
    },
    {
      "soal": "Kenapa Superman punya huruf S di dadanya?",
      "jawaban": "Soalnye kalo huruf M mah Mahal"
    },
    {
      "soal": "Bis apa yang bisa dimakan?",
      "jawaban": "Biskuit"
    },
    {
      "soal": "Telur mana yang bisa terbang?",
      "jawaban": "Telur angsa"
    },
    {
      "soal": "Buah apa yang durhaka?",
      "jawaban": "Melon (membangkang)"
    },
  ];

  int currentIndex = 0;
  final TextEditingController answerController = TextEditingController();
  String feedbackMessage = "";
  bool showAnswer = false;

  void nextTekaTeki() {
    setState(() {
      currentIndex = (currentIndex + 1) % tekaTekiList.length;
      answerController.clear();
      feedbackMessage = "";
      showAnswer = false;
    });
  }

  void previousTekaTeki() {
    setState(() {
      currentIndex = (currentIndex - 1 + tekaTekiList.length) % tekaTekiList.length;
      answerController.clear();
      feedbackMessage = "";
      showAnswer = false;
    });
  }

  void cekJawaban() {
    String userAnswer = answerController.text.toLowerCase().trim();
    String correctAnswer = tekaTekiList[currentIndex]['jawaban']!.toLowerCase();
    
    if (userAnswer.isEmpty) {
      setState(() {
        feedbackMessage = "Isi jawaban dulu bang!";
      });
      return;
    }

    if (userAnswer == correctAnswer) {
      setState(() {
        feedbackMessage = "✅ JAWABAN LU BENER! Pinter juga yak!";
        showAnswer = false;
      });
    } else {
      setState(() {
        feedbackMessage = "❌ SALAH! Lu kira-kira aja deh...";
        showAnswer = false;
      });
    }
  }

  void lihatJawaban() {
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "TEKA-TEKI",
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
            // Header Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: Text(
                "TEKA-TEKI ${currentIndex + 1}/${tekaTekiList.length}",
                style: TextStyle(
                  color: lightPurple,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card Soal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryPurple.withOpacity(0.2),
                    accentPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: primaryPurple.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.question_mark,
                    color: lightPurple,
                    size: 50,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tekaTekiList[currentIndex]['soal']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryWhite,
                      fontFamily: 'ShareTechMono',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  if (showAnswer) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: lightPurple),
                      ),
                      child: Text(
                        "Jawaban: ${tekaTekiList[currentIndex]['jawaban']!}",
                        style: TextStyle(
                          color: lightPurple,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

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
                  hintText: "Masukkan jawaban teka-teki...",
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

            const SizedBox(height: 15),

            // Feedback Message
            if (feedbackMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
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

            // Button Row 1 (CEK & LIHAT JAWABAN)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "CEK",
                    icon: Icons.check,
                    onTap: cekJawaban,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: showAnswer ? "SEMBUNYIKAN" : "LIHAT JAWABAN",
                    icon: showAnswer ? Icons.visibility_off : Icons.visibility,
                    onTap: lihatJawaban,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Button Row 2 (PREV & NEXT)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "SEBELUMNYA",
                    icon: Icons.arrow_back,
                    onTap: previousTekaTeki,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: "SELANJUTNYA",
                    icon: Icons.arrow_forward,
                    onTap: nextTekaTeki,
                    color: accentPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: lightPurple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tebak jawaban teka-tekinya. Kalau buntu, bisa liat jawaban!",
                      style: TextStyle(
                        color: primaryWhite.withOpacity(0.7),
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryWhite, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: primaryWhite,
                  fontFamily: 'Orbitron',
                  fontSize: 10,
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