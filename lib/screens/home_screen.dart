import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/schedule_service.dart';
import '../services/protection_service.dart';
import '../services/device_admin_service.dart';
import '../widgets/device_admin_card.dart';
import '../widgets/timer_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/protection_card.dart';
import '../widgets/manual_controls_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdminActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check admin status
      _isAdminActive = await DeviceAdminService.isAdminActive();
      
      // Initialize services
      if (mounted) {
        await context.read<ScheduleService>().initialize();
        await context.read<ProtectionService>().refreshStatus();
      }
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _isAdminActive = await DeviceAdminService.isAdminActive();
      
      if (mounted) {
        await context.read<ScheduleService>().loadSchedules();
        await context.read<ProtectionService>().refreshStatus();
      }
    } catch (e) {
      print('Error refreshing status: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Lock App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Device Admin Status Card
                    DeviceAdminCard(
                      isAdminActive: _isAdminActive,
                      onAdminStatusChanged: (bool newStatus) {
                        setState(() {
                          _isAdminActive = newStatus;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Manual Controls Card
                    ManualControlsCard(
                      isAdminActive: _isAdminActive,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Timer Card
                    TimerCard(
                      isAdminActive: _isAdminActive,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Schedule Card
                    ScheduleCard(
                      isAdminActive: _isAdminActive,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Protection Card
                    ProtectionCard(
                      isAdminActive: _isAdminActive,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Screen Lock App uses Device Administrator privileges to automatically lock and unlock your device screen based on timers and schedules.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Features:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '• Timer-based automatic lock/unlock\n'
                              '• Scheduled lock/unlock at specific times\n'
                              '• Manual lock/unlock controls\n'
                              '• Protection against uninstallation\n'
                              '• Persistent state across app restarts',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

