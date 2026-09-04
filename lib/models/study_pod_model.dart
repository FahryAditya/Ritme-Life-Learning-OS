class StudyPodModel {
  final int? id;
  final String title;
  final String subtitle;
  final int durationSeconds;
  final int progressSeconds;
  final String audioUrl;
  final String aiNotes;
  final bool isActive;

  StudyPodModel({
    this.id,
    required this.title,
    required this.subtitle,
    required this.durationSeconds,
    this.progressSeconds = 0,
    this.audioUrl = '',
    this.aiNotes = '',
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subtitle': subtitle,
      'duration_seconds': durationSeconds,
      'progress_seconds': progressSeconds,
      'audio_url': audioUrl,
      'ai_notes': aiNotes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory StudyPodModel.fromMap(Map<String, dynamic> map) {
    return StudyPodModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      durationSeconds: map['duration_seconds'] as int? ?? 1200,
      progressSeconds: map['progress_seconds'] as int? ?? 0,
      audioUrl: map['audio_url'] as String? ?? '',
      aiNotes: map['ai_notes'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 0) == 1,
    );
  }

  StudyPodModel copyWith({
    int? id,
    String? title,
    String? subtitle,
    int? durationSeconds,
    int? progressSeconds,
    String? audioUrl,
    String? aiNotes,
    bool? isActive,
  }) {
    return StudyPodModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      aiNotes: aiNotes ?? this.aiNotes,
      isActive: isActive ?? this.isActive,
    );
  }
}
