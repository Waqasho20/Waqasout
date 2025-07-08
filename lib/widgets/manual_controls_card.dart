import 'package:flutter/material.dart';
import '../services/device_admin_service.dart';

class ManualControlsCard extends StatefulWidget {
  final bool isAdminActive;

  const ManualControlsCard({
    super.key,
    required this.isAdminActive,
  });

  @override
  State<ManualControlsCard> createState() => _ManualControlsCardState();
}

class _ManualControlsCardState extends State<ManualControlsCard> {
  bool _isLocking = false;
  bool _isUnlocking = false;

  Future<void> _lockScreen() async {
    setState(() {
      _isLocking = true;
    });

    try {
      final success = await DeviceAdminService.lockScreen();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Screen locked successfully'
                  : 'Failed to lock screen',
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
          _isLocking = false;
        });
      }
    }
  }

  Future<void> _unlockScreen() async {
    setState(() {
      _isUnlocking = true;
    });

    try {
      final success = await DeviceAdminService.unlockScreen();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Screen unlocked successfully'
                  : 'Failed to unlock screen',
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
          _isUnlocking = false;
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
            const Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.purple,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Manual Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            const Text(
              'Instantly lock or unlock your device screen:',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isAdminActive && !_isLocking && !_isUnlocking 
                        ? _lockScreen 
                        : null,
                    icon: _isLocking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock),
                    label: const Text('Lock Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isAdminActive && !_isLocking && !_isUnlocking 
                        ? _unlockScreen 
                        : null,
                    icon: _isUnlocking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: const Text('Unlock Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lock Now: Immediately locks the device screen\n'
                      'Unlock Now: Removes screen lock (may clear password/PIN)',
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            
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
                        'Device Administrator privileges required to use manual controls.',
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
  }
}

