import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

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
    final center = Offset(size.width / 2, size.height / 2);

    // Draw background
    _drawBackgroundEffect(canvas, size, center);

    // Draw circular grid lines
    _drawCircularGrid(canvas, center, min(size.width, size.height) * 0.35);

    // Draw device connections
    for (final device in devices) {
      _drawConnection(
          canvas, center, _getDevicePosition(center, device), device);
    }

    // Draw animated data packets on connections
    for (final device in devices) {
      _drawDataPackets(
          canvas, center, _getDevicePosition(center, device), device);
    }

    // Draw ripple effect around router
    _drawRouterEffects(canvas, center);
  }

  void _drawBackgroundEffect(Canvas canvas, Size size, Offset center) {
    final Rect rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    final gradient = RadialGradient(
      colors: [
        Colors.blue.withOpacity(0.15),
        Colors.blue.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final Paint bgPaint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRect(rect, bgPaint);
  }

  void _drawCircularGrid(Canvas canvas, Offset center, double maxRadius) {
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final radius = maxRadius * (i / 3);
      canvas.drawCircle(center, radius, gridPaint);
    }
  }

  Offset _getDevicePosition(Offset center, Device device) {
    final angle = (devices.indexOf(device) / devices.length) * 2 * pi;
    final distance = min(center.dx, center.dy) *
        0.7; // Increased distance for better spacing

    return Offset(
      center.dx + distance * cos(angle),
      center.dy + distance * sin(angle),
    );
  }

  void _drawConnection(Canvas canvas, Offset start, Offset end, Device device) {
    final isReachable = pingResults[device.ipAddress]?.isReachable ?? false;
    final pingLatency = pingResults[device.ipAddress]?.latency;
    final pingTime = pingLatency?.avg.round() ?? 0;

    final Paint linePaint = Paint()
      ..strokeWidth = isReachable ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;

    // Define connection color based on ping result
    if (isLoading) {
      linePaint.color = Colors.grey.withOpacity(0.3);
    } else if (isReachable) {
      // Apply color based on ping time
      if (pingTime < 50) {
        linePaint.color = Colors.green.shade400;
      } else if (pingTime < 100) {
        linePaint.color = Colors.orange.shade400;
      } else {
        linePaint.color = Colors.red.shade400;
      }

      // Add glow effect for active connections
      final glowPaint = Paint()
        ..color = linePaint.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawLine(start, end, glowPaint);
    } else {
      linePaint.color = Colors.grey.withOpacity(0.4);
      linePaint.strokeWidth = 1.0;

      // Draw dashed line for unreachable devices
      final dashSize = 4.0;
      final gapSize = 4.0;
      _drawDashedLine(canvas, start, end, dashSize, gapSize, linePaint);
      return;
    }

    canvas.drawLine(start, end, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double dashSize,
      double gapSize, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var currentPoint = start;
    var remainingDistance = distance;

    while (remainingDistance > 0) {
      final dashDistance = min(dashSize, remainingDistance);
      if (dashDistance > 0) {
        final nextPoint = Offset(
          currentPoint.dx + unitDx * dashDistance,
          currentPoint.dy + unitDy * dashDistance,
        );
        canvas.drawLine(currentPoint, nextPoint, paint);
        currentPoint = nextPoint;
        remainingDistance -= dashDistance;
      }

      // Skip gap
      final gapDistance = min(gapSize, remainingDistance);
      if (gapDistance > 0) {
        currentPoint = Offset(
          currentPoint.dx + unitDx * gapDistance,
          currentPoint.dy + unitDy * gapDistance,
        );
        remainingDistance -= gapDistance;
      }
    }
  }

  void _drawDataPackets(
      Canvas canvas, Offset start, Offset end, Device device) {
    final isReachable = pingResults[device.ipAddress]?.isReachable ?? false;

    if (!isReachable || isLoading) return;

    // Calculate packet positions
    final positions = _calculatePacketPositions(start, end);

    final Paint packetPaint = Paint()..style = PaintingStyle.fill;

    final pingLatency = pingResults[device.ipAddress]?.latency;
    final pingTime = pingLatency?.avg.round() ?? 0;

    // Determine packet color based on ping time
    if (pingTime < 50) {
      packetPaint.color = Colors.green.shade500;
    } else if (pingTime < 100) {
      packetPaint.color = Colors.orange.shade500;
    } else {
      packetPaint.color = Colors.red.shade500;
    }

    // Draw packets - moving in both directions for bidirectional data flow
    for (final position in positions) {
      // Outbound packet (from router to device)
      final outboundPos = position.outbound;
      canvas.drawCircle(outboundPos, 3.0, packetPaint);

      // Draw a smaller trailing effect for outbound
      canvas.drawCircle(
          outboundPos,
          5.0,
          Paint()
            ..color = packetPaint.color.withOpacity(0.3)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

      // Inbound packet (from device to router)
      final inboundPos = position.inbound;

      // For inbound, use a different shape - small rectangle/diamond
      canvas.save();
      canvas.translate(inboundPos.dx, inboundPos.dy);
      canvas.rotate(atan2(end.dy - start.dy, end.dx - start.dx));

      // Draw small diamond for inbound data
      final path = Path()
        ..moveTo(0, -2)
        ..lineTo(3, 0)
        ..lineTo(0, 2)
        ..lineTo(-3, 0)
        ..close();

      canvas.drawPath(
          path,
          Paint()
            ..color = packetPaint.color
            ..style = PaintingStyle.fill);

      canvas.restore();
    }
  }

  List<_PacketPositions> _calculatePacketPositions(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    // We'll create 2 packets along each connection
    final List<_PacketPositions> packets = [];

    // Use the animation value to move the packets along the line
    for (int i = 0; i < 2; i++) {
      // Calculate position for two-way traffic
      double progress = (animationValue + i * 0.5) % 1.0;

      // Outbound packet (router to device)
      final outboundProgress = progress;
      final outboundPos = Offset(
        start.dx + unitDx * distance * outboundProgress,
        start.dy + unitDy * distance * outboundProgress,
      );

      // Inbound packet (device to router)
      final inboundProgress = (1.0 - progress);
      final inboundPos = Offset(
        start.dx + unitDx * distance * inboundProgress,
        start.dy + unitDy * distance * inboundProgress,
      );

      packets.add(_PacketPositions(outboundPos, inboundPos));
    }

    return packets;
  }

  void _drawRouterEffects(Canvas canvas, Offset center) {
    // Draw ripple effect
    final rippleCount = 3;

    for (int i = 0; i < rippleCount; i++) {
      final rippleProgress = (animationValue + i / rippleCount) % 1.0;
      final rippleRadius = rippleProgress * 25.0;
      final opacity = (1.0 - rippleProgress);

      final ripplePaint = Paint()
        ..color = Colors.blue.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(NetworkPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isLoading != isLoading ||
        oldDelegate.pingResults != pingResults;
  }
}

// Helper class to store packet positions for bidirectional traffic
class _PacketPositions {
  final Offset outbound;
  final Offset inbound;

  _PacketPositions(this.outbound, this.inbound);
}
