// bug_sender.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  // --- MODERN PURPLE THEME ---
  static const Color bgDark = Color(0xFF050510); // Latar belakang gelap keunguan
  static const Color accentPurple = Color(0xFFBB86FC); // Ungu terang utama
  static const Color darkPurple = Color(0xFF1A1025); // Ungu gelap untuk kartu
  static const Color softPurple = Color(0xFF381A4A); // Ungu sedang
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFB0B0B0);
  
  // Warna untuk aksi berbahaya (delete)
  static const Color deleteColor = Color(0xFFCF6679);

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

  bool get canAddGlobal =>
      ["owner", "developer"].contains(widget.role.toLowerCase());

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSenders();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final res = await http.get(
        Uri.parse("$apiBaseUrl/mySender?key=${widget.sessionKey}"),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        final connections = data["connections"] as List<dynamic>? ?? [];
        connections.sort((a, b) {
          final ag = a["isGlobal"] == true ? 0 : 1;
          final bg = b["isGlobal"] == true ? 0 : 1;
          if (ag != bg) return ag.compareTo(bg);
          return (a["sessionName"] ?? "").toString().compareTo(
                (b["sessionName"] ?? "").toString(),
              );
        });
        setState(() => senderList = connections);
      } else {
        setState(
          () => errorMessage = data["message"] ?? "Failed to fetch senders",
        );
      }
    } catch (e) {
      setState(() => errorMessage = "Connection failed: $e");
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  Future<void> _addSender(String number, bool isGlobal) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          "$apiBaseUrl/getPairing?key=${widget.sessionKey}&number=$number&global=${isGlobal ? 1 : 0}",
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        _showPairingDialog(number, data["pairingCode"].toString());
        _showSnackBar("Pairing code generated!", false);
      } else {
        _showSnackBar(data["message"] ?? "Failed to generate pairing code", true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", true);
    } finally {
      setState(() => isLoading = false);
      await _fetchSenders();
    }
  }

  Future<void> _deleteSender(String id, bool isGlobal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteDialog(isGlobal),
    );
    if (ok != true) return;

    setState(() => isLoading = true);
    try {
      final res = await http.delete(
        Uri.parse(
          "$apiBaseUrl/deleteSender?key=${widget.sessionKey}&id=$id&scope=${isGlobal ? 'global' : 'private'}",
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["valid"] == true) {
        _showSnackBar("Sender deleted successfully!", false);
        await _fetchSenders();
      } else {
        _showSnackBar(data["message"] ?? "Failed to delete sender", true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDeleteDialog(bool isGlobal) {
    return Dialog(
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
                child: Icon(Icons.warning_amber_rounded,
                    color: deleteColor, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirm Delete",
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isGlobal
                    ? "Global sender ini akan dihapus untuk semua user. This action cannot be undone."
                    : "Are you sure you want to delete this sender? This action cannot be undone.",
                style: const TextStyle(color: softGrey, fontSize: 13),
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
                            "CANCEL",
                            style:
                                TextStyle(color: softGrey, fontWeight: FontWeight.w600),
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
                        child: Center(
                          child: Text(
                            "DELETE",
                            style: TextStyle(
                                color: deleteColor, fontWeight: FontWeight.w600),
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
    );
  }

  void _showAddDialog() {
    final phoneController = TextEditingController();
    bool isGlobal = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Dialog(
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
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
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
                        child: const Icon(Icons.phone_android,
                            color: primaryWhite, size: 28),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Add New Sender",
                        style: TextStyle(
                          color: primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter phone number to add new WhatsApp sender",
                        style: TextStyle(color: softGrey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: primaryWhite, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "62xxxxxxxxxx",
                            hintStyle: TextStyle(color: softGrey.withOpacity(0.5)),
                            prefixIcon:
                                const Icon(Icons.phone, color: accentPurple, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      if (canAddGlobal) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryWhite.withOpacity(0.1)),
                          ),
                          child: SwitchListTile(
                            value: isGlobal,
                            onChanged: (v) => setLocal(() => isGlobal = v),
                            title: const Text(
                              "Global Sender",
                              style: TextStyle(color: primaryWhite),
                            ),
                            subtitle: const Text(
                              "Tambah global sender untuk semua role",
                              style: TextStyle(color: softGrey, fontSize: 12),
                            ),
                            activeColor: accentPurple,
                            inactiveThumbColor: Colors.grey,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Center(
                                  child: Text(
                                    "CANCEL",
                                    style: TextStyle(
                                        color: softGrey, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final number = phoneController.text.trim();
                                if (number.isEmpty) {
                                  _showSnackBar("Please enter phone number", true);
                                  return;
                                }
                                if (isGlobal && !canAddGlobal) {
                                  _showSnackBar(
                                    "Hanya owner & developer yang dapat menambahkan Global Sender.",
                                    true,
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                await _addSender(number, isGlobal);
                              },
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
                                    "ADD SENDER",
                                    style: TextStyle(
                                        color: primaryWhite, fontWeight: FontWeight.w600),
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
            );
          },
        );
      },
    );
  }

  void _showPairingDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
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
                  child: const Icon(Icons.qr_code_2, color: primaryWhite, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pairing Required",
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Number: $number",
                  style: const TextStyle(color: softGrey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentPurple.withOpacity(0.1), darkPurple.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentPurple.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Pairing Code",
                        style: TextStyle(color: softGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentPurple, width: 2),
                        ),
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            color: accentPurple,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          _showSnackBar("Code copied to clipboard!", false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: accentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentPurple.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy, color: accentPurple, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                "COPY CODE",
                                style: TextStyle(
                                    color: accentPurple, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Center(
                            child: Text(
                              "CLOSE",
                              style: TextStyle(
                                  color: softGrey, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _refreshSenders();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                              "REFRESH",
                              style: TextStyle(
                                  color: primaryWhite, fontWeight: FontWeight.w600),
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
  }

  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: primaryWhite,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: primaryWhite, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? deleteColor.withOpacity(0.9) : accentPurple.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender["sessionName"] ?? "WhatsApp Sender";
    final id = (sender["id"] ?? name).toString();
    final isGlobal = sender["isGlobal"] == true;
    final canDelete = sender["canDelete"] != false;
    final isEven = index % 2 == 0;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEven
                ? [glassPrimary, glassSecondary]
                : [glassSecondary, glassPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryWhite.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Icon(
                      isGlobal ? Icons.public : Icons.phone_android,
                      color: primaryWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: $id",
                          style: const TextStyle(color: softGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isGlobal ? accentPurple : softPurple).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (isGlobal ? accentPurple : softPurple).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isGlobal ? accentPurple : softPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGlobal ? "GLOBAL" : "PRIVATE",
                          style: TextStyle(
                            color: isGlobal ? accentPurple : softPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _refreshSenders,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentPurple.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh, color: accentPurple, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "REFRESH",
                              style: TextStyle(
                                  color: accentPurple, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: canDelete ? () => _deleteSender(id, isGlobal) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: canDelete
                              ? deleteColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: canDelete
                                ? deleteColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canDelete ? Icons.delete_outline : Icons.lock_outline,
                              color: canDelete ? deleteColor : softGrey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canDelete ? "DELETE" : "LOCKED",
                              style: TextStyle(
                                color: canDelete ? deleteColor : softGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [glassPrimary, glassSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryWhite.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: primaryWhite, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Global sender hanya bisa ditambah owner/developer, tapi semua role bisa memakai global sender.",
              style: TextStyle(color: softGrey, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentPurple.withOpacity(0.1), darkPurple.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentPurple.withOpacity(0.2)),
                ),
                child: const Icon(Icons.phone_iphone, color: accentPurple, size: 70),
              ),
              const SizedBox(height: 28),
              const Text(
                "No Senders Found",
                style: TextStyle(
                    color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Add your first WhatsApp sender to get started",
                style: TextStyle(color: softGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _showAddDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: purpleGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: primaryWhite, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        "ADD NEW SENDER",
                        style: TextStyle(
                          color: primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: deleteColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: deleteColor, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              "Failed to Load",
              style: TextStyle(
                  color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: const TextStyle(color: softGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _refreshSenders,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: purpleGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: primaryWhite, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      "TRY AGAIN",
                      style: TextStyle(
                        color: primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
      backgroundColor: bgDark,
      appBar: AppBar(
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            "BUG SENDER",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: AnimatedRotation(
                turns: isRefreshing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Icon(Icons.refresh, color: accentPurple, size: 20),
              ),
              onPressed: isLoading ? null : _refreshSenders,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: purpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: primaryWhite, size: 20),
              onPressed: _showAddDialog,
            ),
          ),
        ],
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: isLoading && senderList.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: accentPurple,
                      strokeWidth: 3,
                    ),
                  )
                : errorMessage != null && senderList.isEmpty
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildInfoBanner(),
                      Expanded(
                        child: senderList.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: accentPurple,
                                backgroundColor: glassSecondary,
                                onRefresh: _refreshSenders,
                                child: ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: senderList.length,
                                  itemBuilder: (context, index) => _buildSenderCard(
                                    Map<String, dynamic>.from(senderList[index]),
                                    index,
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
}

// Custom Grid Painter for background (Updated with Purple accent)
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