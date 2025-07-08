import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protection_service.dart';

class ProtectionCard extends StatefulWidget {
  final bool isAdminActive;

  const ProtectionCard({
    super.key,
    required this.isAdminActive,
  });

  @override
  State<ProtectionCard> createState() => _ProtectionCardState();
}

class _ProtectionCardState extends State<ProtectionCard> {
  bool _isLoading = false;

  Future<void> _toggleProtection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final protectionService = context.read<ProtectionService>();
      
      if (protectionService.protectionEnabled) {
        await protectionService.disableProtection();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Protection disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final success = await protectionService.enableProtection();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                    ? 'Protection enabled successfully'
                    : 'Failed to enable protection - Device Administrator required',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _attemptRecovery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<ProtectionService>().attemptRecovery();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Protection recovered successfully'
                  : 'Failed to recover protection',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('active')) {
      return Colors.green;
    } else if (status.contains('compromised')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    if (status.contains('active')) {
      return Icons.shield;
    } else if (status.contains('compromised')) {
      return Icons.shield_outlined;
    } else {
      return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProtectionService>(
      builder: (context, protectionService, child) {
        final statusColor = _getStatusColor(protectionService.protectionStatus);
        final statusIcon = _getStatusIcon(protectionService.protectionStatus);
        final recommendations = protectionService.getRecommendations();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'App Protection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    protectionService.protectionStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  protectionService.protectionEnabled
                      ? 'App protection is monitoring device administrator privileges and attempting to prevent unauthorized changes.'
                      : 'App protection is disabled. Enable it to monitor and protect against unauthorized changes.',
                  style: const TextStyle(fontSize: 14),
                ),
                
                const SizedBox(height: 16),
                
                // Main action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _toggleProtection,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            protectionService.protectionEnabled 
                                ? Icons.shield_outlined 
                                : Icons.shield,
                          ),
                    label: Text(
                      protectionService.protectionEnabled 
                          ? 'Disable Protection' 
                          : 'Enable Protection',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: protectionService.protectionEnabled 
                          ? Colors.red 
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                // Recovery button (if needed)
                if (protectionService.protectionEnabled && !protectionService.adminActive) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _attemptRecovery,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Attempt Recovery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
                
                // Recommendations
                if (recommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recommendations:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...recommendations.map((recommendation) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            recommendation.contains('properly configured')
                                ? Icons.check_circle
                                : Icons.info,
                            size: 16,
                            color: recommendation.contains('properly configured')
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
                
                // Monitoring status
                if (protectionService.protectionEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monitor_heart, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Monitoring Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          protectionService.isMonitoringHealthy
                              ? 'Monitoring is active and healthy'
                              : 'Monitoring may be inactive',
                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                        if (protectionService.getTimeSinceLastCheck() != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Last check: ${protectionService.getTimeSinceLastCheck()!.inSeconds}s ago',
                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                if (!widget.isAdminActive) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Device Administrator privileges required for app protection.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

