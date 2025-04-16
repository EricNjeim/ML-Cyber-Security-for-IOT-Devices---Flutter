// home_dart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:iotframework/services/auth_service.dart';
import 'package:vector_math/vector_math.dart' as vector;

// Network Traffic model for attack logs
class NetworkTraffic {
  final int id;
  final String category;
  final String detectedAs;
  final String ethDst;
  final String ethSrc;
  final String ipDst;
  final String ipSrc;
  final int? tcpDstPort;
  final int? tcpSrcPort;
  final String timestamp;
  final int? udpDstPort;
  final int? udpSrcPort;

  NetworkTraffic({
    required this.id,
    required this.category,
    required this.detectedAs,
    required this.ethDst,
    required this.ethSrc,
    required this.ipDst,
    required this.ipSrc,
    this.tcpDstPort,
    this.tcpSrcPort,
    required this.timestamp,
    this.udpDstPort,
    this.udpSrcPort,
  });

  factory NetworkTraffic.fromJson(Map<String, dynamic> json) {
    return NetworkTraffic(
      id: json['id'] != null
          ? (json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0)
          : 0,
      category: json['category']?.toString() ?? 'Unknown',
      detectedAs: json['detected_as']?.toString() ?? 'Unknown',
      ethDst: json['eth_dst']?.toString() ?? '',
      ethSrc: json['eth_src']?.toString() ?? '',
      ipDst: json['ip_dst']?.toString() ?? '',
      ipSrc: json['ip_src']?.toString() ?? '',
      tcpDstPort: json['tcp_dstport'] != null
          ? (json['tcp_dstport'] is int
              ? json['tcp_dstport']
              : int.tryParse(json['tcp_dstport'].toString()))
          : null,
      tcpSrcPort: json['tcp_srcport'] != null
          ? (json['tcp_srcport'] is int
              ? json['tcp_srcport']
              : int.tryParse(json['tcp_srcport'].toString()))
          : null,
      timestamp: json['timestamp']?.toString() ?? '',
      udpDstPort: json['udp_dstport'] != null
          ? (json['udp_dstport'] is int
              ? json['udp_dstport']
              : int.tryParse(json['udp_dstport'].toString()))
          : null,
      udpSrcPort: json['udp_srcport'] != null
          ? (json['udp_srcport'] is int
              ? json['udp_srcport']
              : int.tryParse(json['udp_srcport'].toString()))
          : null,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Define the widgets for the four tabs.
  final List<Widget> _pages = [
    const DashboardTab(),
    const LogsTab(),
    const AnalyticsTab(),
    const DevicesTab(),
    const NetworkMapTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IoT Attack Detection"),
        backgroundColor: Colors.greenAccent,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_check),
            label: 'Network',
          ),
        ],
      ),
    );
  }
}

// ----- Dashboard Tab -----
// This tab incorporates the key features of the monitoring dashboard.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Dummy data for attack summary.
  final List<Map<String, dynamic>> attackSummaryData = const [
    {'title': 'Today', 'count': 5},
    {'title': 'Week', 'count': 20},
    {'title': 'Month', 'count': 80},
  ];

  // For network traffic logs
  List<NetworkTraffic> recentAttacks = [];
  bool isLoading = false;
  final AuthService _authService = AuthService();
  final String apiBaseUrl = 'http://192.168.101.55:3000/api';

  @override
  void initState() {
    super.initState();
    fetchRecentAttacks();
  }

  Future<void> fetchRecentAttacks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/network-traffic'),
        headers: headers,
      );

      print('GET network-traffic status (Dashboard): ${response.statusCode}');

      if (response.body.isNotEmpty) {
        print(
            'GET network-traffic response (Dashboard): ${response.body.substring(0, min(500, response.body.length))}...');
      }

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        print('Decoded data type (Dashboard): ${decodedData.runtimeType}');

        List<dynamic> trafficData = [];

        // Handle different response formats
        if (decodedData is List) {
          // If response is directly a list
          trafficData = decodedData;
          print('Response is a List with ${trafficData.length} items');
        } else if (decodedData is Map) {
          print('Response is a Map with keys: ${decodedData.keys.toList()}');

          // Try different keys that might contain the data
          if (decodedData.containsKey('data')) {
            final data = decodedData['data'];
            if (data is List) {
              trafficData = data;
              print('Found data list with ${trafficData.length} items');
            }
          } else if (decodedData.containsKey('traffic')) {
            final traffic = decodedData['traffic'];
            if (traffic is List) {
              trafficData = traffic;
              print('Found traffic list with ${trafficData.length} items');
            }
          } else if (decodedData.containsKey('logs')) {
            final logs = decodedData['logs'];
            if (logs is List) {
              trafficData = logs;
              print('Found logs list with ${trafficData.length} items');
            }
          } else {
            // If no known list field is found, look for any list field
            for (var key in decodedData.keys) {
              final value = decodedData[key];
              if (value is List && value.isNotEmpty) {
                trafficData = value;
                print(
                    'Found list in key "$key" with ${trafficData.length} items');
                break;
              }
            }

            // If still no list found, try to convert the map to a list of one item
            if (trafficData.isEmpty) {
              print(
                  'No list found in the response, treating the whole response as one log');
              // Check if the map itself can be treated as a log entry
              if (decodedData.containsKey('id') ||
                  decodedData.containsKey('detected_as')) {
                trafficData = [decodedData];
              }
            }
          }
        }

        if (trafficData.isEmpty) {
          print('No usable data found in the response (Dashboard)');
          setState(() {
            recentAttacks = [];
            isLoading = false;
          });
          return;
        }

        setState(() {
          try {
            // Print first item to debug
            if (trafficData.isNotEmpty) {
              print('First item (Dashboard): ${trafficData.first}');
            }

            recentAttacks = trafficData
                .map((item) {
                  try {
                    return NetworkTraffic.fromJson(item);
                  } catch (e) {
                    print('Error parsing item (Dashboard): $e');
                    print('Item data: $item');
                    return null;
                  }
                })
                .where((item) => item != null)
                .cast<NetworkTraffic>()
                .toList();

            print(
                'Successfully parsed ${recentAttacks.length} logs for dashboard');

            // Sort by timestamp and take most recent 5
            if (recentAttacks.isNotEmpty) {
              recentAttacks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              if (recentAttacks.length > 5) {
                recentAttacks = recentAttacks.sublist(0, 5);
              }
            }
          } catch (e) {
            print('Error processing traffic data (Dashboard): $e');
            recentAttacks = [];
          }
        });
      } else if (response.statusCode == 401) {
        // Handle authentication error
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch attacks: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching attacks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Attack Summary Section ---
          const Text(
            "Attack Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: attackSummaryData.map((item) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['count'].toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // --- Threat Level Indicator ---
          const Text(
            "Threat Level",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.redAccent, // Adjust color based on current severity
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "High Risk!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // --- Attack Types Pie Chart ---
          const Text(
            "Attack Types",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 40,
                    color: Colors.blue,
                    title: 'DoS',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    color: Colors.orange,
                    title: 'Port Scan',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    color: Colors.purple,
                    title: 'Others',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Latest Attacks Timeline ---
          const Text(
            "Latest Attacks",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (recentAttacks.isEmpty)
            const Center(
              child: Text("No recent attacks detected."),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentAttacks.length,
              itemBuilder: (context, index) {
                final attack = recentAttacks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: _getAttackIcon(attack.detectedAs),
                    title: Text(attack.detectedAs),
                    subtitle: Text(
                      "Source: ${attack.ipSrc} | Time: ${attack.timestamp}",
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _getAttackIcon(String attackType) {
    IconData iconData;
    Color iconColor;

    switch (attackType.toLowerCase()) {
      case 'ddos':
        iconData = Icons.lan;
        iconColor = Colors.red;
        break;
      case 'port scan':
        iconData = Icons.scanner;
        iconColor = Colors.orange;
        break;
      case 'malware':
        iconData = Icons.bug_report;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.redAccent;
    }

    return Icon(iconData, color: iconColor);
  }
}

// ----- Logs Tab -----
// Represents the attack history screen with a timeline of recorded events.
class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  List<NetworkTraffic> attackLogs = [];
  bool isLoading = true;
  final AuthService _authService = AuthService();
  final String apiBaseUrl = 'http://192.168.101.55:3000/api';

  @override
  void initState() {
    super.initState();
    fetchAttackLogs();
  }

  Future<void> fetchAttackLogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/network-traffic'),
        headers: headers,
      );

      print('GET network-traffic status: ${response.statusCode}');

      if (response.body.isNotEmpty) {
        print(
            'GET network-traffic response: ${response.body.substring(0, min(500, response.body.length))}');
      }

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        print('Decoded data type: ${decodedData.runtimeType}');

        List<dynamic> trafficData = [];

        // Handle different response formats
        if (decodedData is List) {
          // If response is directly a list
          trafficData = decodedData;
          print('Response is a List with ${trafficData.length} items');
        } else if (decodedData is Map) {
          print('Response is a Map with keys: ${decodedData.keys.toList()}');

          // Try different keys that might contain the data
          if (decodedData.containsKey('data')) {
            final data = decodedData['data'];
            if (data is List) {
              trafficData = data;
              print('Found data list with ${trafficData.length} items');
            }
          } else if (decodedData.containsKey('traffic')) {
            final traffic = decodedData['traffic'];
            if (traffic is List) {
              trafficData = traffic;
              print('Found traffic list with ${trafficData.length} items');
            }
          } else if (decodedData.containsKey('logs')) {
            final logs = decodedData['logs'];
            if (logs is List) {
              trafficData = logs;
              print('Found logs list with ${trafficData.length} items');
            }
          } else {
            // If no known list field is found, look for any list field
            for (var key in decodedData.keys) {
              final value = decodedData[key];
              if (value is List && value.isNotEmpty) {
                trafficData = value;
                print(
                    'Found list in key "$key" with ${trafficData.length} items');
                break;
              }
            }

            // If still no list found, try to convert the map to a list of one item
            if (trafficData.isEmpty) {
              print(
                  'No list found in the response, treating the whole response as one log');
              // Check if the map itself can be treated as a log entry
              if (decodedData.containsKey('id') ||
                  decodedData.containsKey('detected_as')) {
                trafficData = [decodedData];
              }
            }
          }
        }

        if (trafficData.isEmpty) {
          print('No usable data found in the response');
          setState(() {
            attackLogs = [];
            isLoading = false;
          });
          return;
        }

        setState(() {
          try {
            // Print first item to debug
            if (trafficData.isNotEmpty) {
              print('First item: ${trafficData.first}');
            }

            attackLogs = trafficData
                .map((item) {
                  try {
                    return NetworkTraffic.fromJson(item);
                  } catch (e) {
                    print('Error parsing item: $e');
                    print('Item data: $item');
                    return null;
                  }
                })
                .where((item) => item != null)
                .cast<NetworkTraffic>()
                .toList();

            print('Successfully parsed ${attackLogs.length} logs');

            // Sort by timestamp and take most recent 20
            if (attackLogs.isNotEmpty) {
              attackLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              if (attackLogs.length > 20) {
                attackLogs = attackLogs.sublist(0, 20);
              }
            }
          } catch (e) {
            print('Error processing traffic data: $e');
            attackLogs = [];
          }
        });
      } else if (response.statusCode == 401) {
        // Handle authentication error
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to fetch attack logs: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Exception in fetchAttackLogs: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching attack logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attackLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No attack logs found."),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchAttackLogs,
              child: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: fetchAttackLogs,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: attackLogs.length,
          itemBuilder: (context, index) {
            final log = attackLogs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: _getAttackIcon(log.detectedAs),
                title: Text("${log.detectedAs} - ${log.category}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Source: ${log.ipSrc}"),
                    Text("Time: ${log.timestamp}"),
                  ],
                ),
                onTap: () => _showAttackDetails(log),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchAttackLogs,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _getAttackIcon(String attackType) {
    IconData iconData;
    Color iconColor;

    switch (attackType.toLowerCase()) {
      case 'ddos':
        iconData = Icons.lan;
        iconColor = Colors.red;
        break;
      case 'port scan':
        iconData = Icons.scanner;
        iconColor = Colors.orange;
        break;
      case 'malware':
        iconData = Icons.bug_report;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.redAccent;
    }

    return Icon(iconData, color: iconColor);
  }

  void _showAttackDetails(NetworkTraffic log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.detectedAs),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("ID", log.id.toString()),
              _detailRow("Category", log.category),
              _detailRow("Source IP", log.ipSrc),
              _detailRow("Destination IP", log.ipDst),
              _detailRow("Source MAC", log.ethSrc),
              _detailRow("Destination MAC", log.ethDst),
              if (log.tcpSrcPort != null)
                _detailRow("TCP Source Port", log.tcpSrcPort.toString()),
              if (log.tcpDstPort != null)
                _detailRow("TCP Destination Port", log.tcpDstPort.toString()),
              if (log.udpSrcPort != null)
                _detailRow("UDP Source Port", log.udpSrcPort.toString()),
              if (log.udpDstPort != null)
                _detailRow("UDP Destination Port", log.udpDstPort.toString()),
              _detailRow("Timestamp", log.timestamp),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ----- Analytics Tab -----
// A placeholder for detailed analytics and trends.
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Extend with charts, graphs, or other analytical widgets.
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Analytics", style: TextStyle(fontSize: 24)),
          SizedBox(height: 16),
          Text("Detailed analytics and trends will appear here.",
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ----- Settings Tab -----
// Allows users to configure app settings (theme, notifications, thresholds, monitored locations, etc.).
class DevicesTab extends StatefulWidget {
  const DevicesTab({super.key});

  @override
  State<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  final List<Device> devices = [];
  bool isLoading = true;
  final String apiBaseUrl = 'http://192.168.101.55:3000/api';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/devices'),
        headers: headers,
      );

      // Log the response for debugging
      print('GET devices status: ${response.statusCode}');
      print('GET devices response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> devicesJson = responseData['devices'] ?? [];
        setState(() {
          devices.clear();
          for (var deviceJson in devicesJson) {
            devices.add(Device(
              id: deviceJson['id']?.toString() ?? '',
              name: deviceJson['name'] ?? '',
              ipAddress: deviceJson['ip_address'] ?? '',
              macAddress: deviceJson['mac_address'] ?? '',
              userId: deviceJson['user_id']?.toString() ?? '',
            ));
          }
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid, redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );

        // Logout user and redirect to login
        await _authService.logout();

        // Navigate to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        // If server returns an error, use mock data for now
        setState(() {
          devices.addAll([
            Device(
                id: '1',
                name: "Living Room Sensor",
                ipAddress: "192.168.1.100",
                macAddress: "00:1A:2B:3C:4D:5E",
                userId: '1'),
            Device(
                id: '2',
                name: "Kitchen Camera",
                ipAddress: "192.168.1.101",
                macAddress: "00:1A:2B:3C:4D:5F",
                userId: '1'),
            Device(
                id: '3',
                name: "Bedroom Thermostat",
                ipAddress: "192.168.1.102",
                macAddress: "00:1A:2B:3C:4D:60",
                userId: '1'),
          ]);
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch devices: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // On error, load mock data
      setState(() {
        devices.addAll([
          Device(
              id: '1',
              name: "Living Room Sensor",
              ipAddress: "192.168.1.100",
              macAddress: "00:1A:2B:3C:4D:5E",
              userId: '1'),
          Device(
              id: '2',
              name: "Kitchen Camera",
              ipAddress: "192.168.1.101",
              macAddress: "00:1A:2B:3C:4D:5F",
              userId: '1'),
          Device(
              id: '3',
              name: "Bedroom Thermostat",
              ipAddress: "192.168.1.102",
              macAddress: "00:1A:2B:3C:4D:60",
              userId: '1'),
        ]);
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching devices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> postDevice(Device device) async {
    try {
      // Add loading indicator
      setState(() {
        isLoading = true;
      });

      // Log the request for debugging
      print('Posting device to $apiBaseUrl/devices');
      print('Request body: ${jsonEncode({
            'name': device.name,
            'ip_address': device.ipAddress,
            'mac_address': device.macAddress,
          })}');

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$apiBaseUrl/devices'),
        headers: headers,
        body: jsonEncode({
          'name': device.name,
          'ip_address': device.ipAddress,
          'mac_address': device.macAddress,
        }),
      );

      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Success - refresh the device list
        await fetchDevices();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device ${device.name} added successfully')),
        );
      } else if (response.statusCode == 401) {
        // Token expired or invalid, redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );

        // Logout user and redirect to login
        await _authService.logout();

        // Navigate to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to add device: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateDevice(Device device, String deviceId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$apiBaseUrl/devices/$deviceId'),
        headers: headers,
        body: jsonEncode({
          'name': device.name,
          'ip_address': device.ipAddress,
          'mac_address': device.macAddress,
        }),
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device ${device.name} updated successfully')),
        );
      } else if (response.statusCode == 401) {
        // Token expired or invalid, redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );

        // Logout user and redirect to login
        await _authService.logout();

        // Navigate to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update device: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pingDevice(Device device) async {
    // Show a loading indicator
    final snackBar = SnackBar(
      content: Text('Pinging ${device.name}...'),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/devices/${device.id}/ping'),
        headers: headers,
      );

      print('Ping response status: ${response.statusCode}');
      print('Ping response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract ping result
        final pingResult = responseData['ping_result'];
        final status = pingResult['status'];
        final packetLoss = pingResult['packet_loss'];
        final latency = pingResult['latency'];

        final isReachable = status == 'online';

        // Show detailed ping result in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Ping Results: ${device.name}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: ${isReachable ? 'Online ✓' : 'Offline ✗'}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isReachable ? Colors.green : Colors.red)),
                const SizedBox(height: 8),
                Text("Packet Loss: $packetLoss"),
                const SizedBox(height: 8),
                if (latency != null) ...[
                  Text("Latency:"),
                  Text("  Avg: ${latency['avg']} ms"),
                  Text("  Min: ${latency['min']} ms"),
                  Text("  Max: ${latency['max']} ms"),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ping ${device.name}: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pinging ${device.name}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pingAllDevices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/devices/ping-all'),
        headers: headers,
      );

      print('Ping all response status: ${response.statusCode}');
      print('Ping all response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final results = responseData['results'] as List;

        // Update device status based on ping results
        for (var result in results) {
          final deviceData = result['device'];
          final pingResult = result['ping_result'];

          // Find the device in our list
          final deviceId = deviceData['id'].toString();
          final deviceIndex = devices.indexWhere((d) => d.id == deviceId);

          if (deviceIndex >= 0) {
            setState(() {
              // Update device status
              devices[deviceIndex] = devices[deviceIndex].copyWith(
                status: pingResult['status'] ?? 'unknown',
                packetLoss: pingResult['packet_loss'] ?? 'N/A',
                latencyAvg: pingResult['latency']?['avg']?.toString() ?? 'N/A',
                latencyMin: pingResult['latency']?['min']?.toString() ?? 'N/A',
                latencyMax: pingResult['latency']?['max']?.toString() ?? 'N/A',
              );
            });
          }
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All devices pinged successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ping all devices: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pinging all devices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addNewDevice() {
    showDialog(
      context: context,
      builder: (context) => DeviceDialog(
        onSave: (Device device) {
          setState(() {
            devices.add(device);
          });
          postDevice(device);
        },
      ),
    );
  }

  void editDevice(Device device, int index) {
    final String deviceId = device.id;
    showDialog(
      context: context,
      builder: (context) => DeviceDialog(
        device: device,
        onSave: (Device updatedDevice) {
          setState(() {
            devices[index] = updatedDevice;
          });
          updateDevice(updatedDevice, deviceId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? const Center(
                  child: Text(
                      "No devices found. Add a device using the + button."))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Dismissible(
                      key: Key(
                          device.id.isNotEmpty ? device.id : device.ipAddress),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: Text(
                                  "Are you sure you want to delete ${device.name}?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("CANCEL"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("DELETE"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        // Remove device from list
                        setState(() {
                          devices.removeAt(index);
                        });

                        // Call API to delete the device
                        deleteDevice(device);

                        // Show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${device.name} deleted'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                // Add the device back
                                setState(() {
                                  devices.insert(index, device);
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(device.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("IP: ${device.ipAddress}"),
                              Text("MAC: ${device.macAddress}"),
                              if (device.status != 'unknown')
                                Text("Status: ${device.status}",
                                    style: TextStyle(
                                        color: device.status == 'online'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.network_ping,
                                    color: Colors.blue),
                                onPressed: () => pingDevice(device),
                                tooltip: "Ping device",
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => editDevice(device, index),
                                tooltip: "Edit device",
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Ping All button
          FloatingActionButton(
            heroTag: "pingAll",
            onPressed: pingAllDevices,
            backgroundColor: Colors.blue,
            mini: true,
            child: const Icon(Icons.network_check),
            tooltip: "Ping all devices",
          ),
          const SizedBox(height: 16),
          // Add Device button
          FloatingActionButton(
            heroTag: "addDevice",
            onPressed: addNewDevice,
            backgroundColor: Colors.greenAccent,
            child: const Icon(Icons.add),
            tooltip: "Add new device",
          ),
        ],
      ),
    );
  }

  // Add a method to delete devices
  Future<void> deleteDevice(Device device) async {
    try {
      setState(() {
        isLoading = true;
      });

      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse(
            '$apiBaseUrl/devices/${device.id.isNotEmpty ? device.id : device.ipAddress}'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device ${device.name} deleted successfully')),
        );
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        await _authService.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to delete device: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class Device {
  String id;
  String name;
  String ipAddress;
  String macAddress;
  String userId;
  String status;
  String packetLoss;
  String latencyAvg;
  String latencyMin;
  String latencyMax;

  Device({
    this.id = '',
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    this.userId = '',
    this.status = 'unknown',
    this.packetLoss = 'N/A',
    this.latencyAvg = 'N/A',
    this.latencyMin = 'N/A',
    this.latencyMax = 'N/A',
  });

  Device copyWith({
    String? id,
    String? name,
    String? ipAddress,
    String? macAddress,
    String? userId,
    String? status,
    String? packetLoss,
    String? latencyAvg,
    String? latencyMin,
    String? latencyMax,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      packetLoss: packetLoss ?? this.packetLoss,
      latencyAvg: latencyAvg ?? this.latencyAvg,
      latencyMin: latencyMin ?? this.latencyMin,
      latencyMax: latencyMax ?? this.latencyMax,
    );
  }
}

class DeviceDialog extends StatefulWidget {
  final Device? device;
  final Function(Device) onSave;

  const DeviceDialog({
    super.key,
    this.device,
    required this.onSave,
  });

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  late TextEditingController nameController;
  late TextEditingController ipController;
  late TextEditingController macController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.device?.name ?? '');
    ipController = TextEditingController(text: widget.device?.ipAddress ?? '');
    macController =
        TextEditingController(text: widget.device?.macAddress ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    ipController.dispose();
    macController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.device == null ? 'Add Device' : 'Edit Device'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'Enter device name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: 'Enter IP address (e.g. 192.168.101.55)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: macController,
              decoration: const InputDecoration(
                labelText: 'MAC Address',
                hintText: 'Enter MAC address (e.g. 00:1A:2B:3C:4D:5E)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isEmpty ||
                ipController.text.isEmpty ||
                macController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')));
              return;
            }

            final device = Device(
              id: widget.device?.id ?? '',
              name: nameController.text,
              ipAddress: ipController.text,
              macAddress: macController.text,
              userId: widget.device?.userId ?? '',
            );

            widget.onSave(device);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ----- NetworkMapTab -----
class NetworkMapTab extends StatefulWidget {
  const NetworkMapTab({super.key});

  @override
  State<NetworkMapTab> createState() => _NetworkMapTabState();
}

class _NetworkMapTabState extends State<NetworkMapTab> {
  bool isLoading = true;
  final AuthService _authService = AuthService();
  final String apiBaseUrl = 'http://192.168.101.55:3000/api';
  List<Device> devices = [];

  // Router details
  final RouterNode router = RouterNode(
    id: 'router',
    name: 'Router',
    ipAddress: '192.168.101.1',
  );

  @override
  void initState() {
    super.initState();
    fetchDevicesAndPingStatus();
  }

  Future<void> fetchDevicesAndPingStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First fetch devices
      final headers = await _authService.getAuthHeaders();
      final devicesResponse = await http.get(
        Uri.parse('$apiBaseUrl/devices'),
        headers: headers,
      );

      if (devicesResponse.statusCode == 200) {
        final dynamic decodedData = jsonDecode(devicesResponse.body);
        List<dynamic> devicesData = [];

        if (decodedData is Map && decodedData.containsKey('devices')) {
          devicesData = decodedData['devices'] as List<dynamic>;
        } else if (decodedData is List) {
          devicesData = decodedData;
        }

        setState(() {
          devices = devicesData.map((item) {
            return Device(
              id: item['id']?.toString() ?? '',
              name: item['name'] ?? 'Unknown Device',
              ipAddress: item['ip_address'] ?? '',
              macAddress: item['mac_address'] ?? '',
              userId: item['user_id']?.toString() ?? '',
            );
          }).toList();
        });

        // Then perform ping-all to get statuses
        await pingAllDevices();
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to fetch devices: ${devicesResponse.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching devices: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pingAllDevices() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/devices/ping-all'),
        headers: headers,
      );

      print('Ping all response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final results = responseData['results'] as List;

        // Update device status based on ping results
        for (var result in results) {
          final deviceData = result['device'];
          final pingResult = result['ping_result'];

          // Find the device in our list
          final deviceId = deviceData['id'].toString();
          final deviceIndex = devices.indexWhere((d) => d.id == deviceId);

          if (deviceIndex >= 0) {
            setState(() {
              // Update device status
              devices[deviceIndex] = devices[deviceIndex].copyWith(
                status: pingResult['status'] ?? 'unknown',
                packetLoss: pingResult['packet_loss'] ?? 'N/A',
                latencyAvg: pingResult['latency']?['avg']?.toString() ?? 'N/A',
                latencyMin: pingResult['latency']?['min']?.toString() ?? 'N/A',
                latencyMax: pingResult['latency']?['max']?.toString() ?? 'N/A',
              );
            });
          }
        }
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ping devices: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error pinging devices: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pinging devices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Network Topology Map',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: devices.isEmpty
                      ? const Center(child: Text('No devices found'))
                      : NetworkMapWidget(devices: devices, router: router),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchDevicesAndPingStatus,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Network Map',
      ),
    );
  }
}

class RouterNode {
  final String id;
  final String name;
  final String ipAddress;

  RouterNode({
    required this.id,
    required this.name,
    required this.ipAddress,
  });
}

class NetworkMapWidget extends StatelessWidget {
  final List<Device> devices;
  final RouterNode router;

  const NetworkMapWidget({
    super.key,
    required this.devices,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 2.0,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          child: CustomPaint(
            painter: NetworkMapPainter(devices: devices, router: router),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class NetworkMapPainter extends CustomPainter {
  final List<Device> devices;
  final RouterNode router;

  NetworkMapPainter({
    required this.devices,
    required this.router,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;

    // Draw router in the center
    _drawRouter(canvas, center);

    // Draw devices in a circle around the router
    final deviceCount = devices.length;
    if (deviceCount > 0) {
      for (int i = 0; i < deviceCount; i++) {
        final angle = 2 * pi * i / deviceCount;
        final deviceOffset = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );

        // Draw connection line first (so it's behind the nodes)
        _drawConnection(
            canvas, center, deviceOffset, devices[i].status == 'online');

        // Draw the device
        _drawDevice(canvas, deviceOffset, devices[i]);
      }
    }
  }

  void _drawRouter(Canvas canvas, Offset position) {
    // Router background
    final Paint routerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 30, routerPaint);

    // Router icon
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: "🌐",
        style: TextStyle(
          fontSize: 30,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ));

    // Router label
    final TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: router.name,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    labelPainter.layout();
    labelPainter.paint(
        canvas,
        Offset(
          position.dx - labelPainter.width / 2,
          position.dy + 35,
        ));
  }

  void _drawDevice(Canvas canvas, Offset position, Device device) {
    // Device background with color based on status
    final Color deviceColor =
        device.status == 'online' ? Colors.green : Colors.red;

    final Paint devicePaint = Paint()
      ..color = deviceColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 25, devicePaint);

    // Device icon
    final String deviceIcon = _getDeviceIcon(device.name);
    final TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: deviceIcon,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    iconPainter.layout();
    iconPainter.paint(
        canvas,
        Offset(
          position.dx - iconPainter.width / 2,
          position.dy - iconPainter.height / 2,
        ));

    // Device name
    final TextPainter namePainter = TextPainter(
      text: TextSpan(
        text: device.name,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    namePainter.layout();
    namePainter.paint(
        canvas,
        Offset(
          position.dx - namePainter.width / 2,
          position.dy + 30,
        ));

    // IP address
    final TextPainter ipPainter = TextPainter(
      text: TextSpan(
        text: device.ipAddress,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    ipPainter.layout();
    ipPainter.paint(
        canvas,
        Offset(
          position.dx - ipPainter.width / 2,
          position.dy + 45,
        ));
  }

  void _drawConnection(Canvas canvas, Offset start, Offset end, bool isOnline) {
    final Paint linePaint = Paint()
      ..color = isOnline ? Colors.green : Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, linePaint);
  }

  String _getDeviceIcon(String deviceName) {
    final String nameLower = deviceName.toLowerCase();

    if (nameLower.contains('camera')) return '📷';
    if (nameLower.contains('thermostat')) return '🌡️';
    if (nameLower.contains('sensor')) return '🔍';
    if (nameLower.contains('lock')) return '🔒';
    if (nameLower.contains('light') || nameLower.contains('lamp')) return '💡';
    if (nameLower.contains('speaker')) return '🔊';
    if (nameLower.contains('tv')) return '📺';

    // Default icon
    return '📱';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
