import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'dart:convert';

class AttackLogsScreen extends ConsumerStatefulWidget {
  final String period;
  final String endpoint;

  const AttackLogsScreen({
    Key? key,
    required this.period,
    required this.endpoint,
  }) : super(key: key);

  @override
  ConsumerState<AttackLogsScreen> createState() => _AttackLogsScreenState();
}

class _AttackLogsScreenState extends ConsumerState<AttackLogsScreen> {
  @override
  Widget build(BuildContext context) {
    // Determine which provider to use based on the period
    final attacksAsync = _getProviderForPeriod(widget.period);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.period} Attack Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the data based on period
              if (widget.period.toLowerCase() == 'today') {
                ref.refresh(todayAttacksProvider);
              } else if (widget.period.toLowerCase() == 'week') {
                ref.refresh(weekAttacksProvider);
              } else if (widget.period.toLowerCase() == 'month') {
                ref.refresh(monthAttacksProvider);
              } else {
                ref.refresh(recentAttacksProvider);
              }
            },
          ),
        ],
      ),
      body: attacksAsync.when(
        data: (result) => result.fold(
          (attacks) => _buildAttackList(attacks),
          (failure) => Center(
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
                  'Error: ${failure.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Refresh based on period
                    if (widget.period.toLowerCase() == 'today') {
                      ref.refresh(todayAttacksProvider);
                    } else if (widget.period.toLowerCase() == 'week') {
                      ref.refresh(weekAttacksProvider);
                    } else if (widget.period.toLowerCase() == 'month') {
                      ref.refresh(monthAttacksProvider);
                    } else {
                      ref.refresh(recentAttacksProvider);
                    }
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  // Helper method to get the appropriate provider based on period
  AsyncValue<dynamic> _getProviderForPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'today':
        return ref.watch(todayAttacksProvider);
      case 'week':
        return ref.watch(weekAttacksProvider);
      case 'month':
        return ref.watch(monthAttacksProvider);
      default:
        return ref.watch(recentAttacksProvider);
    }
  }

  Widget _buildAttackList(List<NetworkTraffic> attacks) {
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
            Text(
              'No attacks detected for ${widget.period.toLowerCase()}',
              style: const TextStyle(
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
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Found ${attacks.length} attack ${attacks.length == 1 ? 'record' : 'records'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: attacks.length,
            itemBuilder: (context, index) {
              final attack = attacks[index];
              return _buildAttackItem(attack);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttackItem(NetworkTraffic attack) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy HH:mm:ss');
    final Color severityColor = _getSeverityColor(attack.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: severityColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.2),
          child: Icon(
            _getAttackTypeIcon(attack.category),
            color: severityColor,
            size: 20,
          ),
        ),
        title: Text(
          attack.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formatter.format(attack.timestamp),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: attack.isResolved ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            attack.isResolved ? 'Resolved' : 'Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: attack.isResolved ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ),
        children: [
          _buildAttackDetails(attack),
        ],
      ),
    );
  }

  Widget _buildAttackDetails(NetworkTraffic attack) {
    // Determine which format the attack is using (new or old)
    final bool isNewFormat =
        attack.dstport == 0 && attack.ethDst.isEmpty && attack.ipDst.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attack Details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Display appropriate fields based on format
          if (isNewFormat)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem('Attack ID', attack.id.toString()),
                _detailItem('Attack Type', attack.category),
                _detailItem(
                    'Start Time',
                    DateFormat('MMM dd, yyyy HH:mm:ss')
                        .format(attack.timestamp)),
                _detailItem(
                    'Status', attack.isResolved ? 'Resolved' : 'Active'),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailItem('Source IP', attack.ipSrc),
                          _detailItem('Source Port', attack.srcport.toString()),
                          _detailItem('Source MAC', attack.ethSrc),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailItem('Destination IP', attack.ipDst),
                          _detailItem(
                              'Destination Port', attack.dstport.toString()),
                          _detailItem('Destination MAC', attack.ethDst),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _detailItem('Category', attack.category),
                _detailItem('Label', attack.label),
                _detailItem(
                    'Timestamp',
                    DateFormat('MMM dd, yyyy HH:mm:ss')
                        .format(attack.timestamp)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAttackTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'xss':
        return Icons.code;
      case 'sql injection':
        return Icons.storage;
      case 'ddos':
        return Icons.network_check;
      case 'port scan':
        return Icons.radar;
      case 'brute force':
        return Icons.key;
      default:
        return Icons.security;
    }
  }

  Color _getSeverityColor(String category) {
    switch (category.toLowerCase()) {
      case 'xss':
        return Colors.red;
      case 'sql injection':
        return Colors.orange;
      case 'brute force':
        return Colors.purple;
      case 'port scan':
        return Colors.blue;
      case 'ddos':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}
