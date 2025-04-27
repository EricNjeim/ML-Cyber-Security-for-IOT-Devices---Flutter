import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/features/network_map/presentation/widgets/device_node.dart';
import 'package:iotframework/features/network_map/presentation/widgets/network_painter.dart';

/// =========================  NEW NetworkTopologyMap  ========================
class NetworkTopologyMap extends StatefulWidget {
  final List<Device> devices;
  final Map<String, PingResult> pingResults;
  final void Function(Device, PingResult?) onDeviceTap;
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
  late final AnimationController _animCtrl;
  late double _animValue;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() => setState(() => _animValue = _animCtrl.value));
    _animCtrl.repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Work in logical pixels inside safe-area.
        final Size size = constraints.biggest;
        final double maxExtent =
            min(size.width, size.height) * 0.35; // Adjusted for device spacing
        final double nodeSize = _calculateNodeSize(
            min(size.width, size.height), widget.devices.length);
        final double minSpacing = nodeSize * 0.25; // tweakable gap

        /// Generate polar coordinates for every device on concentric rings
        final List<_PolarPos> positions = _placeOnRings(
          count: widget.devices.length,
          nodeDiameter: nodeSize + minSpacing,
          maxRadius: maxExtent,
        );

        /// Paint links first (keeps them under the nodes)
        final painter = NetworkPainter(
          devices: widget.devices,
          pingResults: widget.isLoading ? {} : widget.pingResults,
          isLoading: widget.isLoading,
          effectiveRadius: 0, // no longer used inside painter
          animationValue: _animValue,
        );

        return Stack(
          children: [
            // Background lines and effects
            CustomPaint(size: size, painter: painter),

            // Central router icon with improved appearance
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 3,
                        )
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.router,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: const Text(
                      'Router',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Device nodes
            ...List.generate(widget.devices.length, (i) {
              final device = widget.devices[i];
              final Offset cart = positions[i].toCartesian(size);
              return Positioned(
                left: cart.dx - nodeSize / 2,
                top: cart.dy - nodeSize / 2,
                child: GestureDetector(
                  onTap: () => widget.onDeviceTap(
                    device,
                    widget.isLoading
                        ? null
                        : widget.pingResults[device.ipAddress],
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
            }),

            if (widget.isLoading)
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.05)),
              ),
          ],
        );
      },
    );
  }

  // --- helpers --------------------------------------------------------------

  double _calculateNodeSize(double minDimension, int count) {
    if (count <= 4) return min(max(minDimension * .14, 60), 90);
    if (count <= 8) return min(max(minDimension * .12, 50), 80);
    if (count <= 20) return min(max(minDimension * .10, 45), 70);
    return min(max(minDimension * .08, 40), 60);
  }

  /// Greedy placement on rings: keeps adding devices to the current ring
  /// until there's no room, then starts a new outer ring.
  List<_PolarPos> _placeOnRings({
    required int count,
    required double nodeDiameter,
    required double maxRadius,
  }) {
    final List<_PolarPos> out = [];

    double r = nodeDiameter * 1.2; // keep first ring away from router
    int placed = 0;

    while (placed < count && r <= maxRadius) {
      final int capacity =
          max(1, (2 * pi * r / nodeDiameter).floor()); // nodes this ring
      final int toPlace = min(capacity, count - placed);
      final double angleStep = 2 * pi / toPlace;

      for (int i = 0; i < toPlace; i++) {
        out.add(_PolarPos(radius: r, theta: i * angleStep));
      }
      placed += toPlace;
      r += nodeDiameter * 1.1; // next ring 10 % further out
    }

    // Fallback: if we ran out of space, stack leftovers at the edge
    while (placed < count) {
      out.add(_PolarPos(radius: maxRadius, theta: 0));
      placed++;
    }
    return out;
  }
}

/// Simple polar coordinate holder
class _PolarPos {
  final double radius;
  final double theta; // radians

  const _PolarPos({required this.radius, required this.theta});

  Offset toCartesian(Size canvas) => Offset(
        canvas.width / 2 + radius * cos(theta),
        canvas.height / 2 + radius * sin(theta),
      );
}
