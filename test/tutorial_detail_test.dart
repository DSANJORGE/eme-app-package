import 'package:eme_app_package/eme_http.dart';
import 'package:eme_app_package/models/tutorial.dart';
import 'package:eme_app_package/services/topic_service.dart';
import 'package:eme_app_package/testing/fake_eme_http.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trimmed from a real response
/// (`tutorial.json?entitytutorial=AZ_tFsHKimsE6yOlqXpA`, 2026-08-31): two
/// sections, three MCQs, with the same questions echoed onto the paragraph
/// and asset rows exactly as the server does it.
Map<String, dynamic> get _detailPayload => {
  'response': {'status': 'ok', 'userid': 'testautologinuser'},
  'tutorial': {
    'id': 'TUT1',
    'entitytopicid': 'TOPIC1',
    'title': 'Definición y Características',
  },
  'sections': [
    {
      'id': 'SEC1',
      'title': '1. Fundamentos',
      'contents': [
        {'id': 'c1', 'contenttype': 'heading', 'content': 'Fundamentos'},
        // Question echoed onto a paragraph row — must NOT count as an MCQ.
        {
          'id': 'c2',
          'contenttype': 'paragraph',
          'content': 'Los derechos humanos…',
          'question': _q1,
        },
        {
          'id': 'c3',
          'contenttype': 'asset',
          'contentrole': 'featureimage',
          'asseturl': '/img/a.jpg',
          'content': '',
          'question': _q1,
        },
        {
          'id': 'c4',
          'contenttype': 'mcq',
          'contentrole': 'exercise',
          'content': '',
          'question': _q1,
        },
        {
          'id': 'c5',
          'contenttype': 'mcq',
          'contentrole': 'exercise',
          'content': '',
          'question': _q2,
        },
      ],
    },
    {
      'id': 'SEC2',
      'title': '2. Empresas',
      'contents': [
        {
          'id': 'c6',
          'contenttype': 'mcq',
          'contentrole': 'exercise',
          'content': '',
          // Same question id as _q1: ids are unique per section only.
          'question': _q3,
        },
      ],
    },
  ],
};

const _q1 = {
  'id': '1',
  'question': '¿Qué son los Derechos Humanos?',
  'options': {
    'option_a': 'Principios inherentes a toda persona',
    'option_b': 'Privilegios que la empresa otorga',
    'option_c': 'Normas de adopción voluntaria',
    'option_d': 'Beneficios por cumplir metas',
  },
  'correctoption': 'option_a',
  'rationale': 'Corresponden a toda persona por existir.',
  'cognitivelevel': 'beginner',
};

const _q2 = {
  'id': '2',
  'question': '¿Qué característica los define?',
  'options': {
    'option_a': 'Son negociables',
    'option_b': 'Son universales e inalienables',
  },
  // Short form: the answer key is sometimes just the letter.
  'correctoption': 'b',
  'cognitivelevel': 'competent',
};

const _q3 = {
  'id': '1',
  'question': '¿Qué marco internacional aplica?',
  'options': {'option_a': 'Ninguno', 'option_b': 'Principios Rectores'},
  'correctoption': 'option_b',
  'cognitivelevel': 'expert',
};

void main() {
  late FakeEmeHttp http;
  late TopicService service;

  const path = 'services/module/entitytutorial/tutorial.json';

  setUp(() {
    http = FakeEmeHttp();
    service = TopicService(http: http);
  });

  group('fetchTutorialDetail', () {
    test('requests the tutorial path with the entitytutorial parameter', () async {
      http.canned[path] = _detailPayload;

      await service.fetchTutorialDetail('TUT1');

      expect(http.requests.single.$1, path);
      expect(http.requests.single.$2, {'entitytutorial': 'TUT1'});
    });

    test('parses sections from the top level of the response', () async {
      http.canned[path] = _detailPayload;

      final detail = await service.fetchTutorialDetail('TUT1');

      expect(detail, isNotNull);
      expect(detail!.sections.map((s) => s.id), ['SEC1', 'SEC2']);
      expect(detail.sections.first.title, '1. Fundamentos');
      expect(detail.sections.first.contents, hasLength(5));
    });

    test('mcqQuestions reads mcq rows only, ignoring echoed copies', () async {
      http.canned[path] = _detailPayload;

      final detail = await service.fetchTutorialDetail('TUT1');
      final mcqs = detail!.mcqQuestions;

      // Five rows carry a question object; only three are real MCQs.
      final rowsWithQuestion = detail.sections
          .expand((s) => s.contents)
          .where((c) => c.question != null)
          .length;
      expect(rowsWithQuestion, 5);
      expect(mcqs, hasLength(3));
      expect(mcqs.map((m) => m.contentId), ['c4', 'c5', 'c6']);
      expect(mcqs.map((m) => m.section.id), ['SEC1', 'SEC1', 'SEC2']);
    });

    test('question ids repeat across sections, so both are carried', () async {
      http.canned[path] = _detailPayload;

      final mcqs = (await service.fetchTutorialDetail('TUT1'))!.mcqQuestions;

      final first = mcqs.first;
      final last = mcqs.last;
      expect(first.question.id, '1');
      expect(last.question.id, '1'); // same id, different section
      expect(first.section.id, isNot(last.section.id));
    });

    test('pairs each MCQ with the asset row tagged with its question', () async {
      http.canned[path] = _detailPayload;

      final mcqs = (await service.fetchTutorialDetail('TUT1'))!.mcqQuestions;

      expect(mcqs[0].image?.assetUrl, '/img/a.jpg');
      expect(mcqs[1].image, isNull); // no asset row for question 2
      expect(mcqs[2].image, isNull); // same id as q1, other section
    });

    test('maps the answer key to an index over key-sorted options', () async {
      http.canned[path] = _detailPayload;

      final mcqs = (await service.fetchTutorialDetail('TUT1'))!.mcqQuestions;

      expect(mcqs[0].question.correctAnswerIndex, 0); // 'option_a'
      expect(mcqs[0].question.optionsList.first,
          'Principios inherentes a toda persona');
      expect(mcqs[1].question.correctAnswerIndex, 1); // bare 'b'
      expect(mcqs[2].question.correctAnswerIndex, 1); // 'option_b'
    });

    test('carries the rationale and cognitive level when present', () async {
      http.canned[path] = _detailPayload;

      final mcqs = (await service.fetchTutorialDetail('TUT1'))!.mcqQuestions;

      expect(mcqs[0].question.rationale,
          'Corresponden a toda persona por existir.');
      expect(mcqs[0].question.cognitiveLevel, 'beginner');
      // Absent rationale is empty, never null.
      expect(mcqs[1].question.rationale, '');
    });

    test('accepts the socket spelling of the cognitive level', () {
      final q = McqQuestion.fromJson({
        'id': '9',
        'question': 'q',
        'options': {'option_a': 'a'},
        'correctoption': 'option_a',
        'mcqcognitivelevel': 'expert',
      });

      expect(q.cognitiveLevel, 'expert');
    });

    test('returns null when the response carries no sections', () async {
      http.canned[path] = {
        'response': {'status': 'ok'},
        'tutorial': {'id': 'TUT1'},
      };

      expect(await service.fetchTutorialDetail('TUT1'), isNull);
    });

    test('rethrows transport failures for the caller to fall back on', () async {
      // Nothing canned: FakeEmeHttp throws a 404 EmeHttpException.
      expect(
        () => service.fetchTutorialDetail('TUT1'),
        throwsA(isA<EmeHttpException>()),
      );
    });
  });
}
