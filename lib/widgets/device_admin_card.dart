import 'package:flutter/material.dart';
import '../services/device_admin_service.dart';

class DeviceAdminCard extends StatefulWidget {
  final bool isAdminActive;
  final Function(bool) onAdminStatusChanged;

  const DeviceAdminCard({
    super.key,
    required this.isAdminActive,
    required this.onAdminStatusChanged,
  });

  @override
  State<DeviceAdminCard> createState() => _DeviceAdminCardState();
}

class _DeviceAdminCardState extends State<DeviceAdminCard> {
  bool _isLoading = false;

  Future<void> _toggleAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool newStatus;
      
      if (widget.isAdminActive) {
        // Remove admin privileges
        await DeviceAdminService.removeAdmin();
        newStatus = false;
      } else {
        // Request admin privileges
        newStatus = await DeviceAdminService.requestAdminPermission();
      }
      
      widget.onAdminStatusChanged(newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus 
                  ? 'Device Administrator enabled successfully'
                  : widget.isAdminActive 
                      ? 'Device Administrator disabled'
                      : 'Failed to enable Device Administrator',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isAdminActive ? Icons.admin_panel_settings : Icons.security,
                  color: widget.isAdminActive ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Device Administrator',
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
                color: widget.isAdminActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isAdminActive ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                widget.isAdminActive ? 'ENABLED' : 'DISABLED',
                style: TextStyle(
                  color: widget.isAdminActive ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              widget.isAdminActive
                  ? 'Device Administrator privileges are active. The app can lock and unlock your screen.'
                  : 'Device Administrator privileges are required for screen lock/unlock functionality.',
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _toggleAdmin,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        widget.isAdminActive ? Icons.remove_circle : Icons.add_circle,
                      ),
                label: Text(
                  widget.isAdminActive ? 'Disable Administrator' : 'Enable Administrator',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isAdminActive ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            if (!widget.isAdminActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be prompted to grant Device Administrator permissions. This is required for the app to function.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
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
  }
}

