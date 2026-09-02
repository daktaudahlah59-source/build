import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class ManageServerPage extends StatefulWidget {
  final String keyToken;
  const ManageServerPage({super.key, required this.keyToken});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  List<Map<String, dynamic>> vpsList = [];
  bool isLoading = false;

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);

  LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void initState() {
    super.initState();
    _fetchVpsList();
  }

  Future<void> _fetchVpsList() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('$apiBaseUrl/myServer?key=${widget.keyToken}');
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        vpsList = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      _showError("Gagal mengambil data VPS.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _addVps() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _showError("Isi semua field terlebih dahulu.");
      return;
    }

    final uri = Uri.parse('$apiBaseUrl/addServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
        'username': user,
        'password': pass,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _hostController.clear();
        _userController.clear();
        _passController.clear();
        _fetchVpsList();
      } else {
        _showError(data['error'] ?? 'Gagal menambah VPS');
      }
    } catch (_) {
      _showError("Gagal terhubung ke server.");
    }
  }

  Future<void> _deleteVps(String host) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        title: const Text("Konfirmasi Hapus", style: TextStyle(color: primaryWhite)),
        content: const Text("Yakin ingin menghapus VPS ini?", style: TextStyle(color: softGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("BATAL", style: TextStyle(color: softGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("HAPUS", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uri = Uri.parse('$apiBaseUrl/delServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchVpsList();
      } else {
        _showError("Gagal menghapus VPS.");
      }
    } catch (_) {
      _showError("Gagal menghubungi server.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentPurple.withOpacity(0.3)),
        ),
        title: const Text("Error", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: softGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: accentPurple)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentPurple.withOpacity(0.3)),
        ),
        title: const Text("Tambah VPS", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput("IP VPS", _hostController),
            const SizedBox(height: 12),
            _buildInput("Username", _userController),
            const SizedBox(height: 12),
            _buildInput("Password", _passController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL", style: TextStyle(color: softGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addVps();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("TAMBAH", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: primaryWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: softGrey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accentPurple.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accentPurple, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: bgDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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
              "MANAGE SERVER",
              style: TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: softPurple.withOpacity(0.2),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                           width: 4, height: 20,
                           decoration: BoxDecoration(gradient: purpleGradient, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 10),
                        const Text("My VPS List",
                            style: TextStyle(
                                fontSize: 16,
                                color: primaryWhite,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: purpleGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: accentPurple.withOpacity(0.3), blurRadius: 6)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: primaryWhite),
                        onPressed: _showAddDialog,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: accentPurple.withOpacity(0.3)),
                const SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: accentPurple))
                      : vpsList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dns_outlined, size: 60, color: softPurple.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  const Text("Belum ada VPS terdaftar", style: TextStyle(color: softGrey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: vpsList.length,
                              itemBuilder: (context, index) {
                                final vps = vpsList[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: darkPurple,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: accentPurple.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentPurple.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentPurple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.dns_rounded, color: accentPurple),
                                    ),
                                    title: Text("${vps['host']}", style: const TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
                                    subtitle: Text("User: ${vps['username']}", style: const TextStyle(color: softGrey, fontSize: 12)),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                      onPressed: () => _deleteVps(vps['host']),
                                    ),
                                  ),
                                );
                              },
                            ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}