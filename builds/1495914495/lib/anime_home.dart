import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// --- CONFIG & THEME (PURPLE THEME) ---
const String jikanBaseUrl = "https://api.jikan.moe/v4";
const String videoSearchApi = "https://api.siputzx.my.id/api/s/youtube";

// Palette Warna (Ungu - Hitam)
final Color deepPurple = const Color(0xFF6A1B9A);   // Ungu gelap
final Color mainPurple = const Color(0xFF9C27B0);   // Ungu utama
final Color accentPurple = const Color(0xFFBA68C8); // Ungu aksen
final Color bgBlack = const Color(0xFF000000);    // Hitam background
final Color cardBlack = const Color(0xFF0F0F0F);  // Hitam card

// --- MODEL ---
class Anime {
  final int malId;
  final String title;
  final String imageUrl;
  final double? score;
  final String? type;
  final int? year;
  final int? episodes;
  final String? status;
  final String? synopsis;
  final List<String> genres;
  final String? trailerUrl;

  Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.score,
    this.type,
    this.year,
    this.episodes,
    this.status,
    this.synopsis,
    required this.genres,
    this.trailerUrl,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'] ?? json['title_english'] ?? json['title_japanese'] ?? 'No Title',
      imageUrl: json['images']?['jpg']?['large_image_url'] ?? json['poster'] ?? '',
      score: json['score']?.toDouble(),
      type: json['type'],
      year: json['year'],
      episodes: json['episodes'],
      status: json['status'],
      synopsis: json['synopsis'],
      genres: (json['genres'] as List?)?.map((e) => e['name'].toString()).toList() ?? [],
      trailerUrl: json['trailer']?['youtube_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mal_id': malId,
      'title': title,
      'poster': imageUrl,
      'slug': 'anime-$malId',
    };
  }
}

class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Anime> _animeList = [];
  List<Anime> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _activeCategory = "Top Airing";
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  final List<String> _categories = ["Top Airing", "Upcoming", "Popular", "Action", "Romance", "Drama", "Fantasy"];

  @override
  void initState() {
    super.initState();
    _fetchAnime(); 
    _loadWatchHistory();
  }

  // Callback function to refresh history when updated from other pages
  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _fetchAnime({String? query}) async {
    setState(() {
      _isLoading = true;
      _isSearching = query != null && query.isNotEmpty;
    });
    
    try {
      String url;
      if (query != null && query.isNotEmpty) {
        url = "$jikanBaseUrl/anime?q=$query&sfw=true&page=1&limit=20";
      } else {
        String filter = "bypopularity";
        if (_activeCategory == "Top Airing") filter = "airing";
        if (_activeCategory == "Upcoming") filter = "upcoming";
        
        url = "$jikanBaseUrl/top/anime?filter=$filter&page=1&limit=20";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          if (_isSearching) {
            _searchResults = data.map((e) => Anime.fromJson(e)).toList();
          } else {
            _animeList = data.map((e) => Anime.fromJson(e)).toList();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching anime: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black, deepPurple.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: mainPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: deepPurple.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("ANIME STATION", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                        SizedBox(height: 5),
                        Text("Stream Unlimited Anime", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.movie_filter_rounded, color: accentPurple, size: 40),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: mainPurple.withOpacity(0.1), blurRadius: 10)],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: accentPurple,
                  decoration: InputDecoration(
                    hintText: "Search anime...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: mainPurple),
                    filled: true,
                    fillColor: cardBlack,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: mainPurple.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentPurple, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: mainPurple),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                  onSubmitted: (val) => _fetchAnime(query: val),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Category Chips (hanya tampil jika tidak sedang search)
            if (!_isSearching)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = _activeCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeCategory = cat;
                          _searchController.clear();
                        });
                        _fetchAnime();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? mainPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? accentPurple : Colors.white24),
                          boxShadow: isActive ? [BoxShadow(color: deepPurple, blurRadius: 8)] : [],
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // Content Area
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _isSearching
                      ? _buildSearchResults()
                      : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _fetchAnime(),
          _loadWatchHistory(),
        ]);
      },
      color: mainPurple,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch History Section
            _buildSectionHeader(Icons.history, "Watch History"),
            const SizedBox(height: 12),

            // Show loading shimmer for history
            if (_isHistoryLoading)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: cardBlack,
                        highlightColor: deepPurple.withOpacity(0.2),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_watchHistory.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                child: const Text(
                  "No watch history yet. Start watching an anime!",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final anime = _watchHistory[index];
                    return _buildHistoryCard(anime);
                  },
                ),
              ),

            // Quick Access Section
            _buildSectionHeader(Icons.dashboard, "Quick Access"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    "Genre",
                    Icons.category,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeGenreListPage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    "Schedule",
                    Icons.schedule,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeSchedulePage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Currently Airing Section
            _buildSectionHeader(Icons.live_tv, "Currently Airing"),
            const SizedBox(height: 12),
            _buildAnimeGrid(_animeList),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: accentPurple, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                anime: Anime(
                  malId: int.parse(anime['slug'].toString().replaceAll('anime-', '')),
                  title: anime['title'],
                  imageUrl: anime['poster'],
                  genres: [],
                ),
              ),
            ),
          ).then((_) => refreshHistory());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: anime['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: cardBlack),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      width: 120,
                      color: cardBlack,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                    child: Text(
                      anime['last_watched_episode'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              anime['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "No results found",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try with different keywords",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final anime = _searchResults[index];
        return _buildSearchResultCard(anime);
      },
    );
  }

  Widget _buildSearchResultCard(Anime anime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainPurple.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(anime: anime),
            ),
          ).then((_) => refreshHistory());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: cardBlack),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: cardBlack,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      anime.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating and Type
                    Row(
                      children: [
                        if (anime.score != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                anime.score.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (anime.type != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mainPurple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              anime.type!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Status and Episode
                    Row(
                      children: [
                        if (anime.status != null) ...[
                          Text(
                            anime.status!,
                            style: TextStyle(
                              color: _getStatusColor(anime.status!),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (anime.episodes != null) ...[
                          Text(
                            "${anime.episodes} Episodes",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Genres
                    if (anime.genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: anime.genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cardBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: mainPurple),
                            ),
                            child: Text(
                              genre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimeGrid(List<Anime> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final anime = list[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(anime: anime),
              ),
            ).then((_) => refreshHistory());
          },
          child: _buildAnimeCard(anime),
        );
      },
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainPurple.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: anime.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: cardBlack),
                errorWidget: (context, url, error) => Container(color: cardBlack, child: const Icon(Icons.error, color: Colors.white)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            if (anime.score != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: deepPurple.withOpacity(0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: accentPurple.withOpacity(0.5))),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 10, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Text(anime.score!.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${anime.type ?? 'TV'} • ${anime.year ?? '?'}",
                    style: TextStyle(color: accentPurple, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: cardBlack,
      highlightColor: deepPurple.withOpacity(0.2),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15))),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// ==========================================
// DETAIL PAGE (Info & Trailer)
// ==========================================
class AnimeDetailPage extends StatefulWidget {
  final Anime anime;
  final Function()? onHistoryUpdate;

  const AnimeDetailPage({super.key, required this.anime, this.onHistoryUpdate});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  YoutubePlayerController? _trailerController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.anime.trailerUrl != null) {
      _trailerController = YoutubePlayerController(
        initialVideoId: widget.anime.trailerUrl!,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false, forceHD: true),
      );
    }
  }

  @override
  void dispose() {
    _trailerController?.dispose();
    super.dispose();
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson
          .map((item) => Map<String, dynamic>.from(json.decode(item)))
          .toList();

      // Create history item
      final historyItem = {
        'slug': 'anime-${widget.anime.malId}',
        'title': widget.anime.title,
        'poster': widget.anime.imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Remove if already exists to avoid duplicates
      watchHistory.removeWhere((item) => item['slug'] == 'anime-${widget.anime.malId}');

      // Add to beginning of list
      watchHistory.insert(0, historyItem);

      // Keep only last 20 items
      if (watchHistory.length > 20) {
        watchHistory = watchHistory.sublist(0, 20);
      }

      // Save to preferences
      final newHistoryJson = watchHistory.map((item) => json.encode(item)).toList();
      await prefs.setStringList('watch_history', newHistoryJson);

      // Trigger history update callback if provided
      if (widget.onHistoryUpdate != null) {
        widget.onHistoryUpdate!();
      }
    } catch (e) {
      debugPrint('Error saving to watch history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            backgroundColor: bgBlack,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(50), border: Border.all(color: mainPurple)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: widget.anime.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [bgBlack, Colors.transparent, bgBlack],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.anime.title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: widget.anime.genres.take(3).map((g) => 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: deepPurple.withOpacity(0.3), 
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: mainPurple)
                              ),
                              child: Text(g, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SYNOPSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(
                    widget.anime.synopsis ?? "No synopsis available.",
                    style: const TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // Anime Info
                  _buildInfoItem('Type', widget.anime.type ?? '-'),
                  _buildInfoItem('Status', widget.anime.status ?? '-'),
                  _buildInfoItem('Episodes', widget.anime.episodes?.toString() ?? '-'),
                  _buildInfoItem('Year', widget.anime.year?.toString() ?? '-'),
                  _buildInfoItem('Score', widget.anime.score?.toString() ?? '-'),

                  if (_trailerController != null) ...[
                    const SizedBox(height: 30),
                    const Text("TRAILER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainPurple.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: YoutubePlayer(
                          controller: _trailerController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: accentPurple,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // WATCH NOW BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _addToWatchHistory();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnimeStreamPage(anime: widget.anime),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [deepPurple, accentPurple]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: mainPurple.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill, size: 28, color: Colors.white),
                              SizedBox(width: 10),
                              Text("WATCH EPISODES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STREAMING PAGE (Updated with Better Search)
// ==========================================
class AnimeStreamPage extends StatefulWidget {
  final Anime anime;
  const AnimeStreamPage({super.key, required this.anime});

  @override
  State<AnimeStreamPage> createState() => _AnimeStreamPageState();
}

class _AnimeStreamPageState extends State<AnimeStreamPage> {
  YoutubePlayerController? _ytController;
  bool _isSearching = true;
  String? _errorMsg;
  int _currentEpisode = 1;
  int _totalEpisodes = 24;

  @override
  void initState() {
    super.initState();
    _totalEpisodes = widget.anime.episodes ?? 24;
    if (_totalEpisodes > 200) _totalEpisodes = 200; 
    _searchVideo();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _searchVideo() async {
    if (mounted) {
      setState(() {
        _isSearching = true;
        _errorMsg = null;
        _ytController?.pause();
      });
    }
    
    // --- QUERY VARIATIONS ---
    final queries = [
      "${widget.anime.title} Episode $_currentEpisode Subtitle Indonesia",
      "${widget.anime.title} Episode $_currentEpisode Sub Indo",
      "${widget.anime.title} Episode $_currentEpisode",
      "${widget.anime.title} Ep $_currentEpisode",
      "${widget.anime.title} Episode $_currentEpisode Eng Sub",
    ];

    bool found = false;

    for (String query in queries) {
      if (found) break;

      try {
        debugPrint("🔍 Searching: $query");

        final response = await http.post(
          Uri.parse(videoSearchApi),
          body: jsonEncode({"query": query}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['data'] != null && (data['data'] as List).isNotEmpty) {
            var firstResult = data['data'][0];
            
            String? videoId;
            if (firstResult['videoId'] != null) {
              videoId = firstResult['videoId'];
            } else if (firstResult['id'] != null) {
              videoId = firstResult['id'];
            } else if (firstResult['url'] != null) {
              videoId = YoutubePlayer.convertUrlToId(firstResult['url']);
            }

            if (videoId != null && videoId.isNotEmpty) {
              _initPlayer(videoId);
              found = true;
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Error searching query '$query': $e");
      }
    }

    if (mounted) {
      if (!found) {
        setState(() {
          _isSearching = false;
          _errorMsg = "Episode $_currentEpisode tidak ditemukan di YouTube.\nMungkin terkena Copyright.";
        });
      } else {
        setState(() {
          _isSearching = false;
          _errorMsg = null;
        });
      }
    }
  }

  void _initPlayer(String videoId) {
    if (_ytController != null) {
      _ytController!.load(videoId);
    } else {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          forceHD: true,
          enableCaption: true,
          hideControls: false, 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: SafeArea(
        child: Column(
          children: [
            // --- VIDEO PLAYER CONTAINER ---
            Container(
              height: 250, 
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isSearching)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: accentPurple),
                        const SizedBox(height: 10),
                        const Text("Searching video...", style: TextStyle(color: Colors.white54, fontSize: 12))
                      ],
                    )
                  else if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  else
                    YoutubePlayer(
                      controller: _ytController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: accentPurple,
                      progressColors: ProgressBarColors(
                        playedColor: accentPurple,
                        handleColor: accentPurple,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white10
                      ),
                    ),
                  
                  // Tombol Back Custom
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- EPISODE GRID & STATS ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EPISODE $_currentEpisode",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Orbitron'),
                    ),
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(Icons.remove_red_eye, "1.2M"),
                        _statItem(Icons.thumb_up, "85K"),
                        _statItem(Icons.trending_up, "#3 Trending"),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    // Grid Episodes
                    const Text("ALL EPISODES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _totalEpisodes,
                      itemBuilder: (context, index) {
                        final epNum = index + 1;
                        final isSelected = epNum == _currentEpisode;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? mainPurple : cardBlack,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: isSelected ? accentPurple : Colors.white24)
                            ),
                          ),
                          onPressed: () {
                            if (!isSelected) {
                              setState(() => _currentEpisode = epNum);
                              _searchVideo();
                            }
                          },
                          child: Text("$epNum"),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: accentPurple, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==========================================
// PAGES YANG TIDAK PERLU DIUBAH (Tetap menggunakan API lama)
// ==========================================
class AnimeGenrePage extends StatefulWidget {
  final String genreSlug;
  final String genreName;

  const AnimeGenrePage({
    super.key,
    required this.genreSlug,
    required this.genreName,
  });

  @override
  State<AnimeGenrePage> createState() => _AnimeGenrePageState();
}

class _AnimeGenrePageState extends State<AnimeGenrePage> {
  List<dynamic> animeList = [];
  Map<String, dynamic>? pagination;
  bool isLoading = true;
  bool isError = false;
  int currentPage = 1;

  Future<void> fetchGenreAnime({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/anime?genres=${widget.genreSlug}&page=$page'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeList = jsonData['data'];
          pagination = jsonData['pagination'];
          isLoading = false;
          currentPage = page;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: Text(
          "Genre: ${widget.genreName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgBlack,
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "Failed to load genre data",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => fetchGenreAnime(),
              child: const Text("Try Again"),
            ),
          ],
        ),
      )
          : _buildGenreContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardBlack,
          highlightColor: deepPurple.withOpacity(0.2),
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenreContent() {
    return Column(
      children: [
        // Pagination Info
        if (pagination != null) _buildPaginationInfo(),

        // Anime List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return _buildAnimeCard(anime);
            },
          ),
        ),

        // Pagination Controls
        if (pagination != null) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainPurple),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Page $currentPage of ${pagination!['last_visible_page']}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            "Total: ${animeList.length} anime",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final hasNext = pagination!['has_next_page'] ?? false;
    final hasPrev = currentPage > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          if (hasPrev)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage - 1),
              style: ElevatedButton.styleFrom(backgroundColor: mainPurple),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text("Previous"),
                ],
              ),
            ),

          const SizedBox(width: 16),

          // Next Button
          if (hasNext)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage + 1),
              style: ElevatedButton.styleFrom(backgroundColor: mainPurple),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next"),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final String title = anime['title'] ?? anime['title_english'] ?? anime['title_japanese'] ?? 'No Title';
    final String poster = anime['images']?['jpg']?['large_image_url'] ?? '';
    final double rating = anime['score']?.toDouble() ?? 0;
    final int episodeCount = anime['episodes'] ?? 0;
    final String synopsis = anime['synopsis'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainPurple.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                anime: Anime.fromJson(anime),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: poster,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: cardBlack),
                  errorWidget: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: cardBlack,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Rating and Episode
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$episodeCount Episodes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Synopsis (short)
                    if (synopsis.isNotEmpty) ...[
                      Text(
                        synopsis.length > 100 ? '${synopsis.substring(0, 100)}...' : synopsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimeSchedulePage extends StatefulWidget {
  const AnimeSchedulePage({super.key});

  @override
  State<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends State<AnimeSchedulePage> {
  List<dynamic> scheduleData = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/schedules'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          scheduleData = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: const Text(
          "Release Schedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgBlack,
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? _buildErrorWidget()
          : _buildScheduleContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardBlack,
          highlightColor: deepPurple.withOpacity(0.2),
          child: Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            "Failed to load release schedule",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchSchedule,
            style: ElevatedButton.styleFrom(backgroundColor: mainPurple),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    // Group by day
    final Map<String, List<dynamic>> groupedByDay = {};
    for (final anime in scheduleData) {
      final day = anime['broadcast']['day'] ?? 'Unknown';
      if (!groupedByDay.containsKey(day)) {
        groupedByDay[day] = [];
      }
      groupedByDay[day]!.add(anime);
    }

    final List<MapEntry<String, List<dynamic>>> dayEntries = groupedByDay.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: dayEntries.length,
      itemBuilder: (context, index) {
        final daySchedule = dayEntries[index];
        final String day = daySchedule.key;
        final List<dynamic> animeList = daySchedule.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mainPurple),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: mainPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${animeList.length} Anime",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Anime List
                if (animeList.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: animeList.length,
                      itemBuilder: (context, animeIndex) {
                        final anime = animeList[animeIndex];
                        final String title = anime['title'] ?? anime['title_english'] ?? anime['title_japanese'] ?? 'No Title';
                        final String poster = anime['images']?['jpg']?['large_image_url'] ?? '';

                        return Container(
                          width: 120,
                          margin: EdgeInsets.only(
                            right: animeIndex == animeList.length - 1 ? 0 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimeDetailPage(
                                    anime: Anime.fromJson(anime),
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Poster
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: poster,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: cardBlack),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 120,
                                      height: 160,
                                      color: cardBlack,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Title
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimeGenreListPage extends StatefulWidget {
  const AnimeGenreListPage({super.key});

  @override
  State<AnimeGenreListPage> createState() => _AnimeGenreListPageState();
}

class _AnimeGenreListPageState extends State<AnimeGenreListPage> {
  List<dynamic> genreList = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchGenreList() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/genres/anime'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          genreList = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching genre list: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: const Text(
          "Anime Genres",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgBlack,
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? _buildErrorWidget()
          : _buildGenreGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardBlack,
          highlightColor: deepPurple.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            "Failed to load genre list",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchGenreList,
            style: ElevatedButton.styleFrom(backgroundColor: mainPurple),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: genreList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        final genre = genreList[index];
        final String name = genre['name'];
        final int id = genre['mal_id'];

        return Container(
          decoration: BoxDecoration(
            color: cardBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mainPurple),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeGenrePage(
                    genreSlug: id.toString(),
                    genreName: name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(
      color: cardBlack,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: mainPurple),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: accentPurple, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}