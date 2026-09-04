class TaskModel {
  final int? id;
  final String title;
  final String category; // 'Deep Work', 'Light Admin', 'Creative', etc.
  final bool isUrgent;
  final bool isImportant;
  final int cognitiveLoad; // percentage 0 - 100
  final int bpm;
  final String genre;
  final bool isActive;
  final bool isCompleted;
  final String scheduledTime; // e.g. '14:00'
  final String createdAt;

  TaskModel({
    this.id,
    required this.title,
    required this.category,
    this.isUrgent = true,
    this.isImportant = true,
    this.cognitiveLoad = 80,
    this.bpm = 62,
    this.genre = 'Lo-Fi Ambient Instrumental',
    this.isActive = false,
    this.isCompleted = false,
    this.scheduledTime = 'Sekarang',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'is_urgent': isUrgent ? 1 : 0,
      'is_important': isImportant ? 1 : 0,
      'cognitive_load': cognitiveLoad,
      'bpm': bpm,
      'genre': genre,
      'is_active': isActive ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'scheduled_time': scheduledTime,
      'created_at': createdAt,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      isUrgent: (map['is_urgent'] as int? ?? 1) == 1,
      isImportant: (map['is_important'] as int? ?? 1) == 1,
      cognitiveLoad: map['cognitive_load'] as int? ?? 80,
      bpm: map['bpm'] as int? ?? 62,
      genre: map['genre'] as String? ?? 'Lo-Fi Ambient',
      isActive: (map['is_active'] as int? ?? 0) == 1,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      scheduledTime: map['scheduled_time'] as String? ?? 'Sekarang',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? category,
    bool? isUrgent,
    bool? isImportant,
    int? cognitiveLoad,
    int? bpm,
    String? genre,
    bool? isActive,
    bool? isCompleted,
    String? scheduledTime,
    String? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      cognitiveLoad: cognitiveLoad ?? this.cognitiveLoad,
      bpm: bpm ?? this.bpm,
      genre: genre ?? this.genre,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
