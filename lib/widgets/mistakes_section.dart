import 'package:flutter/material.dart';
import 'package:flutter_eme_base/l10n/app_localizations.dart';
import '../models/mistake_item.dart';

class MistakesSection extends StatelessWidget {
  final List<MistakeItem> mistakes;
  final Function(MistakeItem mistake) onMistakeResolved;
  final VoidCallback? onAllMistakesResolved;

  const MistakesSection({
    super.key,
    required this.mistakes,
    required this.onMistakeResolved,
    this.onAllMistakesResolved,
  });

  List<MistakeItem> get unresolvedMistakes =>
      mistakes.where((m) => !m.isResolved).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unresolved = unresolvedMistakes;
    final hasMistakes = unresolved.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF50057).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.replay_circle_filled_rounded,
                color: Color(0xFFF50057),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.mistakes,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF38B6FF),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (hasMistakes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF50057).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF50057).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  l10n.questionsToRedo(unresolved.length.toString()),
                  style: const TextStyle(
                    color: Color(0xFFF50057),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MistakesPracticeModal extends StatefulWidget {
  final List<MistakeItem> initialMistakes;
  final Function(MistakeItem mistake) onMistakeResolved;
  final VoidCallback? onAllMistakesResolved;
  final AppLocalizations l10n;

  const _MistakesPracticeModal({
    required this.initialMistakes,
    required this.onMistakeResolved,
    this.onAllMistakesResolved,
    required this.l10n,
  });

  @override
  State<_MistakesPracticeModal> createState() => _MistakesPracticeModalState();
}

class _MistakesPracticeModalState extends State<_MistakesPracticeModal> {
  late List<MistakeItem> _activeMistakes;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerSubmitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _activeMistakes = List.from(widget.initialMistakes);
  }

  MistakeItem? get currentMistake {
    if (_currentIndex < _activeMistakes.length) {
      return _activeMistakes[_currentIndex];
    }
    return null;
  }

  void _submitAnswer() {
    final mistake = currentMistake;
    if (mistake == null || _selectedOptionIndex == null) return;

    final isCorrect = _selectedOptionIndex == mistake.correctOptionIndex;
    setState(() {
      _isAnswerSubmitted = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      widget.onMistakeResolved(mistake);
    }
  }

  void _nextQuestion() {
    if (_isCorrect && currentMistake != null) {
      _activeMistakes.removeAt(_currentIndex);
    } else {
      _currentIndex++;
    }

    if (_currentIndex >= _activeMistakes.length) {
      _currentIndex = 0;
    }

    setState(() {
      _selectedOptionIndex = null;
      _isAnswerSubmitted = false;
      _isCorrect = false;
    });

    if (_activeMistakes.isEmpty) {
      widget.onAllMistakesResolved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mistake = currentMistake;
    final isAllDone = _activeMistakes.isEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161C24),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: isAllDone
            ? _buildAllDoneView(context)
            : _buildQuestionView(context, mistake!),
      ),
    );
  }

  Widget _buildAllDoneView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.celebration_rounded,
            color: Color(0xFF00E676),
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.l10n.allMistakesCleared,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.l10n.noMistakesToRedo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38B6FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuestionView(BuildContext context, MistakeItem mistake) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF50057).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${mistake.topicTitle} • ${_currentIndex + 1}/${_activeMistakes.length}',
                  style: const TextStyle(
                    color: Color(0xFFF50057),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Text
          Text(
            mistake.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Options List
          ...List.generate(mistake.options.length, (index) {
            final option = mistake.options[index];
            final isSelected = _selectedOptionIndex == index;
            final isCorrectOption = index == mistake.correctOptionIndex;

            Color borderColor = Colors.white.withValues(alpha: 0.08);
            Color bgColor = const Color(0xFF1E2638);
            Color textColor = Colors.white70;

            if (_isAnswerSubmitted) {
              if (isCorrectOption) {
                borderColor = const Color(0xFF00E676);
                bgColor = const Color(0xFF00E676).withValues(alpha: 0.15);
                textColor = const Color(0xFF00E676);
              } else if (isSelected && !_isCorrect) {
                borderColor = const Color(0xFFF50057);
                bgColor = const Color(0xFFF50057).withValues(alpha: 0.15);
                textColor = const Color(0xFFF50057);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFF38B6FF);
              bgColor = const Color(0xFF38B6FF).withValues(alpha: 0.15);
              textColor = Colors.white;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isAnswerSubmitted
                      ? null
                      : () {
                          setState(() {
                            _selectedOptionIndex = index;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_isAnswerSubmitted && isCorrectOption)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF00E676),
                            size: 20,
                          )
                        else if (_isAnswerSubmitted &&
                            isSelected &&
                            !_isCorrect)
                          const Icon(
                            Icons.cancel_rounded,
                            color: Color(0xFFF50057),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Feedback / Explanation
          if (_isAnswerSubmitted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? const Color(0xFF00E676).withValues(alpha: 0.1)
                    : const Color(0xFFF50057).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect
                      ? const Color(0xFF00E676).withValues(alpha: 0.3)
                      : const Color(0xFFF50057).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: _isCorrect
                            ? const Color(0xFF00E676)
                            : const Color(0xFFF50057),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isCorrect
                              ? const Color(0xFF00E676)
                              : const Color(0xFFF50057),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mistake.explanation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Button (Submit or Next)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedOptionIndex == null
                  ? null
                  : _isAnswerSubmitted
                  ? _nextQuestion
                  : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAnswerSubmitted
                    ? (_isCorrect
                          ? const Color(0xFF00E676)
                          : const Color(0xFF38B6FF))
                    : const Color(0xFF38B6FF),
                foregroundColor: _isAnswerSubmitted && _isCorrect
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isAnswerSubmitted
                    ? (_isCorrect ? 'Continue' : 'Retry Question')
                    : 'Submit Answer',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
