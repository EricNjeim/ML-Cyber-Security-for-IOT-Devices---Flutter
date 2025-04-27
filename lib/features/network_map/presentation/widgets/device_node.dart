import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

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
