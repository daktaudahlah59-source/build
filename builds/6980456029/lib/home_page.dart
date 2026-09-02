// home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'config.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController targetController = TextEditingController();
  late final AnimationController _pulseController;
  String selectedBugId = "";
  String _selectedBugMode = "number";
  bool isSending = false;
  String? responseMessage;

  // Sender Type Selection
  String _selectedSenderType = "private";
  List<String> activeSenders = [];
  bool _isLoadingSenders = false;
  String? _senderError;

  // Video Player
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isVideoInitialized = false;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color cardDark = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025);
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFCF6679); // Merah muda lembut untuk error
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color liveGreen = Color(0xFF22C55E);

  Color get glassPrimary => const Color(0x1ABB86FC);
  Color get glassSecondary => const Color(0x0DBB86FC);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => const LinearGradient(
        colors: [Color(0xFF2A004E), Color(0xFF45006A)],
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

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    _initializeVideoPlayer();
    _fetchActiveSenders();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoController.setVolume(0.5); 
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            autoInitialize: true,
          );
          isVideoInitialized = true;
        });
      }
    }).catchError((error) {
      debugPrint("Video error: $error");
      if (mounted) {
        setState(() {
          isVideoInitialized = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveSenders() async {
    setState(() {
      _isLoadingSenders = true;
      _senderError = null;
    });

    try {
      final res = await http.get(
        Uri.parse("$apiBaseUrl/mySender?key=${widget.sessionKey}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data["valid"] == true) {
          final globalConnections = data["globalConnections"] as List<dynamic>? ?? [];
          setState(() {
            activeSenders = globalConnections
                .whereType<Map>()
                .map(
                  (item) => item["sessionName"]?.toString() ?? 
                           item["id"]?.toString() ?? 
                           "Unknown",
                )
                .toList();
          });
        } else {
          setState(() {
            _senderError = data["message"] ?? "Gagal memuat sender aktif";
            activeSenders = [];
          });
        }
      } else {
        setState(() {
          _senderError = "Server error: ${res.statusCode}";
          activeSenders = [];
        });
      }
    } catch (e) {
      setState(() {
        _senderError = "Connection failed: $e";
        activeSenders = [];
      });
    } finally {
      setState(() {
        _isLoadingSenders = false;
      });
    }
  }

  String? _formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com') && input.contains('https://');
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      final target = _formatPhoneNumber(rawInput);
      if (target == null || key.isEmpty) {
        _showMessageDialog(
          "Invalid Number",
          "Use international format (e.g., +62, +1, +44)",
        );
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showMessageDialog(
          "Invalid Link",
          "Enter a valid WhatsApp group link",
        );
        return;
      }
    }

    if (_selectedSenderType == "global" && activeSenders.isEmpty) {
      await _fetchActiveSenders();
      if (activeSenders.isEmpty) {
        _showMessageDialog(
          "No Global Sender",
          "No active global sender available",
        );
        return;
      }
    }

    setState(() {
      isSending = true;
      responseMessage = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          "$apiBaseUrl/sendBug?key=$key&target=$rawInput&bug=$selectedBugId&senderType=$_selectedSenderType",
        ),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data["cooldown"] == true) {
        final wait = data["wait"];
        setState(() => responseMessage = wait == null
            ? "⏳ Cooldown: Please wait a moment"
            : "⏳ Cooldown: Wait $wait seconds");
      } else if (data["valid"] == false) {
        setState(() => responseMessage = "❌ Invalid Session: Please login again");
      } else if (data["sended"] == false) {
        setState(() => responseMessage = "⚠️ ${data["message"] ?? "Failed to send bug"}");
      } else {
        final senderLabel = _selectedSenderType == "global" ? "global sender" : "private sender";
        setState(() => responseMessage = "✅ Attack sent successfully with $senderLabel!");
        targetController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => responseMessage = "❌ Error: Connection failed");
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
      if (_selectedSenderType == "global") {
        _fetchActiveSenders();
      }
    }
  }

  void _showMessageDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgDark, bgDark.withOpacity(0.95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accentPurple.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: purpleGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.warning_rounded, color: textWhite, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGrey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: purpleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Card Modern
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardDark, cardDark.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accentPurple.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: purpleGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: accentPurple.withOpacity(0.4), blurRadius: 20),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: textWhite,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentPurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: accentPurple.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      widget.role.toUpperCase(),
                                      style: TextStyle(color: accentPurple, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: darkPurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Exp: ${widget.expiredDate}",
                                      style: const TextStyle(color: textGrey, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Video Player
                  if (isVideoInitialized && _chewieController != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentPurple.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentPurple.withOpacity(0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentPurple.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab(
                          label: "BUG NOMOR",
                          icon: Icons.phone_android_rounded,
                          mode: "number",
                        ),
                        _buildModeTab(
                          label: "BUG GROUP",
                          icon: Icons.group_rounded,
                          mode: "group",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Target Input
                  Container(
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentPurple.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: targetController,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      cursorColor: accentPurple,
                      keyboardType: _selectedBugMode == "number" ? TextInputType.phone : TextInputType.url,
                      decoration: InputDecoration(
                        hintText: _selectedBugMode == "number" 
                            ? "+62xxxxxxxxxx" 
                            : "https://chat.whatsapp.com/...",
                        hintStyle: TextStyle(color: textGrey.withOpacity(0.5), fontSize: 13),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          _selectedBugMode == "number" 
                              ? Icons.phone_android_rounded 
                              : Icons.link_rounded,
                          color: accentPurple,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bug Selection
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "PILIH BUG",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 130,
                    child: Scrollbar(
                      thumbVisibility: false,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.listBug.length,
                        itemBuilder: (context, index) {
                          final bug = widget.listBug[index];
                          final isSelected = selectedBugId == bug['bug_id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedBugId = bug['bug_id'];
                              });
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? purpleGradient
                                    : LinearGradient(
                                        colors: [glassPrimary, glassSecondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? accentPurple : textWhite.withOpacity(0.08),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? secondaryGradient : null,
                                      color: isSelected ? null : glassSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.bug_report,
                                      color: isSelected ? textWhite : accentPurple,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bug['bug_name'],
                                    style: TextStyle(
                                      color: textWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? textWhite.withOpacity(0.2) 
                                          : accentPurple.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "ID: ${bug['bug_id']}",
                                      style: TextStyle(
                                        color: isSelected ? textWhite : accentPurple,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(Icons.check_circle, color: Colors.green, size: 14),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sender Type Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentPurple.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: purpleGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "PILIH SENDER",
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedSenderType = "private"),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedSenderType == "private"
                                        ? accentPurple.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedSenderType == "private"
                                          ? accentPurple
                                          : Colors.white12,
                                      width: _selectedSenderType == "private" ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        color: _selectedSenderType == "private" ? accentPurple : textGrey,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "PRIVATE",
                                        style: TextStyle(
                                          color: _selectedSenderType == "private" ? accentPurple : textGrey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Sender pribadi",
                                        style: TextStyle(color: textGrey, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedSenderType = "global");
                                  if (activeSenders.isEmpty) {
                                    _fetchActiveSenders();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedSenderType == "global"
                                        ? accentPurple.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedSenderType == "global"
                                          ? accentPurple
                                          : Colors.white12,
                                      width: _selectedSenderType == "global" ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.public_rounded,
                                        color: _selectedSenderType == "global" ? accentPurple : textGrey,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "GLOBAL",
                                        style: TextStyle(
                                          color: _selectedSenderType == "global" ? accentPurple : textGrey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Sender global",
                                        style: TextStyle(color: textGrey, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Active Senders Info
                        if (_selectedSenderType == "global") ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "SENDER AKTIF",
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _fetchActiveSenders,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: accentPurple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.refresh_rounded, color: accentPurple, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_isLoadingSenders)
                                  const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: accentPurple),
                                    ),
                                  )
                                else if (_senderError != null)
                                  Text(
                                    _senderError!,
                                    style: TextStyle(color: errorRed, fontSize: 12),
                                  )
                                else if (activeSenders.isEmpty)
                                  Text(
                                    "Tidak ada global sender aktif",
                                    style: TextStyle(color: textGrey, fontSize: 12),
                                  )
                                else
                                  ...activeSenders.map((sender) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: liveGreen,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sender,
                                                style: TextStyle(color: textWhite, fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: accentPurple, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Menggunakan sender pribadi dari session Anda",
                                    style: TextStyle(color: textGrey, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send Button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: accentPurple.withOpacity(0.3 * _pulseController.value),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isSending ? null : _sendBug,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: textWhite, strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.rocket_launch_rounded, color: textWhite, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      "SEND BUG ATTACK",
                                      style: TextStyle(
                                        color: textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),

                  // Response Message
                  if (responseMessage != null) ...[
                    const SizedBox(height: 20),
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: responseMessage!.contains('✅')
                              ? successGreen.withOpacity(0.1)
                              : responseMessage!.contains('❌')
                                  ? errorRed.withOpacity(0.1)
                                  : responseMessage!.contains('⚠️')
                                      ? warningOrange.withOpacity(0.1)
                                      : accentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: responseMessage!.contains('✅')
                                ? successGreen.withOpacity(0.3)
                                : responseMessage!.contains('❌')
                                    ? errorRed.withOpacity(0.3)
                                    : responseMessage!.contains('⚠️')
                                        ? warningOrange.withOpacity(0.3)
                                        : accentPurple.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              responseMessage!.contains('✅')
                                  ? Icons.check_circle
                                  : responseMessage!.contains('❌')
                                      ? Icons.error
                                      : Icons.warning,
                              color: responseMessage!.contains('✅')
                                  ? successGreen
                                  : responseMessage!.contains('❌')
                                      ? errorRed
                                      : warningOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                responseMessage!,
                                style: TextStyle(
                                  color: responseMessage!.contains('✅')
                                      ? successGreen
                                      : responseMessage!.contains('❌')
                                          ? errorRed
                                          : warningOrange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required String mode,
  }) {
    final isActive = _selectedBugMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedBugMode = mode;
          targetController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? purpleGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [BoxShadow(color: accentPurple.withOpacity(0.3), blurRadius: 8)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? textWhite : textGrey, size: 18),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? textWhite : textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
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

    final dotPaint = Paint()
      ..color = accentPurple.withOpacity(0.1)
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