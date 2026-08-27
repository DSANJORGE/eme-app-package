class DailyChallengeItem {
  final String id;
  final DateTime date;
  final String dayLabel;
  final String dateLabel;
  final String title;
  final int totalQuestions;
  int completedQuestions;
  double progress;
  final bool isToday;

  DailyChallengeItem({
    required this.id,
    required this.date,
    required this.dayLabel,
    required this.dateLabel,
    required this.title,
    required this.totalQuestions,
    required this.completedQuestions,
    double? progress,
    this.isToday = false,
  }) : progress = progress ??
            (totalQuestions > 0 ? (completedQuestions / totalQuestions).clamp(0.0, 1.0) : 0.0);

  bool get isCompleted => progress >= 1.0;

  void complete() {
    completedQuestions = totalQuestions;
    progress = 1.0;
  }

  void updateProgress(int completed) {
    completedQuestions = completed.clamp(0, totalQuestions);
    progress = totalQuestions > 0 ? (completedQuestions / totalQuestions).clamp(0.0, 1.0) : 0.0;
  }
}
