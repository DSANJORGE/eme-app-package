import 'tutorial.dart';

enum Efficiency { beginner, competent, expert }

class Topic {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final int completedTutorials;
  final int totalTutorials;
  final double answersForgotten;
  final int forgottenPeriod;

  final TutorialProgress progress;

  final List<Tutorial> tutorial;

  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.totalTutorials,
    required this.completedTutorials,
    required this.answersForgotten,
    required this.forgottenPeriod,
    required this.progress,
    this.tutorial = const [],
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      completedTutorials: (json['completed'] as num?)?.toInt() ?? 0,
      totalTutorials: (json['tutorials'] as num?)?.toInt() ?? 0,
      answersForgotten: (json['answersForgotten'] as num?)?.toDouble() ?? 0,
      forgottenPeriod: (json['forgottenPeriod'] as num?)?.toInt() ?? 0,
      progress: json['progress'] != null
          ? TutorialProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : TutorialProgress(
              beginnerProgress: 0,
              competentProgress: 0,
              expertProgress: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'completedTutorials': completedTutorials,
      'totalTutorials': totalTutorials,
      'answersForgotten': answersForgotten,
      'forgottenperiod': forgottenPeriod,
      'progress': progress,
    };
  }
}
