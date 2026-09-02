import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'config.dart';

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const OwnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['owner', 'vip', 'reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);
  static const Color glassPrimary = Color(0x1ABB86FC);
  static const Color glassSecondary = Color(0x0DBB86FC);
  static const Color deleteColor = Color(0xFFCF6679); // Merah muda lembut untuk hapus

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
    }
    setState(() => isLoading = false);
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
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$apiBaseUrl/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses", "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$apiBaseUrl/editUser?key=$sessionKey&username=$u&addDays=$d',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        _alert("Sukses", "Durasi berhasil diperbarui.");
        editUsernameController.clear();
        editDayController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal mengubah durasi.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                  child: Icon(
                    title == "Sukses" ? Icons.check_circle : Icons.warning_rounded,
                    color: primaryWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: softGrey, fontSize: 14),
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
                            color: primaryWhite,
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: glassSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryWhite.withOpacity(0.1)),
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: primaryWhite),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: softGrey),
            prefixIcon: Icon(icon, color: accentPurple, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: glassPrimary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryWhite.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: accentPurple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    gradient: purpleGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: primaryWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: glassSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryWhite.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: purpleGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                user['username'][0].toUpperCase(),
                style: const TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: const TextStyle(
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentPurple.withOpacity(0.3)),
                        ),
                        child: Text(
                          user['role'].toString().toUpperCase(),
                          style: TextStyle(
                            color: accentPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Exp: ${user['expiredDate']}",
                        style: const TextStyle(color: softGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => Dialog(
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
                          border: Border.all(color: deleteColor.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: deleteColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: deleteColor.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: deleteColor, size: 32),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Konfirmasi Hapus",
                              style: TextStyle(
                                color: primaryWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Hapus user ${user['username']}?",
                              style: const TextStyle(color: softGrey, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "BATAL",
                                          style: TextStyle(color: softGrey, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: deleteColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: deleteColor.withOpacity(0.3)),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "HAPUS",
                                          style: TextStyle(color: deleteColor, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: deleteColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: deleteColor.withOpacity(0.2)),
                ),
                child: Icon(Icons.delete_outline, color: deleteColor, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return GestureDetector(
          onTap: () => setState(() => currentPage = page),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: currentPage == page ? purpleGradient : null,
              color: currentPage == page ? null : glassSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: currentPage == page ? accentPurple : primaryWhite.withOpacity(0.1),
              ),
            ),
            child: Text(
              "$page",
              style: TextStyle(
                color: currentPage == page ? primaryWhite : softGrey,
                fontSize: 12,
                fontWeight: currentPage == page ? FontWeight.bold : FontWeight.normal,
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
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: purpleGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            "OWNER DASHBOARD",
            style: TextStyle(
              color: primaryWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: accentPurple, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(scale: value, child: child),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: purpleGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentPurple.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.workspace_premium,
                              color: primaryWhite,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => purpleGradient.createShader(bounds),
                          child: const Text(
                            "OWNER PANEL",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DELETE USER
                  _buildGlassCard(
                    title: "DELETE USER",
                    icon: FontAwesomeIcons.userSlash,
                    children: [
                      _buildInput(
                        label: "Username Target",
                        controller: deleteController,
                        icon: FontAwesomeIcons.user,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A004E), Color(0xFF45006A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: deleteColor.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _deleteUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete, size: 18, color: primaryWhite),
                              SizedBox(width: 8),
                              Text(
                                "DELETE ACCOUNT",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: primaryWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // CREATE ACCOUNT
                  _buildGlassCard(
                    title: "CREATE ACCOUNT",
                    icon: FontAwesomeIcons.userPlus,
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
                        label: "Durasi (Hari)",
                        controller: createDayController,
                        icon: FontAwesomeIcons.calendarDay,
                        type: TextInputType.number,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: newUserRole,
                            dropdownColor: bgDark,
                            style: const TextStyle(color: primaryWhite),
                            items: roleOptions.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => newUserRole = val ?? 'member'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 50,
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
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryWhite,
                                  ),
                                )
                              : const Text(
                                  "CREATE ACCOUNT",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // EXTEND DURATION
                  _buildGlassCard(
                    title: "EXTEND DURATION",
                    icon: FontAwesomeIcons.clock,
                    children: [
                      _buildInput(
                        label: "Username Target",
                        controller: editUsernameController,
                        icon: FontAwesomeIcons.userEdit,
                      ),
                      _buildInput(
                        label: "Tambah Hari",
                        controller: editDayController,
                        icon: FontAwesomeIcons.calendarPlus,
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
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
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _editUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryWhite,
                                  ),
                                )
                              : const Text(
                                  "ADD DAYS",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // USER LIST
                  _buildGlassCard(
                    title: "USER LIST",
                    icon: FontAwesomeIcons.users,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            dropdownColor: bgDark,
                            style: const TextStyle(color: primaryWhite),
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
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: accentPurple,
                                strokeWidth: 3,
                              ),
                            )
                          : Column(
                              children: [
                                ..._getCurrentPageData()
                                    .map((u) => _buildUserItem(u))
                                    .toList(),
                                const SizedBox(height: 16),
                                _buildPagination(),
                              ],
                            ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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