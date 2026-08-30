import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'config_github.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listGroupBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.listGroupBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  String selectedBugId = "";
  String selectedGroupBugId = "";
  String _selectedBugMode = "number";
  String _selectedSenderType = "pribadi";
  
  bool _isSending = false;
  String? _responseMessage;
  
  // Counter untuk sender
  int _personalSenderCount = 0;
  int _privateSenderCount = 0;
  bool _isLoadingCounts = true;
  bool _configLoaded = false;

  final Color primaryBg = const Color(0xFF0F0F1A);
  final Color cardBg = const Color(0xFF1E1E2E);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFE040FB);
  final Color deepPurple = const Color(0xFF4A148C);
  final Color textWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color virusRed = const Color(0xFFD32F2F);
  final Color globalBlue = const Color(0xFF2196F3);

  final LinearGradient purpleGradient = const LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }
    if (widget.listGroupBug.isNotEmpty) {
      selectedGroupBugId = widget.listGroupBug[0]['bug_id'];
    }

    _initializeVideoPlayer();
    _loadConfigAndFetchCounts();
  }

  Future<void> _loadConfigAndFetchCounts() async {
    try {
      // Pastikan config sudah di-load
      if (!ConfigGithub.isLoaded) {
        await ConfigGithub.loadConfig();
      }
      
      setState(() {
        _configLoaded = true;
      });
      
      await _fetchSenderCounts();
    } catch (e) {
      print("Error loading config: $e");
      setState(() {
        _configLoaded = false;
        _isLoadingCounts = false;
      });
    }
  }

  Future<void> _fetchSenderCounts() async {
    if (!_configLoaded) return;
    
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      final response = await http.get(
        Uri.parse("http://capekkenaoanyak.onlinepanel.my.id:2002/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          // Ambil langsung dari response personalCount dan globalCount
          setState(() {
            _personalSenderCount = data["personalCount"] ?? 0;
            _privateSenderCount = data["globalCount"] ?? 0;
          });
          
          print("SENDER COUNTS - Personal: $_personalSenderCount, Global: $_privateSenderCount");
        }
      }
    } catch (e) {
      print("Error fetching sender counts: $e");
    } finally {
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com');
  }

  Future<void> _sendBug() async {
    if (!_configLoaded) {
      _showAlert("⚠️ Config Error", "Konfigurasi server belum siap. Silakan restart aplikasi.");
      return;
    }
    
    if (_selectedBugMode == "number") {
      await _sendNumberBug();
    } else {
      await _sendGroupBug();
    }
  }

  Future<void> _sendNumberBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62xxx, 1xxx, 44xxx), bukan 08xxx.");
      return;
    }

    // Validasi sender sebelum mengirim
    if (_selectedSenderType == "pribadi" && _personalSenderCount == 0) {
      _showAlert("⚠️ Tidak Ada Sender PRIBADI", 
        "Anda tidak memiliki Sender PRIBADI!\n\n"
        "Silahkan pairing nomor WhatsApp Anda terlebih dahulu melalui menu Pairing.\n\n"
        "Sender PRIBADI adalah nomor WhatsApp pribadi Anda yang akan digunakan untuk mengirim bug.");
      return;
    }
    
    if (_selectedSenderType == "private" && _privateSenderCount == 0) {
      _showAlert("⚠️ Tidak Ada Sender GLOBAL", 
        "Tidak ada Sender GLOBAL yang aktif!\n\n"
        "Sender GLOBAL adalah nomor WhatsApp yang disediakan oleh admin.\n"
        "Silahkan hubungi admin untuk informasi lebih lanjut.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://capekkenaoanyak.onlinepanel.my.id:2002/sendBug?key=$key&target=$target&bug=$selectedBugId&senderType=$_selectedSenderType"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ ${data["message"] ?? "Gagal mengirim bug."}");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage = "⚠️ Gagal: ${data["message"] ?? "Server sedang maintenance."}");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
        // Refresh sender counts after sending
        await _fetchSenderCounts();
      }
    } catch (_) {
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendGroupBug() async {
    final link = targetController.text.trim();
    final key = widget.sessionKey;

    if (!isValidGroupLink(link)) {
      _showAlert("❌ Invalid Link", "Gunakan link WhatsApp Group yang valid (chat.whatsapp.com)");
      return;
    }

    if (key.isEmpty) {
      _showAlert("❌ Error", "Session key tidak valid");
      return;
    }

    // Validasi sender sebelum mengirim
    if (_selectedSenderType == "pribadi" && _personalSenderCount == 0) {
      _showAlert("⚠️ Tidak Ada Sender PRIBADI", 
        "Anda tidak memiliki Sender PRIBADI!\n\n"
        "Silahkan pairing nomor WhatsApp Anda terlebih dahulu melalui menu Pairing.");
      return;
    }
    
    if (_selectedSenderType == "private" && _privateSenderCount == 0) {
      _showAlert("⚠️ Tidak Ada Sender GLOBAL", 
        "Tidak ada Sender GLOBAL yang aktif!\n\n"
        "Hubungi admin untuk menambahkan sender global.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://capekkenaoanyak.onlinepanel.my.id:2002/sendGroupBug?key=$key&bug=$selectedGroupBugId&link=${Uri.encodeComponent(link)}&senderType=$_selectedSenderType"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ ${data["message"] ?? "Gagal mengirim bug."}");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage = "⚠️ Gagal: ${data["message"] ?? "Server sedang maintenance."}");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke group!");
        targetController.clear();
        // Refresh sender counts after sending
        await _fetchSenderCounts();
      }
    } catch (_) {
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryPurple.withOpacity(0.5)),
        ),
        title: Text(title,
            style: const TextStyle(
              color: Color(0xFFE040FB),
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            )),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'ShareTechMono'
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: purpleGradient,
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
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
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
                    style: TextStyle(
                      color: accentPurple,
                      fontFamily: 'ShareTechMono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: accentPurple,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: accentPurple.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Stack(
            children: [
              Chewie(controller: _chewieController),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primaryPurple.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedBugMode = "number";
                targetController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedBugMode == "number"
                    ? accentPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBugMode == "number" ? accentPurple : primaryPurple.withOpacity(0.3),
                  width: _selectedBugMode == "number" ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    color: _selectedBugMode == "number" ? accentPurple : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BUG NOMOR",
                    style: TextStyle(
                      color: _selectedBugMode == "number" ? accentPurple : textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedBugMode = "group";
                targetController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedBugMode == "group"
                    ? accentPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBugMode == "group" ? accentPurple : primaryPurple.withOpacity(0.3),
                  width: _selectedBugMode == "group" ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    color: _selectedBugMode == "group" ? accentPurple : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BUG GROUP",
                    style: TextStyle(
                      color: _selectedBugMode == "group" ? accentPurple : textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bug_report,
            color: virusRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: cardBg,
                value: _selectedBugMode == "number" ? selectedBugId : selectedGroupBugId,
                isExpanded: true,
                iconEnabledColor: accentPurple,
                iconSize: 28,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'ShareTechMono'),
                items: (_selectedBugMode == "number" ? widget.listBug : widget.listGroupBug).map((item) {
                  return DropdownMenuItem<String>(
                    value: item['bug_id'],
                    child: Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          color: virusRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['bug_name'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (_selectedBugMode == "number") {
                      selectedBugId = value ?? "";
                    } else {
                      selectedGroupBugId = value ?? "";
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModeSelector(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryPurple.withOpacity(0.15),
                  border: Border.all(
                    color: primaryPurple,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _selectedBugMode == "number" ? Icons.phone_android_rounded : Icons.link,
                  color: primaryPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedBugMode == "number" ? "NOMOR TARGET" : "LINK GROUP WA",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: accentPurple,
            keyboardType: _selectedBugMode == "number" ? TextInputType.phone : TextInputType.url,
            decoration: InputDecoration(
              hintText: _selectedBugMode == "number"
                  ? "Contoh: +62xxxxxxxxxx"
                  : "Contoh: https://chat.whatsapp.com/...",
              hintStyle: TextStyle(color: textGrey.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryPurple.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE040FB), width: 2),
              ),
              prefixIcon: Icon(
                _selectedBugMode == "number" ? Icons.phone_android_rounded : Icons.link,
                color: primaryPurple,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: virusRed.withOpacity(0.15),
                  border: Border.all(
                    color: virusRed,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.bug_report,
                  color: virusRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedBugMode == "number" ? "PILIH BUG" : "PILIH GROUP BUG",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdownButton(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: globalBlue.withOpacity(0.15),
                  border: Border.all(
                    color: globalBlue,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.public,
                  color: globalBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "PILIH SENDER",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSenderType = "pribadi";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "pribadi"
                        ? accentPurple.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSenderType == "pribadi" ? accentPurple : primaryPurple.withOpacity(0.3),
                      width: _selectedSenderType == "pribadi" ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: _selectedSenderType == "pribadi" ? accentPurple : textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SENDER PRIBADI",
                            style: TextStyle(
                              color: _selectedSenderType == "pribadi" ? accentPurple : textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _isLoadingCounts
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: _selectedSenderType == "pribadi" ? accentPurple : textGrey,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  size: 12,
                                  color: _personalSenderCount > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$_personalSenderCount",
                                  style: TextStyle(
                                    color: _personalSenderCount > 0 
                                        ? Colors.green 
                                        : Colors.red,
                                    fontSize: 14,
                                    fontFamily: 'ShareTechMono',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSenderType = "private";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "private"
                        ? accentPurple.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSenderType == "private" ? accentPurple : primaryPurple.withOpacity(0.3),
                      width: _selectedSenderType == "private" ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public,
                            color: _selectedSenderType == "private" ? accentPurple : textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SENDER GLOBAL",
                            style: TextStyle(
                              color: _selectedSenderType == "private" ? accentPurple : textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _isLoadingCounts
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: _selectedSenderType == "private" ? accentPurple : textGrey,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 12,
                                  color: _privateSenderCount > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$_privateSenderCount",
                                  style: TextStyle(
                                    color: _privateSenderCount > 0 
                                        ? Colors.green 
                                        : Colors.red,
                                    fontSize: 14,
                                    fontFamily: 'ShareTechMono',
                                    fontWeight: FontWeight.bold,
                                  ),
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
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: purpleGradient,
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.4),
                blurRadius: _pulseController.value * 25,
                spreadRadius: _pulseController.value * 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selectedBugMode == "number" ? Icons.rocket_launch_rounded : Icons.group_add, 
                           color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        _selectedBugMode == "number" ? "SEND BUG ATTACK" : "SEND TO GROUP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      bgColor = Colors.green.withOpacity(0.15);
      borderColor = Colors.greenAccent;
      textColor = Colors.greenAccent;
      icon = Icons.check_circle_outline_rounded;
    } else if (_responseMessage!.startsWith('❌') || _responseMessage!.startsWith('⚠️')) {
      bgColor = Colors.red.withOpacity(0.15);
      borderColor = Colors.redAccent;
      textColor = Colors.redAccent;
      icon = Icons.error_outline_rounded;
    } else {
      bgColor = primaryPurple.withOpacity(0.15);
      borderColor = accentPurple;
      textColor = accentPurple;
      icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              const SizedBox(height: 20),
              _buildVideoPlayer(),
              const SizedBox(height: 20),
              _buildInputPanel(),
              const SizedBox(height: 40),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}