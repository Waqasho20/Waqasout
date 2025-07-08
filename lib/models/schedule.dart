class Schedule {
  final int id;
  final int hour;
  final int minute;
  final int durationMinutes;
  final bool enabled;
  final Set<int> daysOfWeek;

  Schedule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.enabled = true,
    Set<int>? daysOfWeek,
  }) : daysOfWeek = daysOfWeek ?? {1, 2, 3, 4, 5, 6, 7}; // Default to all days

  /// Create Schedule from map (from platform channel)
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] ?? 0,
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
      durationMinutes: map['duration'] ?? 0,
      enabled: map['enabled'] ?? true,
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)?.cast<int>().toSet(),
    );
  }

  /// Convert Schedule to map (for platform channel)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'duration': durationMinutes,
      'enabled': enabled,
      'daysOfWeek': daysOfWeek.toList(),
    };
  }

  /// Get formatted time string (HH:MM)
  String get timeString {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration string
  String get durationString {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  /// Get days of week as readable string
  String get daysString {
    if (daysOfWeek.length == 7) {
      return 'Every day';
    } else if (daysOfWeek.length == 5 && 
               daysOfWeek.containsAll([1, 2, 3, 4, 5])) {
      return 'Weekdays';
    } else if (daysOfWeek.length == 2 && 
               daysOfWeek.containsAll([6, 7])) {
      return 'Weekends';
    } else {
      final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final selectedDays = daysOfWeek.map((day) => dayNames[day]).toList();
      selectedDays.sort();
      return selectedDays.join(', ');
    }
  }

  /// Create a copy with modified fields
  Schedule copyWith({
    int? id,
    int? hour,
    int? minute,
    int? durationMinutes,
    bool? enabled,
    Set<int>? daysOfWeek,
  }) {
    return Schedule(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  @override
  String toString() {
    return 'Schedule(id: $id, time: $timeString, duration: $durationString, enabled: $enabled, days: $daysString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        other.id == id &&
        other.hour == hour &&
        other.minute == minute &&
        other.durationMinutes == durationMinutes &&
        other.enabled == enabled &&
        other.daysOfWeek.length == daysOfWeek.length &&
        other.daysOfWeek.containsAll(daysOfWeek);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      hour,
      minute,
      durationMinutes,
      enabled,
      Object.hashAll(daysOfWeek),
    );
  }
}

