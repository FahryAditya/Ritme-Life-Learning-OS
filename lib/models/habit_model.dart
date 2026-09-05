class HabitModel {
  final int? id;
  final String title;
  final String category;
  final int streakCount;
  final bool isCompletedToday;
  final String lastCompletedDate;

  HabitModel({
    this.id,
    required this.title,
    required this.category,
    this.streakCount = 0,
    this.isCompletedToday = false,
    this.lastCompletedDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'streak_count': streakCount,
      'is_completed_today': isCompletedToday ? 1 : 0,
      'last_completed_date': lastCompletedDate,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'Umum',
      streakCount: map['streak_count'] as int? ?? 0,
      isCompletedToday: (map['is_completed_today'] as int? ?? 0) == 1,
      lastCompletedDate: map['last_completed_date'] as String? ?? '',
    );
  }

  HabitModel copyWith({
    int? id,
    String? title,
    String? category,
    int? streakCount,
    bool? isCompletedToday,
    String? lastCompletedDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      streakCount: streakCount ?? this.streakCount,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
