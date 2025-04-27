import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:iotframework/features/notifications/notification_permission_manager.dart';
import 'package:iotframework/features/security/presentation/screens/attack_logs_screen.dart';
import 'package:iotframework/presentation/features/attacks/widgets/recent_attacks_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<Map<String, dynamic>> attackSummaryData = const [
    {'title': 'Today', 'count': 5},
    {'title': 'Week', 'count': 20},
    {'title': 'Month', 'count': 80},
  ];

  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    // Auto-ping the network when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performNetworkScan();
      _requestNotificationPermission();
    });
  }

  // Request notification permission and register FCM token
  Future<void> _requestNotificationPermission() async {
    final notificationManager = ref.read(notificationPermissionManagerProvider);
    await notificationManager.requestPermissionAndRegisterToken(context);
  }

  // Perform network scan that updates both dashboard and map
  Future<void> _performNetworkScan() async {
    if (_isPinging) return;

    setState(() {
      _isPinging = true;
    });

    try {
      // Refresh devices first
      await ref.refresh(devicesProvider.future);
      // Then ping all devices
      await ref.refresh(pingAllDevicesProvider.future);
    } catch (e) {
      debugPrint('Error during network scan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPinging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAttacksAsync = ref.watch(recentAttacksProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final pingAllAsync = ref.watch(pingAllDevicesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(recentAttacksProvider);
        await _performNetworkScan();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight -
                32, // Padding adjustment
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAttackSummary(),
              const SizedBox(height: 24.0),
              buildNetworkStatus(devicesAsync, pingAllAsync),
              const SizedBox(height: 24.0),
              buildSecurityStatus(),
              const SizedBox(height: 24.0),
              buildRecentAttacks(recentAttacksAsync),
              const SizedBox(height: 16.0), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAttackSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attack Summary',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showAllAttackLogs(),
              child: Text(
                'View All',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attackSummaryData.length,
            itemBuilder: (context, index) {
              final item = attackSummaryData[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () => _showAttackLogsForPeriod(item['title']),
                  borderRadius: BorderRadius.circular(12),
                  child: DashboardCard(
                    title: item['title'],
                    backgroundColor: Colors.greenAccent.withOpacity(0.2),
                    titleColor: Colors.green[700],
                    child: SizedBox(
                      height: 50, // Fixed height for the content area
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${item['count']}',
                                style: const TextStyle(
                                  fontSize: 20.0, // Slightly reduced
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Tap to view',
                                style: TextStyle(
                                  fontSize: 8.0, // Further reduced
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Method to show attack logs for a specific time period
  void _showAttackLogsForPeriod(String period) {
    // Determine appropriate endpoint based on period
    String endpoint;
    switch (period.toLowerCase()) {
      case 'today':
        endpoint = '/attacks/daily';
        break;
      case 'week':
        endpoint = '/attacks/weekly';
        break;
      case 'month':
        endpoint = '/attacks/monthly';
        break;
      default:
        endpoint = '/attacks';
    }

    // Navigate to logs screen with the appropriate endpoint
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AttackLogsScreen(
          period: period,
          endpoint: endpoint,
        ),
      ),
    );
  }

  // Method to show all attack logs
  void _showAllAttackLogs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AttackLogsScreen(
          period: 'All Time',
          endpoint: '/attacks',
        ),
      ),
    );
  }

  Widget buildNetworkStatus(
    AsyncValue<dynamic> devicesAsync,
    AsyncValue<dynamic> pingAllAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Network Status',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => AppRouter.navigateTo(AppRouter.networkRoute),
              icon: const Icon(Icons.fullscreen, size: 20),
              label: const Text('View Full Map'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 160, // Further reduced height
          child: DashboardCard(
            title: '',
            child: Stack(
              children: [
                buildNetworkOverview(devicesAsync, pingAllAsync),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: _isPinging ? null : _performNetworkScan,
                    backgroundColor:
                        _isPinging ? Colors.grey.shade300 : Colors.greenAccent,
                    child: _isPinging
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNetworkOverview(
    AsyncValue<dynamic> devicesAsync,
    AsyncValue<dynamic> pingAllAsync,
  ) {
    return devicesAsync.when(
      data: (devicesResult) {
        if (devicesResult == null) {
          return const Center(child: Text('No data available'));
        }

        return devicesResult.fold(
          (devices) {
            return pingAllAsync.when(
              data: (pingResult) {
                if (pingResult == null) {
                  return buildNetworkSummary(devices, {});
                }

                return pingResult.fold(
                  (results) => buildNetworkSummary(devices, results),
                  (failure) => buildNetworkSummary(devices, {}),
                );
              },
              loading: () => buildNetworkSummary(devices, {}, isLoading: true),
              error: (_, __) => buildNetworkSummary(devices, {}),
            );
          },
          (failure) => Center(
            child: Text('Error: ${failure.message}'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget buildNetworkSummary(
      List<Device> devices, Map<String, PingResult> pingResults,
      {bool isLoading = false}) {
    // Count online/offline devices
    final int total = devices.length;
    final int online = isLoading
        ? 0
        : pingResults.values.where((result) => result.isReachable).length;
    final int offline = total - online;

    return Stack(
      children: [
        // Allow content to scroll if it's too large
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use FittedBox to ensure the row fits horizontally
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildStatusIndicator(
                        'Total',
                        total.toString(),
                        Colors.blue,
                        isLoading: false,
                      ),
                      const SizedBox(width: 8),
                      buildStatusIndicator(
                        'Online',
                        isLoading ? '...' : online.toString(),
                        Colors.green,
                        isLoading: isLoading,
                      ),
                      const SizedBox(width: 8),
                      buildStatusIndicator(
                        'Offline',
                        isLoading ? '...' : offline.toString(),
                        Colors.red,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (total > 0)
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value:
                              isLoading ? 0 : (total > 0 ? online / total : 0),
                          backgroundColor: Colors.red.withOpacity(0.2),
                          color: Colors.green,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        if (isLoading)
                          Positioned.fill(
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: Colors.grey.withOpacity(0.5),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  isLoading
                      ? 'Scanning...'
                      : 'Health: ${total > 0 ? ((online / total) * 100).toStringAsFixed(0) : "0"}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget buildStatusIndicator(String label, String value, Color color,
      {bool isLoading = false}) {
    return SizedBox(
      width: 42, // Fixed width to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.0, // Ensure perfect circle
            child: Container(
              decoration: BoxDecoration(
                color: isLoading
                    ? Colors.grey.withOpacity(0.2)
                    : color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLoading ? Colors.grey : color,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isLoading && value == '...'
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.grey[500],
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Reduced to ensure it fits
                              color: isLoading ? Colors.grey : color,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8, // Reduced font size
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSecurityStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Status',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 120,
          child: DashboardCard(
            title: '',
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Security status icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Protected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Last scan: ${_getFormattedTime()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Security status bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.85,
                            backgroundColor: Colors.red,
                            color: Colors.green,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to security settings or initiate a deep scan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Initiating deep scan...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    child: const Text('Scan Now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget buildRecentAttacks(
    AsyncValue<Result<List<NetworkTraffic>>> recentAttacksAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Network Activity',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        const SizedBox(
          height: 300,
          child: RecentAttacksWidget(),
        ),
      ],
    );
  }
}
