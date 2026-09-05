class JournalModel {
  final int? id;
  final String date; // 'YYYY-MM-DD'
  final String content;
  final int moodLevel; // 1–5
  final String createdAt;

  JournalModel({
    this.id,
    required this.date,
    required this.content,
    this.moodLevel = 3,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'content': content,
      'mood_level': moodLevel,
      'created_at': createdAt,
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String? ?? '',
      moodLevel: map['mood_level'] as int? ?? 3,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  JournalModel copyWith({
    int? id,
    String? date,
    String? content,
    int? moodLevel,
    String? createdAt,
  }) {
    return JournalModel(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      moodLevel: moodLevel ?? this.moodLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
