import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config_github.dart';

class ChatPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const ChatPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> messages = [];
  List<String> onlineUsers = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Timer? _pollingTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String _errorMessage = '';
  String _connectionStatus = 'Terhubung';
  Color _connectionColor = Colors.green;
  bool _configLoaded = false;

  // Warna tema ungu
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFEA80FC);
  final Color lightPurple = const Color(0xFFB388FF);
  final Color bgDark = const Color(0xFF0D0221);
  final Color cardGlass = Colors.white.withOpacity(0.05);
  final Color borderGlass = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfigAndStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _configLoaded) {
      _fetchMessages();
    }
  }

  // Load config dari GitHub RAW terlebih dahulu
  Future<void> _loadConfigAndStart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pastikan config sudah di-load
      if (!ConfigGithub.isLoaded) {
        await ConfigGithub.loadConfig();
      }
      
      setState(() {
        _configLoaded = true;
      });
      
      // Setelah config loaded, start polling dan fetch messages
      _fetchMessages();
      _startPolling();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal load config server: $e';
        _connectionStatus = 'Config Error';
        _connectionColor = Colors.red;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_configLoaded) {
        _fetchMessages();
      }
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted || !_configLoaded) return;
    
    try {
      final response = await http.post(
        Uri.parse('http://capekkenaoanyak.onlinepanel.my.id:2002/get-public-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'sessionKey': widget.sessionKey,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
            onlineUsers = List<String>.from(data['online_users'] ?? []);
            _isLoading = false;
            _errorMessage = '';
            _connectionStatus = 'Terhubung';
            _connectionColor = Colors.green;
          });
          _scrollToBottom();
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat pesan';
            _connectionStatus = 'Error';
            _connectionColor = Colors.orange;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _connectionStatus = 'Server Error';
          _connectionColor = Colors.orange;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Koneksi error: $e';
        _connectionStatus = 'Offline';
        _connectionColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final msg = messageController.text.trim();
    if (msg.isEmpty || _isSending || !_configLoaded) return;

    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://capekkenaoanyak.onlinepanel.my.id:2002/send-public-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'message': msg,
          'sessionKey': widget.sessionKey,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          messageController.clear();
          await _fetchMessages(); // Refresh langsung
        } else {
          _showSnackBar('Gagal kirim: ${data['message']}', Colors.red);
        }
      } else {
        _showSnackBar('Gagal kirim: Server error', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Gagal kirim pesan: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(String? timeStr) {
    try {
      if (timeStr == null) return '';
      final time = DateTime.parse(timeStr);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghapus tanda panah kembali
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text(
          "PUBLIC CHAT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardGlass,
              border: Border(
                bottom: BorderSide(
                  color: accentPurple.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connectionColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _connectionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: accentPurple,
                        size: 8,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${onlineUsers.length} online',
                        style: TextStyle(
                          color: accentPurple,
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accentPurple),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat pesan...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty && messages.isEmpty
                    ? _buildErrorWidget()
                    : messages.isEmpty
                        ? _buildEmptyChatWidget()
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages.reversed.toList()[index];
                              final isMe = msg['username'] == widget.username;
                              return _buildMessageBubble(msg, isMe);
                            },
                          ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Terhubung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchMessages,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderGlass),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: accentPurple,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selamat datang di Public Chat!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ketik pesan pertama kamu untuk memulai percakapan',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: accentPurple, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    '${onlineUsers.length} pengguna online',
                    style: TextStyle(
                      color: accentPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardGlass,
        border: Border(
          top: BorderSide(
            color: borderGlass,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _errorMessage.isEmpty
                      ? accentPurple.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                maxLength: 500,
                enabled: _errorMessage.isEmpty && !_isSending && _configLoaded,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _errorMessage.isEmpty
                      ? 'Ketik pesan...'
                      : 'Tidak terhubung ke server',
                  hintStyle: TextStyle(
                    color: _errorMessage.isEmpty
                        ? Colors.white.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.chat,
                    color: _errorMessage.isEmpty
                        ? accentPurple.withOpacity(0.7)
                        : Colors.red.withOpacity(0.5),
                    size: 18,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: _errorMessage.isEmpty && !_isSending && _configLoaded
                  ? LinearGradient(
                      colors: [primaryPurple, accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
              onPressed: (_errorMessage.isEmpty && !_isSending && _configLoaded) ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final username = msg['username'] ?? 'Anonymous';
    final message = msg['message'] ?? '';
    final time = _formatTime(msg['time']);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [primaryPurple, accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getUserColor(username),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.black : accentPurple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 8,
                    color: isMe ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUserColor(String username) {
    final hash = username.hashCode.abs();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[hash % colors.length];
  }
}

