import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_eme_base/models/chat_message.dart';
import 'package:flutter_eme_base/services/auth_service.dart';
import 'package:flutter_eme_base/utils/log.dart';
import '../models/topic.dart';
import '../models/tutor_channel.dart';
import '../models/tutorial.dart';

import 'workspace_service.dart';

class TopicService {
  final http.Client _client;
  final String? _customMediaDBRoot;

  TopicService({http.Client? client, String? mediaDBRoot})
    : _client = client ?? http.Client(),
      _customMediaDBRoot = mediaDBRoot;

  String get mediaDBRoot =>
      _customMediaDBRoot ?? WorkspaceService.currentMediaDBRoot;

  Future<List<Topic>> fetchTopics({bool fallbackToMock = true}) async {
    final targetUrl = "$mediaDBRoot/services/module/entitytopic/topics.json";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
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
        throw Exception(
          'Failed to fetch topics. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching from $targetUrl');
      rethrow;
    }
  }

  Future<List<Tutorial>> fetchTutorialsForTopic(String topicId) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorials.json?entitytopic=$topicId";
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
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
    } catch (e) {
      logPrint('TopicService error fetching tutorials from $targetUrl');
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
    final uri = Uri.parse(targetUrl);

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
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
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchTutorHistory({
    required String channelId,
    String? fromBeforeId,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/tutorhistory.json?channel=$channelId${fromBeforeId != null ? '&fromid=$fromBeforeId' : ''}";
    final url = Uri.parse(targetUrl);

    logPrint("fetchTutorHistory $targetUrl");

    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
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
              } catch (e) {
                logPrint(e.toString());
                logPrint(
                  'TopicService error fetching tutor history from $targetUrl',
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
    } catch (e) {
      logPrint('TopicService error fetching tutor history from $targetUrl');
      rethrow;
    }
  }

  Future<void> startTutorial({
    required String tutorialId,
    required String channel,
  }) async {
    final targetUrl =
        "$mediaDBRoot/services/module/entitytutorial/continue.json";
    final uri = Uri.parse(targetUrl);

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
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');
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
    final uri = Uri.parse(targetUrl);

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

      logPrint("Continuing with: $body");

      final response = await _client.post(
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        logPrint('TopicService error fetching tutor channels from $targetUrl');
      }
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
    final uri = Uri.parse(targetUrl);
    try {
      final Map<String, String> credentials =
          await AuthService.getCredentials();
      final String token = credentials['entermediakey']!;

      String body = 'currentscenario=chat_tutor';
      body += '&functionname=chat_tutor_answer';
      body += '&channel=$channel';
      body += '&context_questionid=$questionId';
      body += '&context_selectedoption=$selectedOption';
      body += '&context_confidence=$confidence';
      body += '&context_sectionid=$sectionId';
      body += '&context_componentid=$componentId';
      body += '&context_skiploader=true';

      final response = await _client.post(
        uri,
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-tokentype': 'entermedia',
          'X-token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch tutor channels. Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      logPrint('TopicService error fetching tutor channels from $targetUrl');

      rethrow;
    }
  }
}
