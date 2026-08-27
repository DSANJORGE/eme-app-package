class MistakeItem {
  final String id;
  final String question;
  final String topicTitle;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  bool isResolved;

  MistakeItem({
    required this.id,
    required this.question,
    required this.topicTitle,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.isResolved = false,
  });

  MistakeItem copyWith({
    String? id,
    String? question,
    String? topicTitle,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    bool? isResolved,
  }) {
    return MistakeItem(
      id: id ?? this.id,
      question: question ?? this.question,
      topicTitle: topicTitle ?? this.topicTitle,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
