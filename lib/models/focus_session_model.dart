class FocusSessionModel {
  final int? id;
  final int? taskId;
  final String taskTitle;
  final int durationMinutes;
  final String sessionType; // 'focus' or 'break'
  final String completedAt; // ISO8601 DateTime string

  FocusSessionModel({
    this.id,
    this.taskId,
    this.taskTitle = 'Sesi Bebas',
    required this.durationMinutes,
    this.sessionType = 'focus',
    String? completedAt,
  }) : completedAt = completedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'duration_minutes': durationMinutes,
      'session_type': sessionType,
      'completed_at': completedAt,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as int?,
      taskId: map['task_id'] as int?,
      taskTitle: map['task_title'] as String? ?? 'Sesi Bebas',
      durationMinutes: map['duration_minutes'] as int? ?? 25,
      sessionType: map['session_type'] as String? ?? 'focus',
      completedAt: map['completed_at'] as String? ?? '',
    );
  }
}
