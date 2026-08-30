// country_negara.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CountryInfoPage extends StatefulWidget {
  const CountryInfoPage({super.key});

  @override
  State<CountryInfoPage> createState() => _CountryInfoPageState();
}

class _CountryInfoPageState extends State<CountryInfoPage> {
  final TextEditingController _countryController = TextEditingController();
  Map<String, dynamic>? _countryData;
  bool _isLoading = false;
  String? _errorMessage;

  // Warna tema hitam ungu - pindahkan ke dalam method
  Color get primaryDark => Colors.black;
  Color get primaryPurple => const Color(0xFF7B1FA2);
  Color get accentPurple => const Color(0xFFAA00FF);
  Color get lightPurple => const Color(0xFFE040FB);
  Color get primaryWhite => Colors.white;
  Color get cardDark => const Color(0xFF1A1A1A);

  Future<void> _checkCountryInfo() async {
    String countryName = _countryController.text.trim();
    
    if (countryName.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan nama negara';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _countryData = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.siputzx.my.id/api/tools/countryInfo?name=${Uri.encodeComponent(countryName)}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          setState(() {
            _countryData = jsonData['data'];
          });
        } else {
          setState(() {
            _errorMessage = 'Negara tidak ditemukan';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text('Country Info'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple, accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryPurple.withOpacity(0.3),
                      accentPurple.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryPurple.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.public, color: lightPurple, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'CEK INFORMASI NEGARA',
                          style: TextStyle(
                            color: primaryWhite,
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: primaryPurple.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _countryController,
                        style: TextStyle(color: primaryWhite),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama negara...',
                          hintStyle: TextStyle(color: primaryWhite.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search, color: lightPurple),
                          filled: true,
                          fillColor: cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _checkCountryInfo(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkCountryInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: primaryPurple.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: primaryWhite,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'MENCARI...',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'CEK NEGARA',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Country Info Display
              if (_countryData != null) ...[
                const SizedBox(height: 20),
                _buildCountryHeader(),
                const SizedBox(height: 16),
                _buildInfoGrid(),
                const SizedBox(height: 16),
                if (_countryData!['neighbors'] != null && 
                    (_countryData!['neighbors'] as List).isNotEmpty)
                  _buildNeighborsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryPurple.withOpacity(0.4),
            accentPurple.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Flag
          if (_countryData!['flag'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _countryData!['flag'],
                width: 80,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 50,
                    color: primaryPurple.withOpacity(0.3),
                    child: Icon(Icons.flag, color: lightPurple, size: 30),
                  );
                },
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _countryData!['name'] ?? 'Unknown',
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 24,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_countryData!['capital'] != null)
                  Text(
                    'Ibukota: ${_countryData!['capital']}',
                    style: TextStyle(
                      color: lightPurple,
                      fontSize: 14,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                if (_countryData!['continent'] != null)
                  Text(
                    '${_countryData!['continent']['name']} ${_countryData!['continent']['emoji'] ?? ''}',
                    style: TextStyle(
                      color: lightPurple,
                      fontSize: 14,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: lightPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'INFORMASI DETAIL',
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF7B1FA2), height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildInfoItem(
                icon: Icons.phone,
                label: 'Kode Telepon',
                value: _countryData!['phoneCode'] ?? '-',
              ),
              _buildInfoItem(
                icon: Icons.map,
                label: 'Luas Wilayah',
                value: _countryData!['area'] != null 
                    ? '${_countryData!['area']['squareKilometers']} km²'
                    : '-',
              ),
              _buildInfoItem(
                icon: Icons.language,
                label: 'Bahasa',
                value: _countryData!['languages'] != null && 
                        _countryData!['languages']['native'] != null
                    ? (_countryData!['languages']['native'] as List).join(', ')
                    : '-',
              ),
              _buildInfoItem(
                icon: Icons.attach_money,
                label: 'Mata Uang',
                value: _countryData!['currency'] ?? '-',
              ),
              _buildInfoItem(
                icon: Icons.traffic,
                label: 'Sisi Jalan',
                value: _countryData!['drivingSide'] ?? '-',
              ),
              _buildInfoItem(
                icon: Icons.public,
                label: 'TLD',
                value: _countryData!['internetTLD'] ?? '-',
              ),
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Latitude',
                value: _countryData!['coordinates'] != null
                    ? _countryData!['coordinates']['latitude'].toString()
                    : '-',
              ),
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Longitude',
                value: _countryData!['coordinates'] != null
                    ? _countryData!['coordinates']['longitude'].toString()
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_countryData!['famousFor'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryPurple.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terkenal: ${_countryData!['famousFor']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: lightPurple, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: lightPurple,
                  fontSize: 10,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborsSection() {
    List neighbors = _countryData!['neighbors'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: lightPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'NEGARA TETANGGA',
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF7B1FA2), height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: neighbors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              var neighbor = neighbors[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryPurple.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    if (neighbor['flag'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          neighbor['flag'],
                          width: 40,
                          height: 25,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 25,
                              color: primaryPurple.withOpacity(0.3),
                              child: Icon(Icons.flag, color: lightPurple, size: 15),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            neighbor['name'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (neighbor['coordinates'] != null)
                            Text(
                              'Lat: ${neighbor['coordinates']['latitude']}, Long: ${neighbor['coordinates']['longitude']}',
                              style: TextStyle(
                                color: lightPurple,
                                fontSize: 10,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }
}