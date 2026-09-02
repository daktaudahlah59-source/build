// shortlink_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ShortlinkPage extends StatefulWidget {
  final String sessionKey;

  const ShortlinkPage({
    super.key,
    required this.sessionKey,
  });

  @override
  State<ShortlinkPage> createState() => _ShortlinkPageState();
}

class _ShortlinkPageState extends State<ShortlinkPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _shortUrl;
  String? _errorMessage;
  List<Map<String, String>> _history = [];

  // --- TEMA SAMA DENGAN DOMAIN OSINT ---
  final Color primaryDark = Colors.black;
  final Color primaryWhite = Colors.white;
  final Color accentRed = const Color(0xFF424242);
  final Color cardDark = const Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('shortlink_history_user'); // Ganti jadi key tetap
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      setState(() {
        _history = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shortlink_history_user', jsonEncode(_history)); // Ganti jadi key tetap
  }

  Future<void> _shortenUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan URL yang ingin dipendekkan";
      });
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _errorMessage = "URL harus dimulai dengan http:// atau https://";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _shortUrl = null;
    });

    try {
      final apiUrl = "https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(url)}";
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final shortUrl = response.body.trim();
        setState(() {
          _shortUrl = shortUrl;
        });
        
        _history.insert(0, {
          'original': url,
          'short': shortUrl,
          'date': DateTime.now().toString(),
        });
        if (_history.length > 20) _history.removeLast();
        await _saveHistory();
        
        _showSnackBar("Berhasil memendekkan URL!");
      } else {
        setState(() {
          _errorMessage = "Gagal memendekkan URL";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("$label disalin ke clipboard");
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentRed),
        ),
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentRed),
        ),
        title: const Text(
          "Hapus Riwayat",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Yakin ingin menghapus semua riwayat shortlink?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _history.clear();
                _saveHistory();
              });
              Navigator.pop(context);
              _showSnackBar("Riwayat berhasil dihapus");
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text(
          'SHORTLINK URL',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentRed.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: accentRed.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      style: TextStyle(color: primaryWhite, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan URL Panjang',
                        labelStyle: TextStyle(color: primaryWhite.withOpacity(0.7)),
                        hintText: 'Contoh: https://example.com/very-long-url',
                        hintStyle: TextStyle(color: primaryWhite.withOpacity(0.4)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentRed.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentRed, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: primaryDark,
                        prefixIcon: const Icon(Icons.link, color: Color(0xFF424242)),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: accentRed,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _shortenUrl(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _shortenUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.auto_awesome, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'MEMPROSES...' : 'SHORTLINK URL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentRed),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: accentRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: primaryWhite, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Result Card
              if (_shortUrl != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentRed.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HASIL SHORTLINK',
                        style: TextStyle(
                          color: accentRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _shortUrl!,
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: accentRed, size: 20),
                              onPressed: () => _copyToClipboard(_shortUrl!, 'Shortlink'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // History Section
              if (_history.isNotEmpty) ...[
                Text(
                  'RIWAYAT SHORTLINK',
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryWhite.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['original']!,
                              style: TextStyle(
                                color: primaryWhite.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['short']!,
                                    style: TextStyle(
                                      color: accentRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: accentRed, size: 18),
                                  onPressed: () => _copyToClipboard(item['short']!, 'Shortlink'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}