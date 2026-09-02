import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  // Role Options
  final List<String> roleOptions = ['reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── TEMA HIJAU-BIRU MENYALA ─────────────────────────────────────────────
  final Color bgDark = const Color(0xFF060A0F);
  final Color bgSecondary = const Color(0xFF0A1620);
  final Color neonBlue = const Color(0xFF00D4FF);
  final Color neonGreen = const Color(0xFF39FF14);
  final Color accentCyan = const Color(0xFF00E5FF);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardGlass = const Color(0xFF0A1620);
  final Color borderGlass = const Color(0xFF1A3A4A);

  final LinearGradient neonGradient = const LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF39FF14), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient redGradient = const LinearGradient(
    colors: [Color(0xFFFF4444), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
            '$BaseUrl/listUsers?key=$sessionKey'),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("⚠️ Error", data['message'] ?? 'Tidak diizinkan melihat daftar user.');
      }
    } catch (e) {
      _alert("🌐 Error", "Gagal memuat user list: ${e.toString().replaceAll('Exception: ', '')}");
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("⚠️ Error", "Masukkan username yang ingin dihapus.");
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          '$BaseUrl/deleteUser?key=$sessionKey&username=$username',
        ),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert("✅ Berhasil", "User '${data['user']['username']}' telah dihapus.", isSuccess: true);
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (e) {
      _alert("🌐 Error", "Tidak dapat menghubungi server: ${e.toString().replaceAll('Exception: ', '')}");
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _alert("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    if (username.length < 3) {
      _alert("⚠️ Error", "Username minimal 3 karakter.");
      return;
    }

    if (password.length < 6) {
      _alert("⚠️ Error", "Password minimal 6 karakter.");
      return;
    }

    final dayInt = int.tryParse(day);
    if (dayInt == null || dayInt <= 0) {
      _alert("⚠️ Error", "Durasi harus berupa angka positif.");
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        '$BaseUrl/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("✅ Sukses", "Akun '${data['user']['username']}' berhasil dibuat.", isSuccess: true);
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (e) {
      _alert("🌐 Error", "Gagal menghubungi server: ${e.toString().replaceAll('Exception: ', '')}");
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _alert(String title, String message, {bool isSuccess = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSuccess ? neonGreen.withOpacity(0.5) : neonBlue.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? neonGreen : neonBlue,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: isSuccess ? neonGreen : neonBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: accentGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: isSuccess ? neonGradient : LinearGradient(
                  colors: [neonBlue.withOpacity(0.3), neonBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: isSuccess ? Colors.black : neonBlue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardGlass,
              const Color(0xFF0D1A2B).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: neonBlue.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'ShareTechMono',
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: neonBlue.withOpacity(0.6),
              fontSize: 11,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
            ),
            prefixIcon: Icon(
              icon,
              color: neonBlue,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? accentColor,
  }) {
    final color = accentColor ?? neonBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardGlass,
            const Color(0xFF0D1A2B).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    final isExpired = DateTime.tryParse(user['expiredDate'] ?? '')?.isBefore(DateTime.now()) ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardGlass,
            isExpired ? Colors.red.withOpacity(0.05) : const Color(0xFF0D1A2B).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpired ? Colors.red.withOpacity(0.3) : neonBlue.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isExpired
                  ? redGradient
                  : LinearGradient(
                      colors: [neonBlue, neonGreen],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isExpired ? Colors.red : neonBlue).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isExpired ? Icons.warning_amber_rounded : Icons.person,
              color: Colors.black,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            neonBlue.withOpacity(0.2),
                            neonGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['role'].toUpperCase(),
                        style: TextStyle(
                          color: neonBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Exp: ${user['expiredDate'] ?? 'N/A'}",
                      style: TextStyle(
                        color: isExpired ? Colors.red.withOpacity(0.7) : accentGrey,
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
                Text(
                  "Parent: ${user['parent'] ?? 'SYSTEM'}",
                  style: TextStyle(
                    color: accentGrey.withOpacity(0.5),
                    fontSize: 9,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: redGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black, size: 18),
              onPressed: () async {
                final confirm = await _showConfirmDialog(user['username']);
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String username) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonBlue.withOpacity(0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: neonBlue),
            const SizedBox(width: 10),
            Text(
              "Konfirmasi",
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          "Yakin ingin menghapus user '$username'?",
          style: TextStyle(
            color: accentGrey,
            fontSize: 14,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [neonBlue.withOpacity(0.3), neonBlue.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "Batal",
                    style: TextStyle(
                      color: neonBlue,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: redGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    "Hapus",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final isActive = currentPage == page;
        return GestureDetector(
          onTap: () => setState(() => currentPage = page),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: isActive
                  ? neonGradient
                  : LinearGradient(
                      colors: [
                        cardGlass,
                        const Color(0xFF0D1A2B).withOpacity(0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? neonBlue : neonBlue.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                "$page",
                style: TextStyle(
                  color: isActive ? Colors.black : accentGrey,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              const Color(0xFF0A1620),
              const Color(0xFF061020),
              bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── HEADER ──
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          neonBlue.withOpacity(0.2),
                          neonGreen.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: neonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: neonBlue.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF39FF14)],
                  ).createShader(bounds),
                  child: Text(
                    "ADMIN DASHBOARD",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: neonBlue.withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── DELETE USER ──
                _buildGlassCard(
                  title: "DELETE USER",
                  icon: FontAwesomeIcons.userSlash,
                  accentColor: Colors.red,
                  children: [
                    _buildInput(
                      label: "Target Username",
                      controller: deleteController,
                      icon: FontAwesomeIcons.user,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: redGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _deleteUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_rounded, color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "DELETE ACCOUNT",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── CREATE ACCOUNT ──
                _buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FontAwesomeIcons.userPlus,
                  accentColor: neonGreen,
                  children: [
                    _buildInput(
                      label: "Username",
                      controller: createUsernameController,
                      icon: FontAwesomeIcons.user,
                    ),
                    _buildInput(
                      label: "Password",
                      controller: createPasswordController,
                      icon: FontAwesomeIcons.lock,
                    ),
                    _buildInput(
                      label: "Duration (Days)",
                      controller: createDayController,
                      icon: FontAwesomeIcons.calendarDay,
                      type: TextInputType.number,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: neonBlue.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: newUserRole,
                          dropdownColor: bgDark,
                          style: TextStyle(
                            color: primaryWhite,
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: neonGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: neonBlue.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: neonGreen.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Text(
                                "CREATE ACCOUNT",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // ── USER MANAGEMENT ──
                _buildGlassCard(
                  title: "USER MANAGEMENT",
                  icon: FontAwesomeIcons.users,
                  accentColor: neonBlue,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: neonBlue.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: TextStyle(
                            color: primaryWhite,
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              selectedRole = val;
                              _filterAndPaginate();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: neonBlue,
                        ),
                      )
                    else if (filteredList.isEmpty)
                      Center(
                        child: Text(
                          "No users found",
                          style: TextStyle(
                            color: accentGrey,
                            fontFamily: 'ShareTechMono',
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                          const SizedBox(height: 16),
                          _buildPagination(),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}