import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/domain/models/ongoing_attack.dart';
import 'package:iotframework/features/security/presentation/providers/ongoing_attacks_provider.dart';

/// Widget that displays a list of ongoing attacks with swipe-to-resolve functionality
class OngoingAttacksList extends ConsumerWidget {
  const OngoingAttacksList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingAttacksState = ref.watch(ongoingAttacksProvider);

    return ongoingAttacksState.when(
      data: (attacks) => _buildAttacksList(context, attacks, ref),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorWidget(context, error, ref),
    );
  }

  Widget _buildAttacksList(
      BuildContext context, List<OngoingAttack> attacks, WidgetRef ref) {
    if (attacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              color: Colors.green[700],
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No ongoing attacks detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: attacks.length,
            itemBuilder: (context, index) {
              final attack = attacks[index];
              return _buildAttackItem(context, attack, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttackItem(
      BuildContext context, OngoingAttack attack, WidgetRef ref) {
    return Dismissible(
      key: Key('attack-${attack.id}'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showConfirmationDialog(context, attack);
      },
      onDismissed: (direction) {
        ref
            .read(ongoingAttacksProvider.notifier)
            .resolveAttack(attack.attackId);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getAttackColor(attack.attackType).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                _getAttackColor(attack.attackType).withOpacity(0.2),
            child: Icon(
              _getAttackTypeIcon(attack.attackType),
              color: _getAttackColor(attack.attackType),
              size: 20,
            ),
          ),
          title: Text(
            _formatAttackType(attack.attackType),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Started: ${DateFormat('MMM dd, yyyy HH:mm').format(attack.startTime)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Ongoing',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load ongoing attacks: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(ongoingAttacksProvider.notifier).loadOngoingAttacks();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, OngoingAttack attack) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Resolve Attack'),
              content: Text(
                  'Are you sure you want to mark this ${_formatAttackType(attack.attackType)} attack as resolved?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Resolve'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _formatAttackType(String attackType) {
    final words = attackType.split('_');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getAttackColor(String attackType) {
    switch (attackType.toLowerCase()) {
      case 'dos':
      case 'ddos':
        return Colors.red;
      case 'brute_force':
        return Colors.orange;
      case 'recon':
      case 'reconnaissance':
        return Colors.amber;
      case 'protocol_fuzzing':
        return Colors.deepPurple;
      case 'mitm':
      case 'man_in_the_middle':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttackTypeIcon(String attackType) {
    switch (attackType.toLowerCase()) {
      case 'dos':
      case 'ddos':
        return Icons.flash_on;
      case 'brute_force':
        return Icons.vpn_key;
      case 'recon':
      case 'reconnaissance':
        return Icons.search;
      case 'protocol_fuzzing':
        return Icons.bug_report;
      case 'mitm':
      case 'man_in_the_middle':
        return Icons.swap_horiz;
      default:
        return Icons.warning_amber;
    }
  }
}
