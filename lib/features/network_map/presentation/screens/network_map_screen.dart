import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/features/network_map/presentation/widgets/network_topology_map.dart';

/// Screen to display network topology map
class NetworkMapScreen extends ConsumerStatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  ConsumerState<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends ConsumerState<NetworkMapScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);
    final pingAllAsync = ref.watch(pingAllDevicesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both devices and ping results
          await _performScan();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Network Topology',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanNetwork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Network map
              Expanded(
                child: devicesAsync.when(
                  data: (devicesResult) {
                    if (devicesResult == null) {
                      return const Center(
                        child: Text('No data available'),
                      );
                    }
                    return devicesResult.fold(
                      (devices) {
                        if (devices.isEmpty) {
                          return const Center(
                            child: Text('No devices found'),
                          );
                        }

                        return pingAllAsync.when(
                          data: (pingResults) {
                            if (pingResults == null) {
                              return NetworkTopologyMap(
                                devices: devices,
                                pingResults: {},
                                onDeviceTap: _showDeviceDetails,
                              );
                            }
                            return pingResults.fold(
                              (results) => NetworkTopologyMap(
                                devices: devices,
                                pingResults: results,
                                onDeviceTap: _showDeviceDetails,
                              ),
                              (failure) => NetworkTopologyMap(
                                devices: devices,
                                pingResults: {},
                                onDeviceTap: _showDeviceDetails,
                              ),
                            );
                          },
                          loading: () => NetworkTopologyMap(
                            devices: devices,
                            pingResults: {},
                            isLoading: true,
                            onDeviceTap: _showDeviceDetails,
                          ),
                          error: (_, __) => NetworkTopologyMap(
                            devices: devices,
                            pingResults: {},
                            onDeviceTap: _showDeviceDetails,
                          ),
                        );
                      },
                      (failure) => Center(
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
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error loading devices: $error'),
                  ),
                ),
              ),

              // Legend
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legend:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildLegendItem(
                          color: Colors.green,
                          label: 'Good (<50ms)',
                        ),
                        _buildLegendItem(
                          color: Colors.orange,
                          label: 'Medium (50-100ms)',
                        ),
                        _buildLegendItem(
                          color: Colors.red,
                          label: 'Poor (>100ms)',
                        ),
                        _buildLegendItem(
                          color: Colors.grey,
                          label: 'Unknown',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanNetwork() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    // Perform scan asynchronously
    _performScan();
  }

  Future<void> _performScan() async {
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
          _isScanning = false;
        });
      }
    }
  }

  void _showDeviceDetails(Device device, PingResult? pingResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DeviceDetailsBottomSheet(
        device: device,
        pingResult: pingResult,
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// Network topology map
class NetworkTopologyMap extends StatefulWidget {
  final List<Device> devices;
  final Map<String, PingResult> pingResults;
  final Function(Device, PingResult?) onDeviceTap;
  final bool isLoading;

  const NetworkTopologyMap({
    super.key,
    required this.devices,
    required this.pingResults,
    required this.onDeviceTap,
    this.isLoading = false,
  });

  @override
  State<NetworkTopologyMap> createState() => _NetworkTopologyMapState();
}

class _NetworkTopologyMapState extends State<NetworkTopologyMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _animationValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Setup animation controller for data packet animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          _animationValue = _animationController.value;
        });
      });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the available size to determine the layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate the effective radius based on available space and number of devices
    final effectiveRadius = _calculateEffectiveRadius(
        screenWidth, screenHeight, widget.devices.length);

    return Stack(
      children: [
        // Router and connections
        CustomPaint(
          size: Size.infinite,
          painter: NetworkPainter(
            devices: widget.devices,
            pingResults: widget.isLoading ? {} : widget.pingResults,
            isLoading: widget.isLoading,
            effectiveRadius: effectiveRadius,
            animationValue: _animationValue,
          ),
        ),

        // Center router icon/label
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.router,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Router',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Device nodes
        ...widget.devices.map((device) {
          final index = widget.devices.indexOf(device);
          final totalDevices = widget.devices.length;
          final angle = 2 * pi * index / totalDevices;

          // Calculate device position based on angle and effective radius
          // Add a slight offset to account for router's space in the center
          final x = 0.5 + (effectiveRadius * cos(angle));
          final y = 0.5 + (effectiveRadius * sin(angle));

          // Calculate node size based on screen dimensions and device count
          final nodeSize = _calculateNodeSize(
              screenWidth, screenHeight, widget.devices.length);

          // Calculate position adjustments for device node size
          // This ensures they don't go off screen
          final leftAdjustment = nodeSize / 2;
          final topAdjustment = nodeSize / 2;

          return Positioned(
            left: (x * screenWidth) - leftAdjustment,
            top: (y * screenHeight * 0.8) - topAdjustment,
            child: GestureDetector(
              onTap: () => widget.onDeviceTap(
                device,
                widget.isLoading ? null : widget.pingResults[device.ipAddress],
              ),
              child: DeviceNode(
                device: device,
                pingResult: widget.isLoading
                    ? null
                    : widget.pingResults[device.ipAddress],
                isLoading: widget.isLoading,
                size: nodeSize,
              ),
            ),
          );
        }).toList(),

        // Loading overlay
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
      ],
    );
  }

  // Calculate an appropriate radius based on available space and device count
  double _calculateEffectiveRadius(
      double width, double height, int deviceCount) {
    // Base scaling of radius
    final minRadius = 0.1; // Minimum radius (10% of container)
    final maxRadius = 0.35; // Maximum radius (35% of container)

    // Scale radius based on device count
    double scaledRadius;
    if (deviceCount <= 3) {
      scaledRadius = 0.25; // Small circle for few devices
    } else if (deviceCount <= 6) {
      scaledRadius = 0.30; // Medium circle
    } else if (deviceCount <= 12) {
      scaledRadius = 0.33; // Larger circle for more devices
    } else {
      // For many devices, use dynamic scaling with a maximum
      scaledRadius = min(maxRadius, 0.25 + (deviceCount * 0.005));
    }

    // Adjust radius based on aspect ratio to prevent oval distortion
    final aspectRatio = width / height;
    if (aspectRatio > 1.2) {
      // Wide screen - adjust to prevent horizontal overflow
      return min(scaledRadius, 0.35);
    } else if (aspectRatio < 0.8) {
      // Tall screen - adjust to prevent vertical overflow
      return min(scaledRadius, 0.25);
    }

    return scaledRadius;
  }

  // Calculate node size based on screen dimensions and device count
  double _calculateNodeSize(double width, double height, int deviceCount) {
    final minDimension = min(width, height);
    double baseSize;

    // Scale node size inversely with device count
    if (deviceCount <= 4) {
      baseSize = minDimension * 0.14; // 14% of screen for few devices
    } else if (deviceCount <= 8) {
      baseSize = minDimension * 0.12; // 12% for medium count
    } else if (deviceCount <= 16) {
      baseSize = minDimension * 0.10; // 10% for more devices
    } else {
      baseSize = minDimension * 0.08; // 8% for many devices
    }

    // Ensure size is reasonable
    return min(max(baseSize, 60), 80);
  }
}

/// Custom painter for network links
class NetworkPainter extends CustomPainter {
  final List<Device> devices;
  final Map<String, PingResult> pingResults;
  final bool isLoading;
  final double effectiveRadius;
  final double animationValue;

  NetworkPainter({
    required this.devices,
    required this.pingResults,
    required this.isLoading,
    required this.effectiveRadius,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate center point
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;

    // Scale everything based on the shorter dimension to prevent distortion
    final scaleFactor = min(size.width, size.height);

    // Router appearance
    final routerSize = scaleFactor * 0.05; // 5% of available space
    final routerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Router center coordinates for connection lines
    final routerCenter = Offset(centerX, centerY);

    // Draw router area with glow effect
    final routerGlowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(routerCenter, routerSize * 2.0, routerGlowPaint);

    // Draw animated ripple effect for the router
    final rippleSize = routerSize * 2.5 * (0.5 + animationValue * 0.5);
    final rippleOpacity = (1 - animationValue) * 0.3;
    final ripplePaint = Paint()
      ..color = Colors.blue.withOpacity(rippleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(routerCenter, rippleSize, ripplePaint);

    // Draw second ripple with offset phase for continuous effect
    final ripple2Phase = (animationValue + 0.5) % 1.0;
    final ripple2Size = routerSize * 2.5 * (0.5 + ripple2Phase * 0.5);
    final ripple2Opacity = (1 - ripple2Phase) * 0.2;
    final ripple2Paint = Paint()
      ..color = Colors.blue.withOpacity(ripple2Opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(routerCenter, ripple2Size, ripple2Paint);

    // Draw router area outline
    final routerOutlinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(routerCenter, routerSize * 2.0, routerOutlinePaint);

    // Draw connections to each device
    for (int i = 0; i < devices.length; i++) {
      final device = devices[i];
      final angle = 2 * pi * i / devices.length;

      // Calculate device position based on effectiveRadius (as fraction of container)
      final deviceX = centerX + (size.width * effectiveRadius) * cos(angle);
      final deviceY = centerY + (size.height * effectiveRadius) * sin(angle);
      final deviceCenter = Offset(deviceX, deviceY);

      // Determine line color based on ping result
      final pingResult = isLoading ? null : pingResults[device.ipAddress];
      final connectionColor = _getConnectionColor(pingResult);

      // Base line paint
      final linePaint = Paint()
        ..color = connectionColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw connection line with enhanced style
      if (isLoading) {
        _drawDashedLine(canvas, routerCenter, deviceCenter, linePaint);
      } else if (pingResult != null && pingResult.isReachable) {
        // Draw primary connection line
        canvas.drawLine(routerCenter, deviceCenter, linePaint);

        // Draw "glow" effect for active connections
        final glowPaint = Paint()
          ..color = connectionColor.withOpacity(0.2)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;
        canvas.drawLine(routerCenter, deviceCenter, glowPaint);

        // Add "data flow" indicators - small circles along the line
        final packetPositions =
            _calculatePacketPositions(routerCenter, deviceCenter);
        for (final position in packetPositions) {
          final packetPaint = Paint()
            ..color = connectionColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(position, 3, packetPaint);
        }
      } else {
        // Just draw a basic line for offline devices with dotted style
        _drawDashedLine(canvas, routerCenter, deviceCenter, linePaint);
      }

      // Draw ping time if available and not loading
      if (!isLoading &&
          pingResult != null &&
          pingResult.isReachable &&
          pingResult.latency != null) {
        final avgLatency = pingResult.latency!.avg.round();

        // Ensure font size scales with the container
        final fontSize = max(8.0, scaleFactor * 0.02);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$avgLatency ms',
            style: TextStyle(
              fontSize: fontSize,
              color: _getConnectionColor(pingResult),
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Position text in middle of line
        final textX =
            centerX + (deviceX - centerX) * 0.5 - textPainter.width / 2;
        final textY =
            centerY + (deviceY - centerY) * 0.5 - textPainter.height / 2;

        // Add white background for better readability
        final bgRect = Rect.fromLTWH(
          textX - 4,
          textY - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(0.85),
        );

        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  // Calculate positions for data packet indicators along the connection line
  List<Offset> _calculatePacketPositions(Offset start, Offset end) {
    final positions = <Offset>[];

    // Calculate vector from start to end
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Calculate 3 packet positions, offset by animation value for movement
    // Use animation to create flowing data effect
    final baseSpacing = distance / 3;

    // Add some variation to make packets appear to flow
    final adjustedAnimValue = (animationValue * distance) % distance;

    for (int i = 0; i < 3; i++) {
      // Calculate position with animation offset
      final position = (i * baseSpacing + adjustedAnimValue) % distance;
      final factor = position / distance;

      positions.add(Offset(
        start.dx + dx * factor,
        start.dy + dy * factor,
      ));
    }

    return positions;
  }

  // Helper method to draw dashed lines
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double dashWidth = 5;
    final double dashSpace = 3;

    double startX = start.dx;
    double startY = start.dy;
    double endX = end.dx;
    double endY = end.dy;

    // Calculate the distance and direction
    double dx = endX - startX;
    double dy = endY - startY;
    double distance = sqrt(dx * dx + dy * dy);
    double unitX = dx / distance;
    double unitY = dy / distance;

    // Calculate number of segments
    int segments = (distance / (dashWidth + dashSpace)).floor();

    // Draw dash segments
    for (int i = 0; i < segments; i++) {
      double startDashX = startX + unitX * i * (dashWidth + dashSpace);
      double startDashY = startY + unitY * i * (dashWidth + dashSpace);
      double endDashX = startDashX + unitX * dashWidth;
      double endDashY = startDashY + unitY * dashWidth;

      canvas.drawLine(
        Offset(startDashX, startDashY),
        Offset(endDashX, endDashY),
        paint,
      );
    }
  }

  Color _getConnectionColor(PingResult? pingResult) {
    if (pingResult == null) {
      return Colors.grey;
    }

    if (!pingResult.isReachable) {
      return Colors.red;
    }

    if (pingResult.latency != null) {
      final avgLatency = pingResult.latency!.avg;
      if (avgLatency < 50) return Colors.green;
      if (avgLatency < 100) return Colors.orange;
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  bool shouldRepaint(covariant NetworkPainter oldDelegate) {
    return oldDelegate.devices != devices ||
        oldDelegate.pingResults != pingResults ||
        oldDelegate.isLoading != isLoading ||
        oldDelegate.effectiveRadius != effectiveRadius ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Device node widget
class DeviceNode extends StatelessWidget {
  final Device device;
  final PingResult? pingResult;
  final bool isLoading;
  final double? size;

  const DeviceNode({
    super.key,
    required this.device,
    this.pingResult,
    this.isLoading = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isReachable = !isLoading && (pingResult?.isReachable ?? false);
    final statusColor =
        isLoading ? Colors.grey : (isReachable ? Colors.green : Colors.red);

    // Determine appropriate node size based on screen and provided size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final minDimension = min(screenWidth, screenHeight);

    // Default node size is dynamic based on screen size (min 60, max 80)
    final nodeSize = size ?? min(max(minDimension * 0.12, 60), 80);
    final iconSize = nodeSize * 0.35; // Scale icon relative to node size

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withOpacity(0.7),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: iconSize * 0.8,
                    height: iconSize * 0.8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  )
                : Icon(
                    device.type.icon,
                    color: statusColor,
                    size: iconSize,
                  ),
            SizedBox(height: nodeSize * 0.05),
            Text(
              device.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: max(8, nodeSize * 0.14),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              device.ipAddress,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: max(7, nodeSize * 0.12),
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Device details bottom sheet
class DeviceDetailsBottomSheet extends StatelessWidget {
  final Device device;
  final PingResult? pingResult;

  const DeviceDetailsBottomSheet({
    super.key,
    required this.device,
    this.pingResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                device.type.icon,
                size: 36,
                color: device.status.color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      device.type.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (pingResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pingResult!.isReachable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pingResult!.isReachable ? 'Online' : 'Offline',
                    style: TextStyle(
                      color:
                          pingResult!.isReachable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoItem(
            icon: Icons.router,
            label: 'IP Address',
            value: device.ipAddress,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.settings_ethernet,
            label: 'MAC Address',
            value: device.macAddress,
          ),
          if (pingResult != null) ...[
            const Divider(height: 32),
            const Text(
              'Connection Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (pingResult!.isReachable && pingResult!.latency != null) ...[
              _buildInfoItem(
                icon: Icons.speed,
                label: 'Avg Latency',
                value: '${pingResult!.latency!.avg.round()} ms',
                valueColor: _getLatencyColor(pingResult!.latency!.avg),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.arrow_downward,
                      label: 'Min',
                      value: '${pingResult!.latency!.min.round()} ms',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.arrow_upward,
                      label: 'Max',
                      value: '${pingResult!.latency!.max.round()} ms',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                icon: Icons.filter_alt,
                label: 'Packet Loss',
                value: pingResult!.packetLoss ?? '0%',
              ),
            ],
            if (!pingResult!.isReachable)
              _buildInfoItem(
                icon: Icons.error_outline,
                label: 'Error',
                value: pingResult!.error ?? 'Device is not reachable',
                valueColor: Colors.red,
              ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Close'),
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
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getLatencyColor(double latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }
}
