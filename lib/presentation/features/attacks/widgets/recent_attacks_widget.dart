import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/presentation/features/attacks/providers/recent_attacks_provider.dart';

/// Widget that displays recent network attacks
class RecentAttacksWidget extends ConsumerWidget {
  const RecentAttacksWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recentAttacksProvider);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.errorMessage != null)
              Center(
                child: Text(
                  'Error: ${state.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (state.attacks.isEmpty)
              const Center(
                child: Text('No recent network activity'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: state.attacks.length,
                  itemBuilder: (context, index) {
                    final traffic = state.attacks[index];
                    return _buildTrafficItem(context, traffic);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficItem(BuildContext context, NetworkTraffic traffic) {
    final isAttack = traffic.isAttack;
    final dateFormat = DateFormat('MMM dd, HH:mm:ss');
    final formattedDate = dateFormat.format(traffic.timestamp);

    return Card(
      color: isAttack ? Colors.red.shade50 : Colors.green.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Icon(
              isAttack ? Icons.warning_amber : Icons.check_circle,
              color: isAttack ? Colors.red : Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${traffic.ipSrc} → ${traffic.ipDst}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${traffic.category}'),
            Text('Label: ${traffic.label}'),
            Text('Ports: ${traffic.srcport} → ${traffic.dstport}'),
            Text('Time: $formattedDate'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
 