import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:eme_app_package/models/chat_message.dart';
import 'package:eme_app_package/services/auth_service.dart';
import 'package:eme_app_package/utils/dio.dart';
import 'package:eme_app_package/utils/log.dart';
import '../models/topic.dart';
import '../models/tutor_channel.dart';
import '../models/tutorial.dart';
import '../utils/error_handler.dart';

import 'workspace_service.dart';

class TopicService {
  final Dio _client;
  final String? _customMediaDBRoot;

  TopicService({Dio? client, String? mediaDBRoot})
    : _client = client ?? DioUtil.dio,
      _customMediaDBRoot = mediaDBRoot;

  String get mediaDBRoot =>
      _customMediaDBRoot ?? WorkspaceService.currentMediaDBRoot;

  Future<List<Topic>> fetchTopics({bool fallbackToMock = true}) async {
    final targetUrl = "$mediaDBRoot/services/module/entitytopic/topics.json";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        targetUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
        ),
      );

      if (response.statusCode == 200) {
        final decoded = (response.data is String
            ? json.decode(response.data)
            : response.data);
        List<dynamic> jsonList;

        if (decoded is Map<String, dynamic>) {
          jsonList = decoded['topics'] as List<dynamic>? ?? [];
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }

        return jsonList
            .map((item) => Topic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        logPrint(
          'Failed to fetch topics. Server returned HTTP ${response.statusCode}',
        );
        return [];
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.fetchTopics failed',
        customKeys: {'url': targetUrl},
      );
      return [];
    }
  }

  Future<List<Tutorial>> fetchTutorialsForTopic(String topicId) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorials.json?entitytopic=$topicId";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        targetUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
        ),
      );

      if (response.statusCode == 200) {
        final decoded = (response.data is String
            ? json.decode(response.data)
            : response.data);
        List<dynamic> jsonList;

        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          jsonList =
              decoded['tutorials'] as List<dynamic>? ??
              decoded['data'] as List<dynamic>? ??
              [];
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }

        return jsonList
            .map((item) => Tutorial.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch tutorials. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutorials from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.fetchTutorialsForTopic failed',
        customKeys: {'url': targetUrl, 'topicId': topicId},
      );
      rethrow;
    }
  }

  Future<TutorChannel?> fetchTutorChannel(
    String tutorialId, {
    bool createNew = false,
  }) async {
    String targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorsession.json?dataid=$tutorialId";
    if (createNew) targetUrl += "&createnew=$createNew";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        targetUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
        ),
      );

      if (response.statusCode == 200) {
        final decoded = (response.data is String
            ? json.decode(response.data)
            : response.data);
        if (decoded is Map<String, dynamic>) {
          final channel = decoded['channel'];
          if (channel is Map<String, dynamic>) {
            return TutorChannel.fromJson(channel);
          }
          if (!createNew) {
            return await fetchTutorChannel(tutorialId, createNew: true);
          }
          return null;
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }
      } else {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.fetchTutorChannel failed',
        customKeys: {'url': targetUrl, 'tutorialId': tutorialId},
      );
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchTutorHistory({
    required String channelId,
    String? fromBeforeId,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorhistory.json?channel=$channelId${fromBeforeId != null ? '&fromid=$fromBeforeId' : ''}";

    logPrint("fetchTutorHistory $targetUrl");

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        targetUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
        ),
      );

      if (response.statusCode == 200) {
        final decoded = (response.data is String
            ? json.decode(response.data)
            : response.data);
        if (decoded is Map<String, dynamic>) {
          final history = decoded['messages'] as dynamic;
          logPrint("messages ${history.length}");
          final List answers = decoded['answers'] is List
              ? decoded['answers']
              : [];
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
                logPrint(
                  'TopicService error fetching tutor history from $targetUrl',
                );
                AppErrorHandler.recordNonFatal(
                  e,
                  stack,
                  reason:
                      'TopicService.fetchTutorHistory failed to parse chat message',
                  customKeys: {'url': targetUrl, 'channelId': channelId},
                );
              }
            }
          }
          return messages;
        } else {
          throw FormatException('Unexpected response format from $targetUrl');
        }
      } else {
        throw Exception(
          'Failed to fetch tutor history. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutor history from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.fetchTutorHistory failed',
        customKeys: {'url': targetUrl, 'channelId': channelId},
      );
      rethrow;
    }
  }

  Future<void> startTutorial({
    required String tutorialId,
    required String channel,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/continue.json";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      // Map body so Dio percent-encodes values; hand-concat broke on &/=/%.
      final body = {
        'context_tutorialid': tutorialId,
        'functionname': 'chat_tutor_welcome',
        'currentscenario': 'chat_tutor',
        'channel': channel,
        'context_skiploader': 'true',
      };

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.startTutorial failed',
        customKeys: {
          'url': targetUrl,
          'tutorialId': tutorialId,
          'channel': channel,
        },
      );
      rethrow;
    }
  }

  Future<void> continueTutorial({
    required String tutorialId,
    String? channel,
    String? sectionId,
    String? componentId,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/continue.json";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      final body = {
        'context_tutorialid': tutorialId,
        'functionname': 'chat_tutor_continue',
        'currentscenario': 'chat_tutor',
        'channel': '$channel', // was interpolated; null stays literal "null"
        'context_sectionid': ?sectionId,
        'context_componentid': ?componentId,
        'context_skiploader': 'true',
      };

      logPrint("Continuing to $targetUrl with: $body");

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        logPrint('TopicService error fetching tutor channels from $targetUrl');
      }
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.continueTutorial failed',
        customKeys: {
          'url': targetUrl,
          'tutorialId': tutorialId,
          'channel': channel ?? '',
        },
      );
      rethrow;
    }
  }

  Future<void> submitAnswer({
    required String channel,
    required String questionId,
    required String selectedOption,
    required String confidence,
    required String sectionId,
    required String componentId,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/continue.json";
    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      final body = {
        'currentscenario': 'chat_tutor',
        'functionname': 'chat_tutor_answer',
        'channel': channel,
        'context_questionid': questionId,
        'context_selectedoption': selectedOption,
        'context_confidence': confidence,
        'context_sectionid': sectionId,
        'context_componentid': componentId,
        'context_skiploader': 'true',
      };

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.submitAnswer failed',
        customKeys: {
          'url': targetUrl,
          'channel': channel,
          'questionId': questionId,
        },
      );
      rethrow;
    }
  }

  Future<void> sendFollowUp({
    required String channel,
    required String messageId,
    required String message,
    required String sectionId,
    required String componentId,
    required String tutorialId,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/continue.json";
    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      final body = {
        'currentscenario': 'chat_tutor',
        'functionname': 'chat_tutor_usercomment',
        'context_tutorialid': tutorialId,
        'channel': channel,
        'context_query': message, // user free text — the original :475 bug
        'context_sectionid': sectionId,
        'context_componentid': componentId,
        'context_skiploader': 'true',
      };

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'X-tokentype': 'entermedia',
            'X-token': token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'TopicService.sendFollowUp failed',
        customKeys: {'url': targetUrl, 'channel': channel, 'message': message},
      );
      rethrow;
    }
  }
}
