import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME MODERN - ABU-ABU GELAP DENGAN AKSEN NEON
// ─────────────────────────────────────────────────────────────────────────────
class ModernTheme {
  
  // Warna dasar
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const card = Color(0xFF1A1A1A);
  static const cardHover = Color(0xFF222222);
  static const border = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFF3D3D3D);
  
  // Warna teks
  static const text = Color(0xFFF0F0F0);
  static const sub = Color(0xFFA8A8A8);
  static const muted = Color(0xFF666666);
  
  // Warna neon aksen
  static const neonBlue = Color(0xFF4A9EFF);
  static const neonRed = Color(0xFFFF4757);
  static const neonGreen = Color(0xFF2ED573);
  static const neonOrange = Color(0xFFFF6B35);
  static const neonPurple = Color(0xFFA855F7);
  static const neonCyan = Color(0xFF22D3EE);
  static const neonPink = Color(0xFFFF4081);
  static const neonYellow = Color(0xFFFBBF24);
  
  // Gradien
  static const LinearGradient gradientBlue = LinearGradient(
    colors: [neonBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientGreen = LinearGradient(
    colors: [neonGreen, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientOrange = LinearGradient(
    colors: [neonOrange, neonRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientPink = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN MANAJEMEN IZIN
// ─────────────────────────────────────────────────────────────────────────────
class DevicePermissionManagerPage extends StatefulWidget {
  final String sessionKey;
  final String role;
  final List<dynamic> allDevices;

  const DevicePermissionManagerPage({
    super.key,
    required this.sessionKey,
    required this.role,
    required this.allDevices,
  });

  @override
  State<DevicePermissionManagerPage> createState() =>
      _DevicePermissionManagerPageState();
}

class _DevicePermissionManagerPageState
    extends State<DevicePermissionManagerPage> with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  List<dynamic> _devices = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMsg;
  Map<String, bool> _permissions = {};
  int _selectedDeviceIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  
  // ── Animasi ──────────────────────────────────────────────────────────────
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ── Siklus Hidup ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    _devices = List.from(widget.allDevices);
    _loadPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Memuat Izin ──────────────────────────────────────────────────────────
  Future<void> _loadPermissions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          '$BaseUrl/rat/permissions?key=${widget.sessionKey}&role=${widget.role}',
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          final perms = data['permissions'] ?? {};
          setState(() {
            _permissions = Map<String, bool>.from(perms);
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _errorMsg = 'Gagal memuat izin perangkat';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  // ── Mengubah Izin ─────────────────────────────────────────────────────────
  Future<void> _togglePermission(String deviceId, String permission, bool value) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final res = await http.post(
        Uri.parse('$BaseUrl/rat/set-permission'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'role': widget.role,
          'deviceId': deviceId,
          'permission': permission,
          'value': value,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) {
        setState(() => _isSaving = false);
        return;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _permissions['$deviceId:$permission'] = value;
          });
          _showToast(
            value ? '✅ Izin diaktifkan' : '❌ Izin dinonaktifkan',
            color: value ? ModernTheme.neonGreen : ModernTheme.neonRed,
          );
        } else {
          throw Exception(data['message'] ?? 'Gagal memperbarui izin');
        }
      } else {
        throw Exception('Server error ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Error: $e', color: ModernTheme.neonRed);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Tindakan Massal ──────────────────────────────────────────────────────
  Future<void> _applyBulkPermission(String permission, bool value) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final onlineDevices = _devices.where((d) => d['online'] == true).toList();
    if (onlineDevices.isEmpty) {
      _showToast('Tidak ada perangkat online', color: ModernTheme.neonOrange);
      setState(() => _isSaving = false);
      return;
    }

    try {
      int success = 0;
      for (final device in onlineDevices) {
        final deviceId = device['id'] ?? 'unknown';
        final res = await http.post(
          Uri.parse('$BaseUrl/rat/set-permission'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'key': widget.sessionKey,
            'role': widget.role,
            'deviceId': deviceId,
            'permission': permission,
            'value': value,
          }),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true) {
            setState(() {
              _permissions['$deviceId:$permission'] = value;
            });
            success++;
          }
        }
      }

      _showToast(
        '✅ $success perangkat berhasil diperbarui',
        color: ModernTheme.neonGreen,
      );
    } catch (e) {
      _showToast('Error: $e', color: ModernTheme.neonRed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Membantu ─────────────────────────────────────────────────────────────
  String _getDeviceName(dynamic device) {
    return device['model'] ?? device['name'] ?? 'Perangkat Tidak Dikenal';
  }

  bool _getPermission(String deviceId, String perm) {
    return _permissions['$deviceId:$perm'] ?? false;
  }

  void _showToast(String msg, {Color color = ModernTheme.neonBlue}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  List<dynamic> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    return _devices.where((d) {
      final name = _getDeviceName(d).toLowerCase();
      final id = (d['id'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMsg != null
                      ? _buildErrorState()
                      : _filteredDevices.isEmpty
                          ? _buildEmptyState()
                          : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ModernTheme.gradientBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Manajemen Izin',
            style: TextStyle(
              color: ModernTheme.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      backgroundColor: ModernTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: ModernTheme.text),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Tindakan massal
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: ModernTheme.sub),
          color: ModernTheme.card,
          onSelected: (value) {
            final parts = value.split('|');
            if (parts.length == 2) {
              _applyBulkPermission(parts[0], parts[1] == 'true');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'access|true',
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: ModernTheme.neonGreen, size: 18),
                  SizedBox(width: 10),
                  Text('Aktifkan Semua Akses', style: TextStyle(color: ModernTheme.text)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'access|false',
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded, color: ModernTheme.neonRed, size: 18),
                  SizedBox(width: 10),
                  Text('Nonaktifkan Semua Akses', style: TextStyle(color: ModernTheme.text)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'location|true',
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: ModernTheme.neonGreen, size: 18),
                  SizedBox(width: 10),
                  Text('Aktifkan Semua Lokasi', style: TextStyle(color: ModernTheme.text)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'camera|true',
              child: Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: ModernTheme.neonGreen, size: 18),
                  SizedBox(width: 10),
                  Text('Aktifkan Semua Kamera', style: TextStyle(color: ModernTheme.text)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'microphone|true',
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, color: ModernTheme.neonGreen, size: 18),
                  SizedBox(width: 10),
                  Text('Aktifkan Semua Mikrofon', style: TextStyle(color: ModernTheme.text)),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: ModernTheme.neonBlue),
          onPressed: _loadPermissions,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ModernTheme.border,
        ),
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ModernTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ModernTheme.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: ModernTheme.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: const TextStyle(color: ModernTheme.text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Cari perangkat...',
                  hintStyle: TextStyle(color: ModernTheme.muted, fontSize: 12),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  color: ModernTheme.muted,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Loading State ─────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: ModernTheme.neonBlue,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Memuat izin perangkat...',
            style: TextStyle(color: ModernTheme.sub, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ModernTheme.neonRed.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: ModernTheme.neonRed.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: ModernTheme.neonRed,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ada yang salah!',
            style: TextStyle(
              color: ModernTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMsg!,
            style: TextStyle(
              color: ModernTheme.sub,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: ModernTheme.gradientBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _loadPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ModernTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: ModernTheme.border),
            ),
            child: Icon(
              Icons.devices_other_rounded,
              color: ModernTheme.muted,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tidak Ada Perangkat',
            style: TextStyle(
              color: ModernTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hubungkan perangkat terlebih dahulu',
            style: TextStyle(
              color: ModernTheme.sub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Konten Utama ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    final filtered = _filteredDevices;
    
    return Column(
      children: [
        _buildStatsBar(filtered),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final device = filtered[index];
              final deviceId = device['id'] ?? 'unknown';
              final isOnline = device['online'] == true;
              final deviceName = _getDeviceName(device);

              return _buildDeviceCard(device, deviceId, isOnline, deviceName);
            },
          ),
        ),
      ],
    );
  }

  // ── Stats Bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar(List<dynamic> devices) {
    final online = devices.where((d) => d['online'] == true).length;
    final total = devices.length;
    final enabled = _permissions.values.where((v) => v == true).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        border: const Border(bottom: BorderSide(color: ModernTheme.border)),
      ),
      child: Row(
        children: [
          _buildStatItem('Total', total.toString(), ModernTheme.neonBlue),
          _buildStatItem('Online', online.toString(), ModernTheme.neonGreen),
          _buildStatItem('Diaktifkan', enabled.toString(), ModernTheme.neonPurple),
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.1)),
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
                color: ModernTheme.muted,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kartu Perangkat ──────────────────────────────────────────────────────
  Widget _buildDeviceCard(dynamic device, String deviceId, bool isOnline, String deviceName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? ModernTheme.neonCyan.withOpacity(0.2)
              : ModernTheme.border,
          width: 1,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: ModernTheme.neonCyan.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? LinearGradient(
                          colors: [ModernTheme.neonCyan.withOpacity(0.2), ModernTheme.neonCyan.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isOnline ? Colors.transparent : ModernTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline
                        ? ModernTheme.neonCyan.withOpacity(0.3)
                        : ModernTheme.border,
                  ),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: isOnline ? ModernTheme.neonCyan : ModernTheme.muted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: TextStyle(
                        color: ModernTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? ModernTheme.neonGreen : ModernTheme.neonRed,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline ? ModernTheme.neonGreen : ModernTheme.neonRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ID: ${deviceId.substring(0, 8)}...',
                          style: TextStyle(
                            color: ModernTheme.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? ModernTheme.neonCyan.withOpacity(0.1)
                      : ModernTheme.muted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline
                        ? ModernTheme.neonCyan.withOpacity(0.2)
                        : ModernTheme.muted.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  isOnline ? 'AKTIF' : 'NONAKTIF',
                  style: TextStyle(
                    color: isOnline ? ModernTheme.neonCyan : ModernTheme.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(
            color: ModernTheme.border,
            height: 1,
          ),
          const SizedBox(height: 14),

          // Toggle Izin - Baris 1
          Row(
            children: [
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'access',
                  '📱 Akses',
                  ModernTheme.neonBlue,
                ),
              ),
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'location',
                  '📍 Lokasi',
                  ModernTheme.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Toggle Izin - Baris 2
          Row(
            children: [
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'camera',
                  '📷 Kamera',
                  ModernTheme.neonOrange,
                ),
              ),
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'microphone',
                  '🎤 Mikrofon',
                  ModernTheme.neonPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Toggle Izin - Baris 3
          Row(
            children: [
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'sms',
                  '📨 SMS',
                  ModernTheme.neonCyan,
                ),
              ),
              Expanded(
                child: _buildPermissionToggle(
                  deviceId,
                  'contacts',
                  '👤 Kontak',
                  ModernTheme.neonPink,
                ),
              ),
            ],
          ),
          
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                color: ModernTheme.neonBlue,
                backgroundColor: ModernTheme.border,
              ),
            ),
        ],
      ),
    );
  }

  // ── Toggle Izin ──────────────────────────────────────────────────────────
  Widget _buildPermissionToggle(
    String deviceId,
    String perm,
    String label,
    Color color,
  ) {
    final isEnabled = _getPermission(deviceId, perm);
    final isOnline = _devices.firstWhere(
      (d) => (d['id'] ?? '') == deviceId,
      orElse: () => {'online': false},
    )['online'] == true;
    
    return GestureDetector(
      onTap: isOnline ? () => _togglePermission(deviceId, perm, !isEnabled) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? color.withOpacity(0.2)
                : ModernTheme.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? color : ModernTheme.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isEnabled
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isEnabled ? color : ModernTheme.muted,
                  size: 14,
                ),
              ],
            ),
            if (!isOnline)
              Text(
                'offline',
                style: TextStyle(
                  color: ModernTheme.muted,
                  fontSize: 7,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⬇️ TAMBAHKAN INI DI BAWAH ⬇️
// ─────────────────────────────────────────────────────────────────────────────

class PermissionResult {
  final bool isGranted;
  final String message;
  
  PermissionResult({required this.isGranted, required this.message});
  
  factory PermissionResult.fromJson(Map<String, dynamic> json) {
    return PermissionResult(
      isGranted: json['granted'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class DevicePermissionStore {
  static Future<PermissionResult?> getFor(String username, String sessionKey) async {
    try {
      final response = await http.get(
        Uri.parse('$BaseUrl/rat/permission?key=$sessionKey&user=$username'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PermissionResult(
          isGranted: data['granted'] ?? false,
          message: data['message'] ?? '',
        );
      }
      return PermissionResult(
        isGranted: false,
        message: 'Failed to get permission',
      );
    } catch (e) {
      return PermissionResult(
        isGranted: false,
        message: 'Error: $e',
      );
    }
  }
}