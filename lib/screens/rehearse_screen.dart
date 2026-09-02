import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:eme_app_package/models/chat_message.dart' as socket_msg;
import 'package:eme_app_package/models/chat_message.dart';
import 'package:eme_app_package/models/topic.dart';
// import 'package:eme_app_package/services/auth_service.dart';
import 'package:eme_app_package/services/chat_socket_service.dart';
import 'package:eme_app_package/services/topic_service.dart';
import 'package:eme_app_package/utils/log.dart';
import 'package:eme_app_package/widgets/common_widgets.dart';
import 'package:eme_app_package/widgets/fullscreen_mediaviewer.dart';
import 'package:eme_app_package/widgets/asset_message_widget.dart';
import 'package:intl/intl.dart';
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
  TutorChannel? _activeTutorChannel;
  TutorChannel? _currentViewingChannel;
  List<TutorChannel> _historyChannels = [];
  bool _isReadOnly = false;
  StreamSubscription<socket_msg.ChatMessage>? _socketSubscription;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _followUpController = TextEditingController();

  bool _isFinished = false;
  Timer? _responseTimer;

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

  void _startResponseTimeoutTimer() {
    _responseTimer?.cancel();
    _responseTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (_stage.isLoading) {
        setState(() {
          _updateStageFromLastMessage();
        });
      }
    });
  }

  Future<void> _connectSocket(String channelId) async {
    await ChatSocketService().connect(channel: channelId);
    _socketSubscription?.cancel();
    _socketSubscription = ChatSocketService().messageStream.listen((
      incomingMsg,
    ) {
      logPrint("ChatSocketService incomingMsg: ${incomingMsg.toJson()}");
      if (incomingMsg.isKeepAlive || incomingMsg.isMessageRemoved) return;
      if (!mounted || _isReadOnly) return;

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
      } else if (incomingMsg.messageType.isEnd) {
        _responseTimer?.cancel();
        setState(() {
          _stage = MessageStage.finished;
          _isFinished = true;
        });
        return;
      }

      _responseTimer?.cancel();
      setState(() {
        final existingMessage = _messages.firstWhere(
          (m) => m.messageId == incomingMsg.messageId,
          orElse: () => incomingMsg,
        );
        if (existingMessage != incomingMsg) {
          final index = _messages.indexWhere(
            (m) => m.messageId == incomingMsg.messageId,
          );
          if (index != -1) {
            _messages[index] = incomingMsg;
          }
        } else {
          _messages.add(incomingMsg);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        _lastMessage = _messages.last;

        if (_lastMessage!.messageType.isWelcome) {
          _stage = MessageStage.ready;
        } else if (_lastMessage!.messageType.isQuestion) {
          _tempSelectedAnswerIndex = null;
          _tempConfidenceLevel = null;
          _stage = MessageStage.selectOption;
        } else if (_lastMessage!.messageType.isEnd) {
          _stage = MessageStage.finished;
          _isFinished = true;
        } else {
          _stage = MessageStage.explainAndFollowup;
        }
      });
      _scrollToBottom();
    });
  }

  void _updateStageFromLastMessage() {
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
          _isFinished = true;
        });
      } else {
        setState(() {
          _stage = MessageStage.explainAndFollowup;
        });
      }
    }
  }

  Future<void> _loadTutorialDetail() async {
    _responseTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isReadOnly = false;
    });

    try {
      _messages.clear();
      _lastMessage = null;

      final result = await TopicService().fetchTutorHistory(
        tutorialId: widget.tutorial.id,
      );

      _historyChannels = result.history;
      _activeTutorChannel = result.activeChannel;
      _currentViewingChannel = result.currentChannel ?? result.activeChannel;
      _tutorChannel = _currentViewingChannel;

      if (_currentViewingChannel == null) {
        setState(() {
          _stage = MessageStage.error;
          _isLoading = false;
        });
        return;
      }

      final isViewingActive =
          _activeTutorChannel != null &&
          _currentViewingChannel?.id == _activeTutorChannel!.id;
      _isReadOnly = !isViewingActive;

      if (result.messages.isNotEmpty) {
        setState(() {
          _messages.addAll(result.messages);
          _lastMessage = _messages.last;
        });
      }

      if (isViewingActive) {
        await _connectSocket(_activeTutorChannel!.id);

        if (_messages.isEmpty) {
          await TopicService().startTutorial(
            tutorialId: widget.tutorial.id,
            channel: _activeTutorChannel!.id,
          );
        } else {
          _updateStageFromLastMessage();
        }
      } else {
        if (_messages.isNotEmpty) {
          _updateStageFromLastMessage();
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
        reason: 'RehearseScreen _loadTutorialDetail failed',
        customKeys: {'tutorialId': widget.tutorial.id},
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(
          context,
          l10n.failedToLoadTutorialSession,
        );
      }
      setState(() {
        _isLoading = false;
        _stage = MessageStage.error;
      });
    }
  }

  Future<void> _loadHistoryChannel(TutorChannel historyChannel) async {
    if (_activeTutorChannel != null &&
        historyChannel.id == _activeTutorChannel!.id) {
      await _switchToActiveSession();
      return;
    }

    _responseTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isReadOnly = true;
      _currentViewingChannel = historyChannel;
      _tutorChannel = historyChannel;
      _messages.clear();
      _lastMessage = null;
    });

    _socketSubscription?.cancel();
    _socketSubscription = null;

    try {
      final result = await TopicService().fetchTutorHistory(
        tutorialId: widget.tutorial.id,
        channelId: historyChannel.id,
      );

      logPrint('Tutor Result: $result');

      _historyChannels = result.history;
      if (result.activeChannel != null) {
        _activeTutorChannel = result.activeChannel;
      }
      if (result.currentChannel != null) {
        _currentViewingChannel = result.currentChannel;
        _tutorChannel = result.currentChannel;
      }

      setState(() {
        _messages.addAll(result.messages);
        _lastMessage = _messages.isNotEmpty ? _messages.last : null;
        _isLoading = false;
      });
      _updateStageFromLastMessage();
      _scrollToBottom();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _loadHistoryChannel failed',
        customKeys: {
          'tutorialId': widget.tutorial.id,
          'channelId': historyChannel.id,
        },
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(
          context,
          l10n.failedToLoadTutorialSession,
        );
      }
      setState(() {
        _isLoading = false;
        _stage = MessageStage.error;
      });
    }
  }

  Future<void> _switchToActiveSession() async {
    if (_activeTutorChannel == null) {
      await _loadTutorialDetail();
      return;
    }

    _responseTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isReadOnly = false;
      _currentViewingChannel = _activeTutorChannel;
      _tutorChannel = _activeTutorChannel;
      _messages.clear();
      _lastMessage = null;
    });

    try {
      final result = await TopicService().fetchTutorHistory(
        tutorialId: widget.tutorial.id,
        channelId: _activeTutorChannel!.id,
      );

      _historyChannels = result.history;
      if (result.activeChannel != null) {
        _activeTutorChannel = result.activeChannel;
      }
      _currentViewingChannel = result.currentChannel ?? _activeTutorChannel;
      _tutorChannel = _currentViewingChannel;

      if (result.messages.isNotEmpty) {
        setState(() {
          _messages.addAll(result.messages);
          _lastMessage = _messages.last;
        });
      }

      await _connectSocket(_activeTutorChannel!.id);

      if (_messages.isEmpty) {
        await TopicService().startTutorial(
          tutorialId: widget.tutorial.id,
          channel: _activeTutorChannel!.id,
        );
      } else {
        _updateStageFromLastMessage();
      }

      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _switchToActiveSession failed',
        customKeys: {
          'tutorialId': widget.tutorial.id,
          'channelId': _activeTutorChannel?.id ?? '',
        },
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(
          context,
          l10n.failedToLoadTutorialSession,
        );
      }
      setState(() {
        _isLoading = false;
        _stage = MessageStage.error;
      });
    }
  }

  void _showHistorySheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final hasActive = _activeTutorChannel != null;
        final isViewingActive = !_isReadOnly;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161C24),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Colors.white12, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF38B6FF,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF38B6FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.sessionHistory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Session option
                if (hasActive) ...[
                  Material(
                    color: isViewingActive
                        ? const Color(0xFF1E2638)
                        : const Color(0xFF0F1319),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isViewingActive
                              ? const Color(0xFF38EF7D).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                          width: isViewingActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF38EF7D,
                            ).withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF38EF7D),
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _activeTutorChannel!.name.isNotEmpty
                                    ? _activeTutorChannel!.name
                                    : l10n.activeSession,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF38EF7D,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.activeSession,
                                style: const TextStyle(
                                  color: Color(0xFF38EF7D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isViewingActive
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF38EF7D),
                                size: 20,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white38,
                                size: 14,
                              ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (!isViewingActive) {
                            _switchToActiveSession();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Past Sessions header
                Text(
                  l10n.pastSessions,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Past Sessions List
                if (_historyChannels.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1319),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 32,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noPreviousSessions,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _historyChannels.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final channel = _historyChannels[index];
                        final isCurrentChannel =
                            _isReadOnly &&
                            _currentViewingChannel?.id == channel.id;

                        final displayName = channel.name.isNotEmpty
                            ? channel.name
                            : "${l10n.pastSession} #${index + 1}";

                        final displayDate = channel.date.isNotEmpty
                            ? DateFormat(
                                'MMM dd, y, h:mm a',
                              ).format(DateTime.parse(channel.date))
                            : (channel.refreshDate.isNotEmpty
                                  ? DateFormat('MMM dd, y, h:mm a').format(
                                      DateTime.parse(channel.refreshDate),
                                    )
                                  : channel.id);

                        return Material(
                          color: isCurrentChannel
                              ? const Color(0xFF1E2638)
                              : const Color(0xFF0F1319),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrentChannel
                                    ? const Color(
                                        0xFF38B6FF,
                                      ).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.05),
                                width: isCurrentChannel ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.history_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                displayDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                displayName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isCurrentChannel
                                  ? const Icon(
                                      Icons.visibility_rounded,
                                      color: Color(0xFF38B6FF),
                                      size: 18,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white24,
                                      size: 12,
                                    ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _loadHistoryChannel(channel);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
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

  void _submitAnswer() async {
    if (_tutorChannel == null ||
        _tempSelectedAnswerIndex == null ||
        _tempConfidenceLevel == null ||
        _lastMessage?.question == null) {
      setState(() {
        _stage = MessageStage.error;
      });
      return;
    }

    // setState(() {
    //   _stage = MessageStage.loading;
    //   final question = _lastMessage!.question;
    //   if (question != null) {
    //     if (question.answer != null) {
    //       question.answer!.setSelectedOption(_tempSelectedAnswerIndex!);
    //       question.answer!.setConfidence(_tempConfidenceLevel!);
    //     } else {
    //       question.answer = Answer(
    //         selectedOption: _tempSelectedAnswerIndex,
    //         confidence: _tempConfidenceLevel,
    //       );
    //     }
    //     _lastMessage!.interactive = false;
    //   }
    // });
    _startResponseTimeoutTimer();

    try {
      if (ChatSocketService().isConnected) {
        ChatSocketService().sendMessage(
          message:
              "Answer: ${_tempSelectedAnswerIndex!.toStr()}, Confidence: ${_tempConfidenceLevel!.name}",
          channel: _activeTutorChannel!.id,
          functionName: 'chat_tutor_answer',
          nextFunctionName: 'chat_tutor_progress',
          command: "messagereceived",
          extraData: {
            'agentcontext': jsonEncode({
              'questionid': _lastMessage!.question!.id,
              'selectedoption': _tempSelectedAnswerIndex!.toStr(),
              'confidence': _tempConfidenceLevel!.name,
              'tutorialid': widget.tutorial.id,
              'sectionid': _messages.last.sectionId,
              'componentid': _messages.last.componentId,
            }),
          },
        );
      }
    } catch (e, stack) {
      _responseTimer?.cancel();
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _submitAnswer failed',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(context, l10n.failedToSubmitAnswer);
        setState(() {
          _updateStageFromLastMessage();
        });
      }
    }
  }

  void _sendFollowUp() async {
    if (_lastMessage == null) return;
    final text = _followUpController.text.trim();
    if (text.isEmpty) return;
    if (text.length < 5) {
      if (mounted) {
        AppErrorHandler.showUserError(
          context,
          'Message must be at least 5 characters long',
        );
      }
      return;
    }
    _followUpController.clear();

    // final userMsgId = 'user_comment_${DateTime.now().millisecondsSinceEpoch}';

    try {
      setState(() {
        _stage = MessageStage.loading;
      });
      _scrollToBottom();
      _startResponseTimeoutTimer();
      if (ChatSocketService().isConnected) {
        ChatSocketService().sendMessage(
          message: text,
          channel: _activeTutorChannel!.id,
          functionName: 'chat_tutor_usercomment',
          command: "messagereceived",
          extraData: {
            'agentcontext': jsonEncode({
              'tutorialId': widget.tutorial.id,
              'sectionId': _messages.last.sectionId,
              'componentId': _messages.last.componentId,
            }),
          },
        );
      }
    } catch (e, stack) {
      _responseTimer?.cancel();
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _sendFollowUp failed',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(context, l10n.failedToSendFollowUp);
        setState(() {
          _updateStageFromLastMessage();
        });
      }
    }
  }

  Future<void> _tutorialContinue([bool? restart]) async {
    restart = restart ?? false;
    setState(() {
      _stage = MessageStage.loading;
    });
    _startResponseTimeoutTimer();
    logPrint(
      "continue From SECTION: ${_lastMessage!.sectionId} and COMPONENT: ${_lastMessage!.componentId}",
    );
    try {
      await TopicService().continueTutorial(
        tutorialId: widget.tutorial.id,
        channel: _lastMessage!.channel,
        sectionId: restart ? null : _lastMessage!.sectionId,
        componentId: restart ? null : _lastMessage!.componentId,
      );
    } catch (e, stack) {
      _responseTimer?.cancel();
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'RehearseScreen _tutorialContinue failed',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(context, l10n.failedToContinueTutorial);
        setState(() {
          _updateStageFromLastMessage();
        });
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
                    l10n.reportDetailsPrompt,
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
                      hintText: l10n.additionalDetailsOptional,
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
                  l10n.report,
                  style: const TextStyle(
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
    bool showAvatar = true,
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
          if (showAvatar)
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
            )
          else
            const SizedBox(width: 32),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: isAgent
                  ? const Color(0xFF161C24).withValues(alpha: 0.8)
                  : const Color(0xFFF27121).withValues(alpha: 0.15),
              borderRadius: isAgent
                  ? BorderRadius.only(
                      topLeft: Radius.circular(showAvatar ? 4 : 16),
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    )
                  : BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: Radius.circular(showAvatar ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
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
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 140),
                            position: PopupMenuPosition.under,
                            color: const Color(0xFF161C24),
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            tooltip: '',
                            onSelected: (value) {
                              if (value == 'report') {
                                _showReportAiDialog(context);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'report',
                                height: 36,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.outlined_flag_rounded,
                                      size: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.reportAi,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.4),
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
          if (showAvatar)
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
            )
          else
            const SizedBox(width: 32),
        ],
      ],
    );
  }

  List<Widget> _buildChatMessageItem(
    ChatMessage message,
    bool isLast, {
    bool showAvatar = true,
  }) {
    switch (message.messageType) {
      case MessageType.usercomment:
        return [_buildUserCommentMessage(message, showAvatar: showAvatar)];
      case MessageType.agentcomment:
        return [_buildAgentCommentMessage(message, showAvatar: showAvatar)];
      case MessageType.end:
        return [_buildEndMessage(message, showAvatar: showAvatar)];
      case MessageType.question:
        return [_buildQuestionMessage(message, isLast, showAvatar: showAvatar)];
      case MessageType.asset:
        return [_buildAssetMessage(message, showAvatar: showAvatar)];
      case MessageType.answereval:
        return [_buildAnswerEvalMessage(message, showAvatar: showAvatar)];
      case MessageType.welcome:
      case MessageType.text:
      default:
        return [_buildTextMessage(message, showAvatar: showAvatar)];
    }
  }

  Widget _buildAssetMessage(ChatMessage message, {bool showAvatar = true}) {
    return _buildMessageContainer(
      isAgent: message.isAI,
      isAiGenerated: false,
      showAvatar: showAvatar,
      child: AssetMessageWidget(message: message),
    );
  }

  Widget _buildUserCommentMessage(
    ChatMessage message, {
    bool showAvatar = true,
  }) {
    return _buildMessageContainer(
      isAgent: false,
      isAiGenerated: false,
      showAvatar: showAvatar,
      child: _buildRichText(
        message.text,
        const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
      ),
    );
  }

  Widget _buildAgentCommentMessage(
    ChatMessage message, {
    bool showAvatar = true,
  }) {
    return _buildMessageContainer(
      isAgent: true,
      isAiGenerated: true,
      showAvatar: showAvatar,
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

  Widget _buildEndMessage(ChatMessage message, {bool showAvatar = true}) {
    return _buildMessageContainer(
      isAgent: true,
      isAiGenerated: true,
      showAvatar: showAvatar,
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

  Widget _buildHeadingMessage(ChatMessage message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32.0, bottom: 16.0, left: 44.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: Alignment.center,
      child: _buildRichText(
        message.text,
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.35,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildAnswerEvalMessage(
    ChatMessage message, {
    bool showAvatar = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (message.componentType == 'heading') {
      return _buildHeadingMessage(message);
    }
    return _buildMessageContainer(
      isAgent: message.isAI,
      isAiGenerated: false,
      showAvatar: showAvatar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isCorrect != null) ...[
            if (message.isCorrect!) ...[
              Text(
                l10n.correct,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38EF7D),
                ),
              ),
            ] else ...[
              Text(
                l10n.incorrect,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF50057),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          _buildRichText(
            message.text,
            TextStyle(
              fontSize: 14,
              color: message.isAI
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, {bool showAvatar = true}) {
    if (message.componentType == 'heading') {
      return _buildHeadingMessage(message);
    }
    return _buildMessageContainer(
      isAgent: message.isAI,
      isAiGenerated: false,
      showAvatar: showAvatar,
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

  Widget _buildQuestionMessage(
    ChatMessage message,
    bool isLast, {
    bool showAvatar = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final bool isInteractive = !_isReadOnly && message.interactive;

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
      showAvatar: showAvatar,
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
                    message.answer!.confidence!.getLabel(l10n),
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
    if (_isReadOnly || message == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.errorLoadingChat,
                  style: const TextStyle(color: Colors.white),
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
                      l10n.tryAgain,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.refresh, size: 16, color: Colors.white),
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
                        l10n.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.play_circle,
                        size: 16,
                        color: Colors.white,
                      ),
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
                        hintText: l10n.askFollowUpHint,
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
                            color: const Color(
                              0xFFFFFFFF,
                            ).withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _followUpController,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  final buttonFill = hasText
                      ? const Color(0xFF357A38)
                      : const Color(0xFFF27121);
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: buttonFill,
                      boxShadow: [
                        BoxShadow(
                          color: buttonFill.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: hasText ? _sendFollowUp : _tutorialContinue,
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
                            hasText ? l10n.send : l10n.continueButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasText
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else if (_stage.isSelectOption) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  l10n.howConfidentQuestion,
                  style: const TextStyle(
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
                            confidence.getLabel(l10n),
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
                        l10n.submitAnswer,
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFF27121)),
            const SizedBox(height: 16),
            Text(
              l10n.connectingToTutorSession,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                          l10n,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.competent,
                          l10n,
                        ),
                        const SizedBox(width: 24),
                        CommonWidgets.buildProgressColumn(
                          widget.tutorial.progress,
                          Efficiency.expert,
                          l10n,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showHistorySheet,
                icon: Icon(
                  Icons.history_rounded,
                  color: _isReadOnly ? const Color(0xFF38B6FF) : Colors.white,
                  size: 22,
                ),
                tooltip: l10n.sessionHistory,
                style: IconButton.styleFrom(
                  backgroundColor: _isReadOnly
                      ? const Color(0xFF38B6FF).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isReadOnly
                          ? const Color(0xFF38B6FF).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isReadOnly)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF38B6FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF38B6FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Color(0xFF38B6FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${l10n.viewingPastSession}: ${_currentViewingChannel?.name.isNotEmpty == true ? _currentViewingChannel!.name : l10n.pastSession}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_activeTutorChannel != null)
                  TextButton(
                    onPressed: _switchToActiveSession,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.resumeActive,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF38B6FF),
                        fontWeight: FontWeight.bold,
                      ),
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

              bool showAvatar = true;
              if (messageIndex > 0) {
                final prevMessage = _messages[messageIndex - 1];
                final isPrevHeading = prevMessage.componentType == 'heading';
                if (!isPrevHeading && prevMessage.isUser == message.isUser) {
                  showAvatar = false;
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: showAvatar ? 8.0 : 24.0),
                child: Column(
                  children: [
                    ..._buildChatMessageItem(
                      message,
                      isLast,
                      showAvatar: showAvatar,
                    ),
                  ],
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.quizCompleted,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.orange),
              foregroundColor: const WidgetStatePropertyAll(Colors.black),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(l10n.goBack),
          ),
        ],
      ),
    );
  }
}
