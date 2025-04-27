import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttackLogsScreen extends StatefulWidget {
  final String period;
  final String endpoint;

  const AttackLogsScreen({
    Key? key,
    required this.period,
    required this.endpoint,
  }) : super(key: key);

  @override
  State<AttackLogsScreen> createState() => _AttackLogsScreenState();
}

class _AttackLogsScreenState extends State<AttackLogsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    // This is a placeholder for the actual API call
    // Will be implemented when backend routes are ready

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For now, generate mock data based on period
      setState(() {
        _logs = _generateMockLogs(widget.period);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load attack logs: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateMockLogs(String period) {
    // Generate different number of logs based on the period
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    int count;

    switch (period.toLowerCase()) {
      case 'today':
        count = 3 + random % 3;
        break;
      case 'week':
        count = 8 + random % 5;
        break;
      case 'month':
        count = 15 + random % 10;
        break;
      default:
        count = 20 + random;
    }

    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> logs = [];

    for (int i = 0; i < count; i++) {
      final DateTime timestamp = now.subtract(Duration(
        hours: (period.toLowerCase() == 'today') ? i * 2 : i * 24,
        minutes: (30 + i * 7) % 60,
      ));

      logs.add({
        'id': 'ATK${1000 + i}',
        'timestamp': timestamp,
        'sourceIp': '192.168.0.${100 + i % 150}',
        'targetDevice':
            'Device ${['Laptop', 'Phone', 'TV', 'Smart Speaker'][i % 4]}',
        'type': [
          'Port Scan',
          'DDoS',
          'Brute Force',
          'Man-in-the-Middle'
        ][i % 4],
        'severity': ['Low', 'Medium', 'High', 'Critical'][i % 4],
        'status': i % 5 == 0 ? 'Ongoing' : 'Blocked',
      });
    }

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.period} Attack Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchLogs();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchLogs();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
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
            'Found ${_logs.length} attack ${_logs.length == 1 ? 'record' : 'records'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return _buildLogItem(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy HH:mm');
    final Color severityColor = _getSeverityColor(log['severity']);

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
            _getAttackTypeIcon(log['type']),
            color: severityColor,
            size: 20,
          ),
        ),
        title: Text(
          log['type'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formatter.format(log['timestamp']),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: log['status'] == 'Blocked'
                ? Colors.green[100]
                : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log['status'],
            style: TextStyle(
              color: log['status'] == 'Blocked'
                  ? Colors.green[800]
                  : Colors.red[800],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', log['id']),
                const Divider(),
                _buildDetailRow('Source IP', log['sourceIp']),
                const Divider(),
                _buildDetailRow('Target', log['targetDevice']),
                const Divider(),
                _buildDetailRow('Severity', log['severity'],
                    color: severityColor),
                const Divider(),
                _buildActionButton(log),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> log) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // This would navigate to a detailed incident response screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Details for attack ${log['id']}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.visibility),
        label: const Text('View Full Details'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  IconData _getAttackTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'port scan':
        return Icons.radar;
      case 'ddos':
        return Icons.flash_on;
      case 'brute force':
        return Icons.key;
      case 'man-in-the-middle':
        return Icons.swap_horiz;
      default:
        return Icons.security;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
