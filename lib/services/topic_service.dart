import 'package:eme_app_package/eme_http.dart';
import 'package:eme_app_package/models/chat_message.dart';
import 'package:eme_app_package/utils/log.dart';
import 'package:intl/intl.dart';
import '../models/topic.dart';
import '../models/tutor_channel.dart';
import '../models/tutorial.dart';
import '../utils/error_handler.dart';

/// Parsing and flow only — transport, auth headers, encoding, decoding,
/// logging and HTTP-error recording live behind [EmeHttp]. Catch blocks here
/// record parse errors only; EmeHttpException is already recorded inside the
/// module.

/// One tutorhistory.json (or dailychallenge.json) response: the channel being
/// viewed, the channel the tutor is live on (they differ when browsing a
/// finished session read-only), the finished-channel history, and the viewed
/// channel's messages.
class TutorHistoryResult {
  final TutorChannel? currentChannel;
  final TutorChannel? activeChannel;
  final List<TutorChannel> history;
  final List<ChatMessage> messages;

  /// Daily challenge only: set by [TopicService.fetchDailyChallenge], with
  /// the section the challenge draws its questions from.
  final bool isDailyChallenge;
  final String? sectionId;

  /// The learner's recorded answers on the current channel, oldest first,
  /// as the server sends them: questionid, section, tutorial, iscorrect
  /// ("true"/"false"), selectedoption, confidence, date.
  final List<Map<String, dynamic>> answers;

  TutorHistoryResult({
    this.currentChannel,
    this.activeChannel,
    this.history = const [],
    this.messages = const [],
    this.answers = const [],
    this.isDailyChallenge = false,
    this.sectionId,
  });
}

class TopicService {
  final EmeHttp _http;

  TopicService({EmeHttp? http}) : _http = http ?? DioEmeHttp();

  static const _continuePath = 'services/module/entitytutorial/continue.json';
  static const _startPath = 'services/module/entitytutorial/start.json';

  Future<List<Topic>> fetchTopics() async {
    const path = 'services/module/entitytopic/topics.json';
    try {
      final data = await _http.getJson(path);
      final jsonList = data['topics'] as List<dynamic>? ?? [];
      return jsonList
          .map((item) => Topic.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTopics failed',
          customKeys: {'url': path},
        );
      }
      return [];
    }
  }

  Future<List<Tutorial>> fetchTutorialsForTopic(String topicId) async {
    const path = 'services/module/entitytutorial/tutorials.json';
    try {
      final data = await _http.getJson(path, query: {'entitytopic': topicId});
      // Bare-array responses arrive as {'data': [...]} per the EmeHttp contract.
      final jsonList =
          data['tutorials'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          [];
      return jsonList
          .map((item) => Tutorial.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTutorialsForTopic failed',
          customKeys: {'url': path, 'topicId': topicId},
        );
      }
      rethrow;
    }
  }

  /// The whole tutorial in one batch: sections with their content, including
  /// MCQs that carry their own [McqQuestion.correctOption]. Unlike the live
  /// tutor flow — where questions arrive over the socket without an answer
  /// key — this lets a caller judge answers locally.
  ///
  /// Note the query parameter is `entitytutorial`; `dataid` returns HTTP 500
  /// here, unlike the other entitytutorial endpoints. `sections` sits beside
  /// `tutorial` in the response, which is what [TutorialDetail.fromJson]
  /// already expects. Questions ride along on related paragraph and asset
  /// rows too, so read them from `contenttype: mcq` rows only — and note a
  /// question's id is unique within its section, not across the tutorial.
  Future<TutorialDetail?> fetchTutorialDetail(String tutorialId) async {
    const path = 'services/module/entitytutorial/tutorial.json';
    try {
      final data = await _http.getJson(
        path,
        query: {'entitytutorial': tutorialId},
      );
      if (data['sections'] is! List) return null;
      return TutorialDetail.fromJson(data);
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTutorialDetail failed',
          customKeys: {'url': path, 'tutorialId': tutorialId},
        );
      }
      rethrow;
    }
  }

  /// The endpoint is a POST with its parameters in the query string; no
  /// channelId means "the tutorial's active session".
  Future<TutorHistoryResult> fetchTutorHistory({
    required String tutorialId,
    String? channelId,
  }) async {
    const path = 'services/module/entitytutorial/tutorhistory.json';
    try {
      final data = await _http.post(
        path,
        query: [
          MapEntry('dataid', tutorialId),
          if (channelId != null && channelId.isNotEmpty)
            MapEntry('channel', channelId),
        ],
      );
      return _toHistory(
        data,
        path: path,
        keys: {'channelId': channelId ?? '', 'tutorialId': tutorialId},
      );
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTutorHistory failed',
          customKeys: {
            'url': path,
            'channelId': channelId ?? '',
            'tutorialId': tutorialId,
          },
        );
      }
      rethrow;
    }
  }

  /// The day's challenge — same channel/message shape as
  /// [fetchTutorHistory], plus the section its questions come from.
  Future<TutorHistoryResult> fetchDailyChallenge({
    required DateTime challengeDate,
  }) async {
    const path = 'services/module/entitytutorial/dailychallenge.json';
    final date = DateFormat('yyyy-MM-dd').format(challengeDate);
    try {
      final data = await _http.post(path, query: [MapEntry('date', date)]);
      final challenge = data['dailychallenge'];
      return _toHistory(
        data,
        path: path,
        keys: {'challengeDate': date},
        isDailyChallenge: true,
        sectionId: challenge is Map<String, dynamic>
            ? challenge['sectionid']?.toString() ?? ''
            : '',
      );
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchDailyChallenge failed',
          customKeys: {'url': path, 'challengeDate': date},
        );
      }
      rethrow;
    }
  }

  /// Channels, messages and the learner's recorded answers, folded into each
  /// question message. Shared by [fetchTutorHistory] and
  /// [fetchDailyChallenge] — the two endpoints answer in the same shape.
  TutorHistoryResult _toHistory(
    Map<String, dynamic> data, {
    required String path,
    required Map<String, String> keys,
    bool isDailyChallenge = false,
    String? sectionId,
  }) {
    TutorChannel? channelFrom(String key) {
      final raw = data[key];
      return raw is Map<String, dynamic> ? TutorChannel.fromJson(raw) : null;
    }

    final historyChannels = <TutorChannel>[
      for (final item in data['channelhistory'] as List<dynamic>? ?? [])
        if (item is Map<String, dynamic>) TutorChannel.fromJson(item),
    ];

    final raw = data['messages'] as dynamic;
    logPrint("messages ${raw is List ? raw.length : 0}");
    final answers = <Map<String, dynamic>>[
      for (final a in data['answers'] as List<dynamic>? ?? [])
        if (a is Map<String, dynamic>) a,
    ];
    logPrint("answers ${answers.length}");

    final messages = <ChatMessage>[];
    if (raw is List) {
      for (final item in raw) {
        try {
          final message = ChatMessage.fromJson(item);
          if (message.messageRenderType.isQuestion) {
            final rawAnswer = answers.firstWhere(
              (a) => a['questionid'] == message.question?.id,
              orElse: () => const {},
            );
            if (rawAnswer.isNotEmpty) {
              message.answer = Answer.fromJson(rawAnswer);
              message.interactive = false;
            }
          }
          messages.add(message);
        } catch (e, stack) {
          logPrint(e.toString());
          AppErrorHandler.recordNonFatal(
            e,
            stack,
            reason: 'TopicService parsing a chat message failed',
            customKeys: {'url': path, ...keys},
          );
        }
      }
    }

    return TutorHistoryResult(
      currentChannel: channelFrom('currentchannel'),
      activeChannel: channelFrom('activechannel'),
      history: historyChannels,
      messages: messages,
      answers: answers,
      isDailyChallenge: isDailyChallenge,
      sectionId: sectionId,
    );
  }

  /// The tutorial's tutor channel, creating one when [createNew] is set.
  /// On minsur (2026-09-02) `tutorhistory.json?dataid=` answers without
  /// `activechannel` even when a session exists; this endpoint still
  /// returns it.
  Future<TutorChannel?> fetchTutorSession(
    String tutorialId, {
    bool createNew = false,
  }) async {
    const path = 'services/module/entitytutorial/tutorsession.json';
    final data = await _http.getJson(
      path,
      query: {'dataid': tutorialId, if (createNew) 'createnew': 'true'},
    );
    final raw = data['channel'];
    return raw is Map<String, dynamic> ? TutorChannel.fromJson(raw) : null;
  }

  /// start.json, not continue.json: the welcome turn moved to its own
  /// endpoint upstream (2026-09-03).
  Future<void> startTutorial({
    required String tutorialId,
    required String channel,
  }) => _http.postForm(_startPath, [
    MapEntry('context_tutorialid', tutorialId),
    const MapEntry('functionname', 'chat_tutor_welcome'),
    const MapEntry('currentscenario', 'chat_tutor'),
    MapEntry('channel', channel),
    const MapEntry('context_skiploader', 'true'),
  ]);

  /// Same welcome turn as [startTutorial], flagged as the daily challenge
  /// and anchored on a section instead of a tutorial.
  Future<void> startDailyChallenge({
    required String channel,
    required DateTime challengeDate,
    required String sectionId,
  }) => _http.postForm(_startPath, [
    const MapEntry('functionname', 'chat_tutor_welcome'),
    const MapEntry('currentscenario', 'chat_tutor'),
    const MapEntry('context_isdailychallenge', 'true'),
    MapEntry('channel', channel),
    MapEntry('sectionid', sectionId),
    MapEntry('context_sectionid', sectionId),
    const MapEntry('context_skiploader', 'true'),
  ]);

  Future<void> submitAnswer({
    required String channel,
    required String questionId,
    required String selectedOption,
    required String confidence,
    required String sectionId,
    required String componentId,
    String? tutorialId,
  }) => _http.postForm(_continuePath, [
    const MapEntry('currentscenario', 'chat_tutor'),
    const MapEntry('functionname', 'chat_tutor_answer'),
    MapEntry('channel', channel),
    // Stored on `tutoranswer` with the section: progress per topic/subtopic.
    if (tutorialId != null) MapEntry('context_tutorialid', tutorialId),
    MapEntry('context_questionid', questionId),
    MapEntry('context_selectedoption', selectedOption),
    MapEntry('context_confidence', confidence),
    MapEntry('context_sectionid', sectionId),
    MapEntry('context_componentid', componentId),
    const MapEntry('context_skiploader', 'true'),
  ]);

  Future<void> sendFollowUp({
    required String channel,
    required String messageId,
    required String message,
    required String sectionId,
    required String componentId,
    required String tutorialId,
    String? questionId,
    String? selectedOption,
    String? confidence,
  }) => _http.postForm(_continuePath, [
    const MapEntry('currentscenario', 'chat_tutor'),
    const MapEntry('functionname', 'chat_tutor_usercomment'),
    MapEntry('context_tutorialid', tutorialId),
    MapEntry('channel', channel),
    MapEntry('context_query', message),
    MapEntry('context_sectionid', sectionId),
    MapEntry('context_componentid', componentId),
    // The question the chat is about, and the learner's answer on it when
    // already submitted locally: `A`… and noidea|notsure|mostlysure|confident.
    if (questionId != null) MapEntry('context_questionid', questionId),
    if (selectedOption != null)
      MapEntry('context_selectedoption', selectedOption),
    if (confidence != null) MapEntry('context_confidence', confidence),
    const MapEntry('context_skiploader', 'true'),
  ]);
}
