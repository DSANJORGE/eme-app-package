import 'dart:convert';
import 'package:eme_app_package/models/chat_message.dart';
import 'package:eme_app_package/models/tutor_channel.dart';
import 'package:eme_app_package/services/topic_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorHistoryResult & TopicService', () {
    test('parses patched tutorhistory.json schema correctly', () {
      final sampleJson = {
        'response': {'status': 'ok'},
        'activechannel': {
          'id': 'ch_active_123',
          'name': 'Active Tutorial Session',
          'channeltype': 'tutor',
          'dataid': 'tut_001',
          'date': '2026-08-31 10:00:00',
        },
        'currentchannel': {
          'id': 'ch_active_123',
          'name': 'Active Tutorial Session',
          'channeltype': 'tutor',
          'dataid': 'tut_001',
          'date': '2026-08-31 10:00:00',
        },
        'channelhistory': [
          {
            'id': 'ch_hist_1',
            'name': 'Completed Session 1',
            'channeltype': 'tutor',
            'dataid': 'tut_001',
            'date': '2026-08-30 09:00:00',
          },
          {
            'id': 'ch_hist_2',
            'name': 'Completed Session 2',
            'channeltype': 'tutor',
            'dataid': 'tut_001',
            'date': '2026-08-29 08:00:00',
          },
        ],
        'messages': [
          {
            'id': 'msg_1',
            'channel': 'ch_active_123',
            'user': 'system',
            'message': 'Welcome to the tutorial!',
            'agentcontextvalues': jsonEncode({
              'messagetype': 'welcome',
            }),
            'date': '2026-08-31 10:00:01',
          },
          {
            'id': 'msg_2',
            'channel': 'ch_active_123',
            'user': 'system',
            'message': 'What is Flutter?',
            'agentcontextvalues': jsonEncode({
              'messagetype': 'question',
              'question': {
                'id': 'q_1',
                'question': 'What is Flutter?',
                'options': {
                  'option_a': 'A UI toolkit',
                  'option_b': 'A database',
                },
                'mcqcognitivelevel': 'knowledge',
              },
            }),
            'date': '2026-08-31 10:00:05',
          },
        ],
        'answers': [
          {
            'questionid': 'q_1',
            'answer': 'A UI toolkit',
            'correct': 'true',
          },
        ],
      };

      // Verify channelhistory parsing
      final historyList = (sampleJson['channelhistory'] as List)
          .map((e) => TutorChannel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(historyList.length, 2);
      expect(historyList[0].id, 'ch_hist_1');
      expect(historyList[0].name, 'Completed Session 1');
      expect(historyList[1].id, 'ch_hist_2');

      // Verify activechannel parsing
      final activeChannel = TutorChannel.fromJson(
        sampleJson['activechannel'] as Map<String, dynamic>,
      );
      expect(activeChannel.id, 'ch_active_123');
      expect(activeChannel.name, 'Active Tutorial Session');

      // Verify currentchannel parsing
      final currentChannel = TutorChannel.fromJson(
        sampleJson['currentchannel'] as Map<String, dynamic>,
      );
      expect(currentChannel.id, 'ch_active_123');

      // Verify messages parsing
      final messages = (sampleJson['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(messages.length, 2);
      expect(messages[0].messageType.isWelcome, true);
      expect(messages[1].messageType.isQuestion, true);

      // Verify TutorHistoryResult construction
      final result = TutorHistoryResult(
        activeChannel: activeChannel,
        currentChannel: currentChannel,
        history: historyList,
        messages: messages,
      );

      expect(result.activeChannel?.id, 'ch_active_123');
      expect(result.currentChannel?.id, 'ch_active_123');
      expect(result.history.length, 2);
      expect(result.messages.length, 2);
    });

    test('parses history-selected response where currentchannel is history item', () {
      final sampleJson = {
        'response': {'status': 'ok'},
        'activechannel': {
          'id': 'ch_active_123',
          'name': 'Active Tutorial Session',
        },
        'currentchannel': {
          'id': 'ch_hist_1',
          'name': 'Completed Session 1',
        },
        'channelhistory': [
          {
            'id': 'ch_hist_1',
            'name': 'Completed Session 1',
          },
        ],
        'messages': [
          {
            'id': 'msg_old',
            'message': 'Past message',
            'messagetype': 'welcome',
          },
        ],
      };

      final activeChannel = TutorChannel.fromJson(
        sampleJson['activechannel'] as Map<String, dynamic>,
      );
      final currentChannel = TutorChannel.fromJson(
        sampleJson['currentchannel'] as Map<String, dynamic>,
      );
      final historyList = (sampleJson['channelhistory'] as List)
          .map((e) => TutorChannel.fromJson(e as Map<String, dynamic>))
          .toList();

      final result = TutorHistoryResult(
        activeChannel: activeChannel,
        currentChannel: currentChannel,
        history: historyList,
      );

      expect(result.activeChannel?.id, 'ch_active_123');
      expect(result.currentChannel?.id, 'ch_hist_1');
      expect(result.activeChannel?.id != result.currentChannel?.id, true);
    });
  });
}
