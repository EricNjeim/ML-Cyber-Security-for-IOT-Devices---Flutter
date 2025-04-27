import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/features/devices/presentation/screens/device_edit_screen.dart';
import 'package:iotframework/core/di/injection_container.dart';

/// Screen to display and manage IoT devices
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String? _selectedDeviceIp;
  bool _isPingingAll = false;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(devicesProvider);
          // Clear ping results when refreshing
          setState(() {
            _selectedDeviceIp = null;
            _isPingingAll = false;
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'IoT Devices',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPingAllButton(),
                ],
              ),
              const SizedBox(height: 16.0),
              if (_isPingingAll) _buildPingAllResults(),
              _buildDevicesList(devicesAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewDevice(context),
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Future<void> _addNewDevice(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeviceEditScreen(isNew: true),
      ),
    );

    if (result == true) {
      // Device was added, refresh the list
      ref.refresh(devicesProvider);
    }
  }

  Future<void> _editDevice(BuildContext context, Device device) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceEditScreen(device: device),
      ),
    );

    if (result == true) {
      // Device was edited, refresh the list
      ref.refresh(devicesProvider);
    }
  }

  Future<void> _deleteDevice(BuildContext context, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deviceRepository =
          ref.read(ServiceLocator.deviceRepositoryProvider);

      final result = await deviceRepository.removeDevice(device.id);

      if (mounted) {
        result.fold(
          (success) {
            // Device successfully deleted
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Device "${device.name}" deleted')),
            );
            // Refresh the devices list
            ref.refresh(devicesProvider);
          },
          (failure) {
            // Error deleting device
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    }
  }

  Widget _buildPingAllButton() {
    return ElevatedButton.icon(
      onPressed: _isPingingAll
          ? null
          : () {
              setState(() {
                _isPingingAll = true;
                _selectedDeviceIp = null;
              });
              ref.refresh(pingAllDevicesProvider);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      icon: const Icon(Icons.network_check, size: 16),
      label: Text(_isPingingAll ? 'Pinging All...' : 'Ping All'),
    );
  }

  Widget _buildPingAllResults() {
    final pingAllAsync = ref.watch(pingAllDevicesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Network Scan Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _isPingingAll = false;
                  });
                },
                color: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),
          pingAllAsync.when(
            data: (result) {
              if (result == null) {
                return const Text('No data available');
              }
              return result.fold(
                (pingResults) {
                  if (pingResults.isEmpty) {
                    return const Text('No devices found');
                  }

                  final reachableCount = pingResults.values
                      .where((result) => result.isReachable)
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found ${pingResults.length} devices, $reachableCount reachable',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          children: [
                            ...pingResults.entries.map((entry) {
                              final ip = entry.key;
                              final result = entry.value;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  result.isReachable
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: result.isReachable
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                title: Text(
                                  ip,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: result.isReachable
                                    ? (result.latency != null
                                        ? Text(
                                            'Latency: ${result.latency}ms',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          )
                                        : null)
                                    : Text(
                                        result.error ?? 'Unreachable',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                (failure) {
                  return Text(
                    'Error: ${failure.message}',
                    style: const TextStyle(color: Colors.red),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 8),
                    Text('Scanning network...'),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Text(
              'Error scanning network: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(AsyncValue<dynamic> devicesAsync) {
    return devicesAsync.when(
      data: (result) {
        if (result == null) {
          return const Center(
            child: Text('No data available'),
          );
        }
        return result.fold(
          (devices) {
            if (devices.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100.0),
                  child: Text('No devices found'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceCard(device);
              },
            );
          },
          (failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    failure.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(devicesProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading devices: $error'),
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final isPinging = _selectedDeviceIp == device.ipAddress;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  device.type.icon,
                  color: device.status.color,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        device.type.displayName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // More button for actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editDevice(context, device);
                        break;
                      case 'delete':
                        _deleteDevice(context, device);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.router,
                        label: 'IP Address',
                        value: device.ipAddress,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.settings_ethernet,
                        label: 'MAC Address',
                        value: device.macAddress,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Last Seen',
                        value: _formatDateTime(device.lastSeen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildPingButton(device.ipAddress),
              ],
            ),
            if (isPinging) _buildPingResult(device.ipAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPingButton(String ipAddress) {
    final isPinging = _selectedDeviceIp == ipAddress;

    return ElevatedButton.icon(
      onPressed: isPinging
          ? null
          : () {
              setState(() {
                _selectedDeviceIp = ipAddress;
              });
              // Force refresh of the ping provider
              ref.refresh(pingResultProvider(ipAddress));
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      icon: const Icon(Icons.network_ping, size: 16),
      label: Text(isPinging ? 'Pinging...' : 'Ping'),
    );
  }

  Widget _buildPingResult(String ipAddress) {
    final pingAsync = ref.watch(pingResultProvider(ipAddress));

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: pingAsync.when(
        data: (result) {
          return result.fold(
            (pingResult) {
              final isReachable = pingResult.isReachable;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isReachable ? Icons.check_circle : Icons.error,
                    color: isReachable ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReachable
                              ? 'Device is reachable'
                              : 'Device is not reachable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isReachable ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (pingResult.packetLoss != null)
                          Text(
                            'Packet Loss: ${pingResult.packetLoss}',
                            style: TextStyle(
                              color:
                                  _getPacketLossColor(pingResult.packetLoss!),
                              fontSize: 14,
                            ),
                          ),
                        if (isReachable && pingResult.latency != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Latency:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildLatencyItem(
                                label: 'Min',
                                value: pingResult.latency!.min,
                              ),
                              const SizedBox(width: 16),
                              _buildLatencyItem(
                                label: 'Avg',
                                value: pingResult.latency!.avg,
                                isAvg: true,
                              ),
                              const SizedBox(width: 16),
                              _buildLatencyItem(
                                label: 'Max',
                                value: pingResult.latency!.max,
                              ),
                            ],
                          ),
                        ],
                        if (!isReachable && pingResult.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              pingResult.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedDeviceIp = null;
                      });
                    },
                    color: Colors.grey,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              );
            },
            (failure) {
              return Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      failure.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedDeviceIp = null;
                      });
                    },
                    color: Colors.grey,
                    iconSize: 20,
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, stack) => Text(
          'Error pinging device: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildLatencyItem(
      {required String label, required double value, bool isAvg = false}) {
    final latencyColor = _getLatencyColor(value, isAvg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        Text(
          '${value.round()}ms',
          style: TextStyle(
            color: latencyColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getLatencyColor(double latency, bool isAvg) {
    // Different thresholds for average vs min/max
    if (isAvg) {
      if (latency < 50) return Colors.green;
      if (latency < 100) return Colors.orange;
      return Colors.red;
    } else {
      if (latency < 20) return Colors.green;
      if (latency < 200) return Colors.orange;
      return Colors.red;
    }
  }

  Color _getPacketLossColor(String packetLoss) {
    // Parse the packet loss percentage
    final percentage =
        double.tryParse(packetLoss.replaceAll('%', '').trim()) ?? 0;

    if (percentage == 0) return Colors.green;
    if (percentage < 5) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
