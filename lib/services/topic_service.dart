import 'package:eme_app_package/eme_http.dart';
import 'package:eme_app_package/models/chat_message.dart';
import 'package:eme_app_package/utils/log.dart';
import '../models/topic.dart';
import '../models/tutor_channel.dart';
import '../models/tutorial.dart';
import '../utils/error_handler.dart';

/// Parsing and flow only — transport, auth headers, encoding, decoding,
/// logging and HTTP-error recording live behind [EmeHttp]. Catch blocks here
/// record parse errors only; EmeHttpException is already recorded inside the
/// module.
class TopicService {
  final EmeHttp _http;

  TopicService({EmeHttp? http}) : _http = http ?? DioEmeHttp();

  static const _continuePath = 'services/module/entitytutorial/continue.json';

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

  Future<TutorChannel?> fetchTutorChannel(
    String tutorialId, {
    bool createNew = false,
  }) async {
    const path = 'services/module/entitytutorial/tutorsession.json';
    try {
      final data = await _http.getJson(
        path,
        query: {'dataid': tutorialId, if (createNew) 'createnew': 'true'},
      );
      final channel = data['channel'];
      if (channel is Map<String, dynamic>) {
        return TutorChannel.fromJson(channel);
      }
      if (!createNew) {
        return await fetchTutorChannel(tutorialId, createNew: true);
      }
      return null;
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTutorChannel failed',
          customKeys: {'url': path, 'tutorialId': tutorialId},
        );
      }
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchTutorHistory({
    required String channelId,
    String? fromBeforeId,
  }) async {
    const path = 'services/module/entitytutorial/tutorhistory.json';
    try {
      final data = await _http.getJson(
        path,
        query: {'channel': channelId, 'fromid': ?fromBeforeId},
      );
      final history = data['messages'] as dynamic;
      logPrint("messages ${history.length}");
      final List answers = data['answers'] is List ? data['answers'] : [];
      logPrint("answers ${answers.length}");
      final List<ChatMessage> messages = [];
      if (history is List) {
        for (final item in history) {
          try {
            final message = ChatMessage.fromJson(item);
            if (message.messageType.isQuestion) {
              final rawAnswer = answers.isEmpty
                  ? null
                  : answers.firstWhere(
                      (a) => a['questionid'] == message.question?.id,
                      orElse: () => null,
                    );
              if (rawAnswer != null) {
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
              reason:
                  'TopicService.fetchTutorHistory failed to parse chat message',
              customKeys: {'url': path, 'channelId': channelId},
            );
          }
        }
      }
      return messages;
    } catch (e, stack) {
      if (e is! EmeHttpException) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'TopicService.fetchTutorHistory failed',
          customKeys: {'url': path, 'channelId': channelId},
        );
      }
      rethrow;
    }
  }

  Future<void> startTutorial({
    required String tutorialId,
    required String channel,
  }) => _http.postForm(_continuePath, [
    MapEntry('context_tutorialid', tutorialId),
    const MapEntry('functionname', 'chat_tutor_welcome'),
    const MapEntry('currentscenario', 'chat_tutor'),
    MapEntry('channel', channel),
    const MapEntry('context_skiploader', 'true'),
  ]);

  Future<void> continueTutorial({
    required String tutorialId,
    String? channel,
    String? sectionId,
    String? componentId,
  }) => _http.postForm(_continuePath, [
    MapEntry('context_tutorialid', tutorialId),
    const MapEntry('functionname', 'chat_tutor_continue'),
    const MapEntry('currentscenario', 'chat_tutor'),
    // '$channel': null stays the literal "null" the server has always seen.
    MapEntry('channel', '$channel'),
    if (sectionId != null) MapEntry('context_sectionid', sectionId),
    if (componentId != null) MapEntry('context_componentid', componentId),
    const MapEntry('context_skiploader', 'true'),
  ]);

  Future<void> submitAnswer({
    required String channel,
    required String questionId,
    required String selectedOption,
    required String confidence,
    required String sectionId,
    required String componentId,
  }) => _http.postForm(_continuePath, [
    const MapEntry('currentscenario', 'chat_tutor'),
    const MapEntry('functionname', 'chat_tutor_answer'),
    MapEntry('channel', channel),
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
  }) => _http.postForm(_continuePath, [
    const MapEntry('currentscenario', 'chat_tutor'),
    const MapEntry('functionname', 'chat_tutor_usercomment'),
    MapEntry('context_tutorialid', tutorialId),
    MapEntry('channel', channel),
    MapEntry('context_query', message),
    MapEntry('context_sectionid', sectionId),
    MapEntry('context_componentid', componentId),
    const MapEntry('context_skiploader', 'true'),
  ]);
}
