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

class TutorHistoryResult {
  final TutorChannel? currentChannel;
  final TutorChannel? activeChannel;
  final List<TutorChannel> history;
  final List<ChatMessage> messages;

  TutorHistoryResult({
    this.currentChannel,
    this.activeChannel,
    this.history = const [],
    this.messages = const [],
  });
}

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
            'Authorization': 'Bearer $token',
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

            'Authorization': 'Bearer $token',
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

  Future<TutorHistoryResult> fetchTutorHistory({
    required String tutorialId,
    String? channelId,
  }) async {
    final queryParams = <String>[];
    queryParams.add("dataid=$tutorialId");
    if (channelId != null && channelId.isNotEmpty) {
      queryParams.add("channel=$channelId");
    }
    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.join('&')}'
        : '';

    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorhistory.json$queryString";

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      final response = await _client.post(
        targetUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final decoded = (response.data is String
            ? json.decode(response.data)
            : response.data);
        if (decoded is Map<String, dynamic>) {
          // Parse currentchannel
          TutorChannel? currentChannel;
          final currentChannelData = decoded['currentchannel'];
          if (currentChannelData is Map<String, dynamic>) {
            currentChannel = TutorChannel.fromJson(currentChannelData);
          }

          // Parse activechannel
          TutorChannel? activeChannel;
          final activeChannelData = decoded['activechannel'];
          if (activeChannelData is Map<String, dynamic>) {
            activeChannel = TutorChannel.fromJson(activeChannelData);
          }

          // Parse history channels (finished channels only)
          final List<TutorChannel> historyChannels = [];
          final rawHistory = decoded['channelhistory'];
          if (rawHistory is List) {
            for (final item in rawHistory) {
              if (item is Map<String, dynamic>) {
                historyChannels.add(TutorChannel.fromJson(item));
              }
            }
          }

          final history = decoded['messages'] as dynamic;
          logPrint("messages ${history is List ? history.length : 0}");
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
                  customKeys: {
                    'url': targetUrl,
                    'channelId': channelId ?? '',
                    'tutorialId': tutorialId,
                  },
                );
              }
            }
          }
          return TutorHistoryResult(
            currentChannel: currentChannel,
            activeChannel: activeChannel,
            history: historyChannels,
            messages: messages,
          );
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
        customKeys: {
          'url': targetUrl,
          'channelId': channelId ?? '',
          'tutorialId': tutorialId,
        },
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

      String body = 'context_tutorialid=$tutorialId';
      body += '&functionname=chat_tutor_welcome';
      body += '&currentscenario=chat_tutor';
      body += '&channel=$channel';
      body += '&context_skiploader=true';

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
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

      String body = 'context_tutorialid=$tutorialId';
      body += '&functionname=chat_tutor_continue';
      body += '&currentscenario=chat_tutor';
      body += '&channel=$channel';
      if (sectionId != null) body += '&context_sectionid=$sectionId';
      if (componentId != null) body += '&context_componentid=$componentId';
      body += '&context_skiploader=true';

      logPrint("Continuing to $targetUrl with: $body");

      final response = await _client.post(
        targetUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
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
}
