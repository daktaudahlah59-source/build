import 'dart:convert';
import 'package:http/http.dart' as http;

class ConfigGithub {
  // Ganti URL ini dengan URL RAW GitHub Anda yang berisi file config.json
  static const String configUrl = "https://raw.githubusercontent.com/DewaVerse/BaseUrl/main/config.json";
  
  static String baseUrl = "";
  static bool isLoaded = false;
  
  static Future<void> loadConfig() async {
    try {
      final response = await http.get(Uri.parse(configUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        baseUrl = data['server_url'];
        isLoaded = true;
      } else {
        throw Exception('Gagal load config dari GitHub: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error load config dari GitHub: $e');
    }
  }
  
  static String getBaseUrl() {
    if (!isLoaded) {
      throw Exception('Config belum di-load, panggil loadConfig() terlebih dahulu');
    }
    return baseUrl;
  }
}