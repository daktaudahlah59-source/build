// instagram_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InstagramDownloaderPage extends StatefulWidget {
  const InstagramDownloaderPage({super.key});

  @override
  State<InstagramDownloaderPage> createState() => _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  List<dynamic>? _mediaData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

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
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL Instagram tidak boleh kosong.";
        _mediaData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final encodedUrl = Uri.encodeComponent(url);
    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/igdl?url=$encodedUrl");

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _mediaData = json['data'];
          });
          _initializeVideoPlayer();
        } else {
          setState(() {
            _errorMessage = "Gagal mengambil data Instagram.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    if (_mediaData != null && _mediaData!.isNotEmpty) {
      final mediaUrl = _mediaData![0]['url'];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              showControls: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: accentPurple,
                handleColor: softPurple,
                backgroundColor: softGrey.withOpacity(0.3),
                bufferedColor: softGrey.withOpacity(0.2),
              ),
            );
          });
        });
    }
  }

  Future<void> _shareVideo() async {
    if (_mediaData == null || _mediaData!.isEmpty) return;

    try {
      final mediaUrl = _mediaData![0]['url'];
      final response = await http.get(Uri.parse(mediaUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/instagram_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)],
        text: 'Video Instagram',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e', style: TextStyle(color: primaryWhite)),
          backgroundColor: darkPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildMediaGrid() {
    if (_mediaData == null) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaData!.length,
      itemBuilder: (context, index) {
        final media = _mediaData![index];
        final isVideo = media['type'] == 'video';

        return GestureDetector(
          onTap: () {
            if (isVideo) {
              _playVideo(media['url']);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: darkPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentPurple.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: isVideo
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          media['thumbnail'] ?? media['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Icon(Icons.videocam, color: accentPurple),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.play_arrow, color: primaryWhite, size: 16),
                          ),
                        ),
                      ],
                    )
                        : Image.network(
                      media['url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Icon(Icons.photo, color: accentPurple),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.photo,
                        color: accentPurple,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVideo ? 'Video' : 'Photo',
                        style: TextStyle(
                          color: primaryWhite,
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
      },
    );
  }

  void _playVideo(String videoUrl) {
    _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: accentPurple,
              handleColor: softPurple,
              backgroundColor: softGrey.withOpacity(0.3),
              bufferedColor: softGrey.withOpacity(0.2),
            ),
          );
        });
      });
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
            "INSTAGRAM DOWNLOADER",
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              color: primaryWhite,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryWhite),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkPurple,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentPurple.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withOpacity(0.2),
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
                        labelText: 'Masukkan URL Instagram',
                        labelStyle: TextStyle(color: softGrey),
                        hintText: 'Contoh: https://www.instagram.com/reel/xxx/',
                        hintStyle: TextStyle(color: softGrey.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentPurple.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: accentPurple, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: bgDark,
                        prefixIcon: Icon(Icons.camera_alt, color: accentPurple),
                        suffixIcon: _isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: accentPurple,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _downloadInstagram,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: purpleGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accentPurple.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isLoading ? Icons.hourglass_top : Icons.download, color: primaryWhite, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading ? 'PROSES...' : 'DOWNLOAD',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    color: primaryWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                    color: darkPurple,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade300),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (_chewieController != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkPurple,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentPurple.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: accentPurple.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: primaryWhite, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "VIDEO PLAYER",
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentPurple.withOpacity(0.5)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Chewie(controller: _chewieController!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _shareVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: softPurple,
                            foregroundColor: primaryWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'SHARE VIDEO',
                                style: TextStyle(
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

              if (_mediaData != null && _chewieController == null)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library, color: primaryWhite, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "MEDIA GALLERY (${_mediaData!.length})",
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildMediaGrid(),
                      ),
                    ],
                  ),
                ),

              if (_mediaData == null && !_isLoading && _errorMessage == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: accentPurple.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Instagram Downloader',
                          style: TextStyle(
                            color: softGrey,
                            fontSize: 18,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Masukkan URL Instagram Reel, Post, atau Story untuk mendownload media',
                            style: TextStyle(
                              color: softGrey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
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
}