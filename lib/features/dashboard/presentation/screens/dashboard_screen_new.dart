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
import 'package:iotframework/presentation/features/attacks/widgets/recent_attacks_widget.dart';
import 'package:iotframework/presentation/features/attacks/providers/recent_attacks_provider.dart'
    as attacks_provider;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
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

  // Perform network scan that updates the dashboard
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
    final devicesAsync = ref.watch(devicesProvider);
    final pingAllAsync = ref.watch(pingAllDevicesProvider);

    return RefreshIndicator(
      onRefresh: () async {
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
              buildRecentAttacks(),
              const SizedBox(height: 16.0), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAttackSummary() {
    // Get the real-time data from providers
    final todayAttacksAsync = ref.watch(todayAttacksProvider);
    final weekAttacksAsync = ref.watch(weekAttacksProvider);
    final monthAttacksAsync = ref.watch(monthAttacksProvider);

    // Create dynamic summary data with explicit types
    final List<Map<String, dynamic>> attackSummaryData = [
      {
        'title': 'Today',
        'count': todayAttacksAsync.when(
          data: (result) => result.fold(
            (data) => data.length,
            (_) => 0,
          ),
          loading: () => 0,
          error: (_, __) => 0,
        ),
        'route': AppRouter.todayAttacksRoute,
      },
      {
        'title': 'Week',
        'count': weekAttacksAsync.when(
          data: (result) => result.fold(
            (data) => data.length,
            (_) => 0,
          ),
          loading: () => 0,
          error: (_, __) => 0,
        ),
        'route': AppRouter.weekAttacksRoute,
      },
      {
        'title': 'Month',
        'count': monthAttacksAsync.when(
          data: (result) => result.fold(
            (data) => data.length,
            (_) => 0,
          ),
          loading: () => 0,
          error: (_, __) => 0,
        ),
        'route': AppRouter.monthAttacksRoute,
      },
    ];

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
                  onTap: () {
                    final route = item['route'] as String;
                    Navigator.pushNamed(context, route);
                  },
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
          ],
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 160,
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

  Widget buildRecentAttacks() {
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
        SizedBox(
          height: 300,
          child: ErrorHandlingRecentAttacksWidget(),
        ),
      ],
    );
  }

  /// Error handling wrapper for the RecentAttacksWidget
  /// This ensures we handle any exceptions gracefully
  Widget ErrorHandlingRecentAttacksWidget() {
    return Consumer(
      builder: (context, ref, child) {
        // Use a try-catch block to handle any exceptions
        try {
          return const RecentAttacksWidget();
        } catch (e) {
          // Return a friendly error card if any exception occurs
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load network activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to refresh the provider
                      try {
                        final provider = ref.read(
                            attacks_provider.recentAttacksProvider.notifier);
                        provider.fetchRecentAttacks();
                      } catch (refreshError) {
                        // If refresh fails, show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not refresh: $refreshError'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
