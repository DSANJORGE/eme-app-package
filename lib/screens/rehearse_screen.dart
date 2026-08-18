import 'dart:async';
import 'dart:math';

import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_eme_base/models/chat_message.dart' as socket_msg;
import 'package:flutter_eme_base/models/chat_message.dart';
import 'package:flutter_eme_base/models/topic.dart';
import 'package:flutter_eme_base/services/auth_service.dart';
import 'package:flutter_eme_base/services/chat_socket_service.dart';
import 'package:flutter_eme_base/services/topic_service.dart';
import 'package:flutter_eme_base/utils/log.dart';
import 'package:flutter_eme_base/widgets/common_widgets.dart';
import 'package:flutter_eme_base/widgets/fullscreen_mediaviewer.dart';
import 'package:flutter_eme_base/widgets/asset_message_widget.dart';
import 'package:transparent_image/transparent_image.dart';

import '../models/tutor_channel.dart';
import '../models/tutorial.dart';
import '../utils/error_handler.dart';

enum MessageStage {
  loading,
  error,
  ready,
  selectOption,
  finished,
  explainAndFollowup;

  bool get isLoading => this == MessageStage.loading;
  bool get isError => this == MessageStage.error;
  bool get isReady => this == MessageStage.ready;
  bool get isSelectOption => this == MessageStage.selectOption;
  bool get isFinished => this == MessageStage.finished;
  bool get isExplainAndFollowup => this == MessageStage.explainAndFollowup;
}

class RehearseScreen extends StatefulWidget {
  final Tutorial tutorial;

  const RehearseScreen({super.key, required this.tutorial});

  @override
  State<RehearseScreen> createState() => _RehearseScreenState();
}

class _RehearseScreenState extends State<RehearseScreen> {
  bool _isLoading = true;
  TutorChannel? _tutorChannel;
  StreamSubscription<socket_msg.ChatMessage>? _socketSubscription;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _followUpController = TextEditingController();

  bool _isFinished = false;

  // Chat state
  final List<ChatMessage> _messages = [];
  ChatMessage? _lastMessage;
  OptionsKey? _tempSelectedAnswerIndex;
  Confidence? _tempConfidenceLevel;
  MessageStage _stage = MessageStage.loading;

  @override
  void initState() {
    super.initState();
    _loadTutorialDetail();
  }

  Future<void> _loadTutorialDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _messages.clear();
      _lastMessage = null;

      final channel = await TopicService().fetchTutorChannel(
        widget.tutorial.id,
      );
      if (channel == null) {
        setState(() {
          _stage = MessageStage.error;
          _isLoading = false;
        });
        return;
      }

      _tutorChannel = channel;

      if (_tutorChannel != null) {
        final messageHistory = await TopicService().fetchTutorHistory(
          channelId: _tutorChannel!.id,
        );

        if (messageHistory.isNotEmpty) {
          setState(() {
            _messages.addAll(messageHistory);
            _lastMessage = _messages.last;
          });
        }
        await ChatSocketService().connect(channel: _tutorChannel!.id);
        _socketSubscription?.cancel();
        _socketSubscription = ChatSocketService().messageStream.listen((
          incomingMsg,
        ) {
          logPrint("ChatSocketService incomingMsg: ${incomingMsg.toJson()}");
          if (incomingMsg.isKeepAlive || incomingMsg.isMessageRemoved) return;
          if (!mounted) return;

          if (incomingMsg.messageType.isProgressUpdate) {
            setState(() {
              widget.tutorial.progress = TutorialProgress.fromJson(
                incomingMsg.progressUpdate?.toJson() ?? {},
                widget.tutorial.progress,
              );
            });
            logPrint(
              'Update TutorialProgress: ${widget.tutorial.progress.toJson()}',
            );
            return;
          }

          setState(() {
            _messages.add(incomingMsg);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _lastMessage = _messages.last;

            if (_lastMessage!.messageType.isWelcome) {
              setState(() {
                _stage = MessageStage.ready;
              });
            } else if (_lastMessage!.messageType.isQuestion) {
              setState(() {
                _tempSelectedAnswerIndex = null;
                _tempConfidenceLevel = null;
                _stage = MessageStage.selectOption;
              });
            } else if (_lastMessage!.messageType.isEnd) {
              setState(() {
                _stage = MessageStage.finished;
              });
              _isFinished = true;
            } else {
              setState(() {
                _stage = MessageStage.explainAndFollowup;
              });
            }
          });
          _scrollToBottom();
        });

        if (_messages.isEmpty) {
          await TopicService().startTutorial(
            tutorialId: widget.tutorial.id,
            channel: _tutorChannel!.id,
          );
        } else {
          logPrint('Last message: ${_lastMessage?.messageType}');
          if (_lastMessage != null) {
            if (_lastMessage!.messageType.isWelcome) {
              setState(() {
                _stage = MessageStage.ready;
              });
            } else if (_lastMessage!.messageType.isQuestion) {
              final answer = _lastMessage!.answer;
              if (answer == null) {
                _tempSelectedAnswerIndex = null;
                _tempConfidenceLevel = null;
                setState(() {
                  _stage = MessageStage.selectOption;
                });
              } else {
                setState(() {
                  _stage = MessageStage.explainAndFollowup;
                });
              }
            } else if (_lastMessage!.messageType.isEnd) {
              setState(() {
                _stage = MessageStage.finished;
              });
              _isFinished = true;
            } else {
              setState(() {
                _stage = MessageStage.explainAndFollowup;
              });
            }
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _loadTutorialSession failed',
        customKeys: {'tutorialId': widget.tutorial.id},
      );
      if (mounted) {
        AppErrorHandler.showUserError(context, 'Failed to load tutorial session');
      }
      setState(() {
        _isLoading = false;
        _stage = MessageStage.error;
      });
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _scrollController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Color _getConfidenceColor(Confidence? confidence) {
    switch (confidence) {
      case Confidence.noidea:
        return const Color(0xFFF50057); // Soft red
      case Confidence.notsure:
        return const Color(0xFFFF9F43); // Orange
      case Confidence.mostlysure:
        return const Color(0xFF38B6FF); // Light blue
      case Confidence.confident:
        return const Color(0xFF38EF7D); // Vibrant green
      default:
        return Colors.white54;
    }
  }

  void _selectOption(OptionsKey opt) {
    setState(() {
      _tempSelectedAnswerIndex = opt;
    });
  }

  void _selectConfidence(Confidence confidence) {
    setState(() {
      _tempConfidenceLevel = confidence;
    });
  }

  void _submitAnswer() {
    setState(() {
      _stage = MessageStage.loading;
    });
    if (_tutorChannel == null ||
        _tempSelectedAnswerIndex == null ||
        _tempConfidenceLevel == null) {
      setState(() {
        _stage = MessageStage.error;
      });
      return;
    }

    setState(() {
      _stage = MessageStage.explainAndFollowup;
      final question = _lastMessage!.question;
      if (question != null) {
        if (question.answer != null) {
          question.answer!.setSelectedOption(_tempSelectedAnswerIndex!);
          question.answer!.setConfidence(_tempConfidenceLevel!);
        } else {
          question.answer = Answer(
            selectedOption: _tempSelectedAnswerIndex,
            confidence: _tempConfidenceLevel,
          );
        }
        _lastMessage!.interactive = false;
      }
    });

    try {
      TopicService().submitAnswer(
        questionId: _lastMessage!.question!.id,
        selectedOption: _tempSelectedAnswerIndex!.toStr(),
        confidence: _tempConfidenceLevel!.name,
        channel: _messages.last.channel,
        sectionId: _messages.last.sectionId!,
        componentId: _messages.last.componentId!,
      );
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _submitAnswer failed',
      );
      if (mounted) {
        AppErrorHandler.showUserError(context, 'Failed to submit answer');
      }
    }
  }

  void _sendFollowUp() {
    final text = _followUpController.text.trim();
    if (text.isEmpty) return;
    _followUpController.clear();

    final userMsgId = 'user_comment_${DateTime.now().millisecondsSinceEpoch}';

    ChatSocketService().sendMessage(
      message: text,
      messageType: MessageType.usercomment,
      extraData: {
        'context_sectionid': _messages.last.sectionId,
        'context_componentid': _messages.last.componentId,
      },
    );

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: userMsgId,
          userId: AuthService.userId ?? 'user',
          message: text,
          channel: _messages.last.channel,
          createdAt: DateTime.now().toLocal(),
        ),
      );
      _lastMessage = _messages.last;
    });
    _scrollToBottom();
  }

  Future<void> _tutorialContinue() async {
    setState(() {
      _stage = MessageStage.loading;
    });
    logPrint(
      "continue From SECTION: ${_lastMessage!.sectionId} and COMPONENT: ${_lastMessage!.componentId}",
    );
    try {
      await TopicService().continueTutorial(
        tutorialId: widget.tutorial.id,
        channel: _lastMessage!.channel,
        sectionId: _lastMessage!.sectionId,
        componentId: _lastMessage!.componentId,
      );
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _tutorialContinue failed',
      );
      if (mounted) {
        AppErrorHandler.showUserError(context, 'Failed to continue tutorial');
      }
    }
    _scrollToBottom();
  }

  Widget _buildRichText(String text, TextStyle baseStyle) {
    String processed = text;

    // Convert common HTML block/line tags
    processed = processed
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li\s*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<h1\s*>', caseSensitive: false), '[h1]')
        .replaceAll(RegExp(r'</h1\s*>', caseSensitive: false), '[/h1]')
        .replaceAll(RegExp(r'</?h[2-6]\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(div|ul|ol|p)\s*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?(strong|b)\s*>', caseSensitive: false), '**')
        .replaceAll(RegExp(r'<thumb\s*>', caseSensitive: false), '[thumb]')
        .replaceAll(RegExp(r'</thumb\s*>', caseSensitive: false), '[/thumb]')
        .replaceAll(RegExp(r'<asset\s*>', caseSensitive: false), '[asset]')
        .replaceAll(RegExp(r'</asset\s*>', caseSensitive: false), '[/asset]')
        .replaceAll(RegExp(r'<caption\s*>', caseSensitive: false), '[caption]')
        .replaceAll(
          RegExp(r'</caption\s*>', caseSensitive: false),
          '[/caption]',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\n\n+'), '\n\n');

    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(
      r'\[asset\](.*?)\[/asset\]\s*\[thumb\](.*?)\[/thumb\]\s*(?:\[caption\](.*?)\[/caption\]\s*)?|\[h1\](.*?)\[/h1\]|\*\*(.*?)\*\*',
      dotAll: true,
    );
    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(processed)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(text: processed.substring(lastMatchEnd, match.start)),
        );
      }

      final String? assetUrl = match.group(1);
      final String? assetThumb = match.group(2);
      final String? captionText = match.group(3);
      final String? h1Content = match.group(4);
      final String? boldContent = match.group(5);

      if (assetThumb != null && assetUrl != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        FullScreenMediaViewer.open(
                          context,
                          url: assetUrl,
                          caption: captionText,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: assetThumb,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    if (captionText != null &&
                        captionText.trim().isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        captionText.trim(),
                        style: baseStyle.copyWith(
                          fontSize: (baseStyle.fontSize ?? 14.0) - 2.0,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (h1Content != null) {
        spans.add(
          TextSpan(
            text: h1Content.replaceAll('**', ''),
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14.0) + 4.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
      } else if (boldContent != null) {
        spans.add(
          TextSpan(
            text: boldContent,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < processed.length) {
      spans.add(TextSpan(text: processed.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(children: spans, style: baseStyle),
    );
  }

  void _showReportAiDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String selectedReason = 'reason_hallucination';
    final TextEditingController commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141923),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Row(
              children: [
                const Icon(Icons.outlined_flag, color: Color(0xFFF50057)),
                const SizedBox(width: 10),
                Text(
                  l10n.reportAi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report hallucination, inaccurate information, or inappropriate AI response:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    l10n.reasonHallucination,
                    l10n.reasonInappropriate,
                    l10n.reasonOffensive,
                    l10n.reasonOther,
                  ].map((reasonKey) {
                    final isSelected = selectedReason == reasonKey;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => selectedReason = reasonKey),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF38B6FF,
                                    ).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF38B6FF)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF38B6FF)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reasonKey,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),

                  TextField(
                    controller: commentsController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Additional details (optional)...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B6FF),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  AppErrorHandler.showUserSuccess(
                    context,
                    l10n.reportAiSuccess,
                  );
                },
                child: Text(
                  'Report',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageContainer({
    required bool isAgent,
    required bool isAiGenerated,
    required Widget child,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isAgent
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        if (isAgent) ...[
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image:
                  "https://minsur.genailabs.tech/site/mediadb/services/module/asset/generated/Sources/Iris_Avatar_Minsur/Iris_Avatar_Minsur.png/image200x200.webp",
              imageErrorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.smart_toy, color: Colors.white);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: isAgent
                  ? const Color(0xFF161C24).withValues(alpha: 0.8)
                  : const Color(0xFFF27121).withValues(alpha: 0.15),
              borderRadius: isAgent
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
              border: Border.all(
                color: isAgent
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF27121).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: isAgent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      child,
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: isAiGenerated
                                ? [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: Color(0xFF38B6FF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.aiGenerated,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF38B6FF),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                          InkWell(
                            onTap: () => _showReportAiDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.outlined_flag,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Report',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : child,
          ),
        ),
        if (!isAgent) ...[
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image:
                  "https://eme.world/mediadb/services/module/asset/generated/Entity%20Assets/profile/placeholder.jpg/image200x200.webp",
              imageErrorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, color: Colors.white);
              },
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildChatMessageItem(ChatMessage message, bool isLast) {
    switch (message.messageType) {
      case MessageType.usercomment:
        return [_buildUserCommentMessage(message)];
      case MessageType.agentcomment:
        return [_buildAgentCommentMessage(message)];
      case MessageType.end:
        return [_buildEndMessage(message)];
      case MessageType.question:
        return [_buildQuestionMessage(message, isLast)];
      case MessageType.asset:
        return [_buildAssetMessage(message)];
      case MessageType.welcome:
      case MessageType.text:
      default:
        return [_buildTextMessage(message)];
    }
  }

  Widget _buildAssetMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAgent: message.isAI,
      isAiGenerated: false,
      child: AssetMessageWidget(message: message),
    );
  }

  Widget _buildUserCommentMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAgent: false,
      isAiGenerated: false,
      child: _buildRichText(
        message.text,
        const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
      ),
    );
  }

  Widget _buildAgentCommentMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAgent: true,
      isAiGenerated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            message.text,
            TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAgent: true,
      isAiGenerated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF38EF7D),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38EF7D),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRichText(
            message.text,
            const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message) {
    return _buildMessageContainer(
      isAgent: message.isAI,
      isAiGenerated: false,
      child: _buildRichText(
        message.text,
        TextStyle(
          fontSize: 14,
          color: message.isAI
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildQuestionMessage(ChatMessage message, bool isLast) {
    final l10n = AppLocalizations.of(context)!;
    final bool isInteractive = message.interactive;

    OptionsKey? selectedOpt;
    if (message.answer?.selectedOption != null) {
      selectedOpt = message.answer!.selectedOption;
    } else if (isLast && _tempSelectedAnswerIndex != null) {
      selectedOpt = _tempSelectedAnswerIndex;
    }

    final question = message.question!;

    return _buildMessageContainer(
      isAgent: true,
      isAiGenerated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text (RichText)
          _buildRichText(
            question.question,
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: question.options.keys.map((optionKey) {
                final optionText = question.options[optionKey]!;
                final isSelected = selectedOpt == optionKey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: isInteractive
                        ? () {
                            _selectOption(optionKey);
                            if (!_stage.isSelectOption) {
                              setState(() {
                                _stage = MessageStage.selectOption;
                              });
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF27121).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF27121)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFF27121)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              optionKey.letter,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (message.answer?.confidence != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${l10n.confidence}:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.answer!.confidence!.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(message.answer?.confidence),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ChatMessage? message) {
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF11161D),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_stage.isLoading) ...[
              const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF27121)),
                ),
              ),
            ] else if (_stage.isError) ...[
              Center(
                child: Text(
                  'An error occured while loading the chat.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _loadTutorialDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Try Again',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.refresh, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ] else if (_stage.isReady) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF27121),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF27121).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _tutorialContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.play_circle, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ] else if (_stage.isExplainAndFollowup) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _followUpController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _sendFollowUp(),
                      decoration: InputDecoration(
                        hintText: 'Ask a follow-up question...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: const Color(0xFFF27121),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendFollowUp,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFFF27121),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFF27121),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF27121).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _tutorialContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Contnue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_stage.isSelectOption) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'HOW CONFIDENT ARE YOU IN THIS ANSWER?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                children: Confidence.values.map((confidence) {
                  final color = _getConfidenceColor(confidence);
                  final isSelected = _tempConfidenceLevel == confidence;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => _selectConfidence(confidence),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.25)
                                : const Color(
                                    0xFF161C24,
                                  ).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            confidence.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? const Color(0xFFF27121)
                      : const Color(0xFF161C24).withValues(alpha: 0.4),
                  boxShadow:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFF27121,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  border:
                      (_tempSelectedAnswerIndex != null &&
                          _tempConfidenceLevel != null)
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                ),
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Submit Answer',
                        style: TextStyle(
                          color:
                              (_tempSelectedAnswerIndex != null &&
                                  _tempConfidenceLevel != null)
                              ? Colors.white
                              : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.send_rounded,
                        size: 16,
                        color:
                            (_tempSelectedAnswerIndex != null &&
                                _tempConfidenceLevel != null)
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFF27121)),
            SizedBox(height: 16),
            Text(
              'Connecting to tutor session...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Premium custom AppBar header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tutorial.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.beginner,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.competent,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.expert,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Conversation Log Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(24.0),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final messageIndex = _messages.length - 1 - index;
              final message = _messages[messageIndex];
              final isLast = messageIndex == _messages.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [..._buildChatMessageItem(message, isLast)],
                ),
              );
            },
          ),
        ),

        // Bottom input/selection panel
        _buildBottomPanel(_messages.isEmpty ? null : _messages.last),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: min(680, size.width),
              color: Colors.white.withValues(alpha: 0.02),
              child: Stack(
                children: [
                  // Main content layout
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 680 : double.infinity,
                      ),
                      child: _isFinished
                          ? _buildResultsView()
                          : _buildQuizView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        Text("Quiz Completed! 🎉"),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Go Back"),
        ),
      ],
    );
  }
}
