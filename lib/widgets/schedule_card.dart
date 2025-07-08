import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/schedule_service.dart';
import '../models/schedule.dart';

class ScheduleCard extends StatefulWidget {
  final bool isAdminActive;

  const ScheduleCard({
    super.key,
    required this.isAdminActive,
  });

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _durationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addSchedule() async {
    final duration = int.tryParse(_durationController.text) ?? 0;
    
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<ScheduleService>().addSchedule(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        durationMinutes: duration,
      );
      
      if (success) {
        _durationController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule added for ${_selectedTime.format(context)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add schedule'),
              backgroundColor: Colors.red,
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

  Future<void> _removeSchedule(int scheduleId) async {
    try {
      final success = await context.read<ScheduleService>().removeSchedule(scheduleId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule removed'),
            backgroundColor: Colors.blue,
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
    }
  }

  Future<void> _toggleSchedule(int scheduleId, bool enabled) async {
    try {
      await context.read<ScheduleService>().setScheduleEnabled(scheduleId, enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, scheduleService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      scheduleService.activeSchedules.isNotEmpty 
                          ? Icons.schedule 
                          : Icons.schedule_outlined,
                      color: scheduleService.activeSchedules.isNotEmpty 
                          ? Colors.orange 
                          : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scheduled Lock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Next schedule info
                if (scheduleService.activeSchedules.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upcoming, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Next: ${scheduleService.getNextScheduleString()}',
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Add new schedule
                const Text(
                  'Add new schedule:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isAdminActive && !_isLoading ? _selectTime : null,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                          border: OutlineInputBorder(),
                          hintText: '60',
                        ),
                        enabled: widget.isAdminActive && !_isLoading,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.isAdminActive && !_isLoading ? _addSchedule : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                // Existing schedules
                if (scheduleService.schedules.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Active Schedules:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  ...scheduleService.schedules.map((schedule) => 
                    _buildScheduleItem(schedule)
                  ).toList(),
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
                            'Device Administrator privileges required to use schedule functionality.',
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

  Widget _buildScheduleItem(Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          schedule.enabled ? Icons.schedule : Icons.schedule_outlined,
          color: schedule.enabled ? Colors.orange : Colors.grey,
        ),
        title: Text(
          '${schedule.timeString} for ${schedule.durationString}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: schedule.enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          schedule.daysString,
          style: TextStyle(
            fontSize: 12,
            color: schedule.enabled ? Colors.grey[600] : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.enabled,
              onChanged: widget.isAdminActive 
                  ? (value) => _toggleSchedule(schedule.id, value)
                  : null,
              activeColor: Colors.orange,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.isAdminActive 
                  ? () => _removeSchedule(schedule.id)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

