import 'dart:convert';
import 'package:eme_app_package/utils/log.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

enum MessageRenderType {
  welcome,
  text,
  question,
  answer,
  answereval,
  asset,
  usercomment,
  end,
  agentcomment,
  progressupdate;

  bool get isQuestion => this == MessageRenderType.question;
  bool get isAsset => this == MessageRenderType.asset;
  bool get isWelcome => this == MessageRenderType.welcome;
  bool get isText => this == MessageRenderType.text;
  bool get isAnswer => this == MessageRenderType.answer;
  bool get isAnswerEval => this == MessageRenderType.answereval;
  bool get isUserComment => this == MessageRenderType.usercomment;
  bool get isEnd => this == MessageRenderType.end;
  bool get isAgentComment => this == MessageRenderType.agentcomment;
  bool get isProgressUpdate => this == MessageRenderType.progressupdate;

  factory MessageRenderType.fromName(String name) {
    return MessageRenderType.values.firstWhere(
      (element) => element.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MessageRenderType.text,
    );
  }
}

class AgentContextValues {
  final MessageRenderType messageRenderType;
  final String? tutorialId;
  final String? sectionId;
  final String? componentId;
  final String? componentType;
  final String? componentContent;
  final bool? isCorrect;
  final Question? question;
  final Asset? asset;
  final ProgressUpdate? progressUpdate;
  bool? interactive = false;

  AgentContextValues({
    this.messageRenderType = MessageRenderType.text,
    this.tutorialId = "",
    this.sectionId = "",
    this.componentId = "",
    this.componentType,
    this.componentContent = "",
    this.isCorrect,
    this.question,
    this.asset,
    this.progressUpdate,
    this.interactive = false,
  });

  // set interactive
  void setInteractive(bool interactive) {
    this.interactive = interactive;
  }

  factory AgentContextValues.fromJson(Map<String, dynamic> json) {
    String? rawMessageRenderType = json['messagerendertype']
        ?.toString()
        .toLowerCase();

    final messageRenderType = MessageRenderType.values.firstWhere(
      (element) => element.name.toLowerCase() == rawMessageRenderType,
      orElse: () => MessageRenderType.text,
    );

    return AgentContextValues(
      messageRenderType: messageRenderType,
      tutorialId: json['tutorialid']?.toString(),
      sectionId: json['sectionid']?.toString(),
      componentId: json['componentid']?.toString(),
      componentType: json['componenttype']?.toString(),
      componentContent: json['componentcontent']?.toString(),
      isCorrect: bool.tryParse(json['iscorrect']?.toString() ?? ''),
      question: json['question'] != null
          ? Question.fromJson(json['question'])
          : null,
      asset: json['asset'] != null ? Asset.fromJson(json['asset']) : null,
      progressUpdate: json['progressupdate'] != null
          ? ProgressUpdate.fromJson(json['progressupdate'])
          : (messageRenderType == MessageRenderType.progressupdate
                ? ProgressUpdate.fromJson(json)
                : null),
      interactive: json['interactive'] == "yes" ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messagerendertype': messageRenderType.name,
      'tutorialid': tutorialId,
      'sectionid': sectionId,
      'componentid': componentId,
      'componenttype': componentType,
      'componentcontent': componentContent,
      if (isCorrect != null) 'iscorrect': isCorrect!.toString(),
      'question': question?.toJson(),
      'asset': asset?.toJson(),
      'progressupdate': progressUpdate?.toJson(),
      'interactive': interactive! ? "yes" : "no",
    };
  }

  String? get text {
    if (messageRenderType.isQuestion) {
      return question!.question;
    }
    return componentContent;
  }
}

class ChatMessage {
  final String messageId;
  final String channel;
  final String userId;
  final String? message;
  final String? command;
  final String? replyToId;
  final DateTime createdAt;
  final AgentContextValues? agentContextValues;

  ChatMessage({
    required this.messageId,
    required this.channel,
    required this.userId,
    this.message,
    this.command,
    this.replyToId,
    required this.createdAt,
    this.agentContextValues,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // date
    DateTime? parsedCreatedAt;
    final rawCreatedAt = json['date'] ?? json['createdat'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.parse(rawCreatedAt).toLocal();
    } else if (rawCreatedAt is num) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(
        rawCreatedAt.toInt(),
      ).toLocal();
    } else {
      parsedCreatedAt = DateTime.now().toLocal();
    }

    // context values
    final rawAgentContext = json['agentcontextvalues'];
    Map<String, dynamic> decodedContext = {};
    if (rawAgentContext != null &&
        rawAgentContext.toString().trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAgentContext.toString());
        if (decoded is Map<String, dynamic>) {
          decodedContext = decoded;
        }
      } catch (e, stack) {
        logPrint('Error decoding agentcontextvalues: $e');
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error decoding agentcontextvalues in ChatMessage.fromJson',
          customKeys: {'rawAgentContext': rawAgentContext.toString()},
        );
      }
    }
    AgentContextValues agentContextValues = AgentContextValues.fromJson(
      decodedContext,
    );

    return ChatMessage(
      messageId: (json['messageid'] ?? json['id']).toString(),
      channel: json['channel'].toString(),
      userId: (json['user'] ?? json['userid']).toString(),
      message: json['message']?.toString() ?? '',
      command: json['command']?.toString(),
      replyToId: (json['replytoid'] ?? json['replyToId'])?.toString(),
      createdAt: parsedCreatedAt,
      agentContextValues: agentContextValues,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'messageid': messageId,
      'channel': channel,
      'userid': userId,
      if (message != null) 'message': message,
      if (command != null) 'command': command,
      if (replyToId != null) 'replytoid': replyToId,
      'createdat': createdAt.toIso8601String(),
      'agentcontextvalues': agentContextValues?.toJson(),
    };
    return map;
  }

  bool get isMessageRemoved => command == 'messageremoved';
  bool get isKeepAlive => command == 'keepalive';

  String get text {
    final textContent = agentContextValues?.text;
    if (textContent != null && textContent.isNotEmpty) return textContent;
    return message ?? '';
  }

  bool get isUser => userId == AuthService.userId;

  bool get isAI => !isUser;

  String get sender => isUser ? 'user' : 'ai';

  AgentContextValues get contextValues =>
      agentContextValues ?? AgentContextValues.fromJson({});

  MessageRenderType get messageRenderType => contextValues.messageRenderType;
  Question? get question => contextValues.question;

  Answer? get answer => question?.answer;
  set answer(Answer? newAnswer) {
    if (question != null) {
      question!.answer = newAnswer;
    }
  }

  Asset? get asset => contextValues.asset;
  String? get tutorialId => contextValues.tutorialId;
  String? get sectionId => contextValues.sectionId;
  String? get componentId => contextValues.componentId;
  String? get componentType => contextValues.componentType;
  String? get textContent => contextValues.componentContent;
  ProgressUpdate? get progressUpdate => contextValues.progressUpdate;
  bool? get isCorrect => contextValues.isCorrect;
  bool get interactive => contextValues.interactive ?? false;
  set interactive(bool newInteractive) {
    contextValues.interactive = newInteractive;
  }

  ChatMessage copyWith({
    String? messageId,
    String? channel,
    String? userId,
    String? message,
    String? command,
    String? replyToId,
    DateTime? createdAt,
    AgentContextValues? agentContextValues,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      channel: channel ?? this.channel,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      command: command ?? this.command,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      agentContextValues: agentContextValues ?? this.agentContextValues,
    );
  }
}

class Question {
  final String id;
  final String question;
  final Map<OptionsKey, String> options;
  final String cognitiveLevel;
  Answer? answer;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.cognitiveLevel,
    this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>;
    final mappedOptions = <OptionsKey, String>{};
    options.forEach((key, value) {
      if (value != null &&
          value.toString() != 'null' &&
          value.toString().trim().isNotEmpty) {
        mappedOptions[OptionsKey.fromString(key)] = value.toString();
      }
    });

    final sortedOptions = Map.fromEntries(
      mappedOptions.entries.toList()
        ..sort((a, b) => a.key.index.compareTo(b.key.index)),
    );

    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      options: sortedOptions,
      cognitiveLevel: json['mcqcognitivelevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'cognitivelevel': cognitiveLevel,
      'answer': answer?.toJson(),
    };
  }
}

enum OptionsKey {
  optionA,
  optionB,
  optionC,
  optionD,
  optionE,
  optionF;

  factory OptionsKey.fromString(String key) {
    switch (key) {
      case 'option_a':
        return OptionsKey.optionA;
      case 'option_b':
        return OptionsKey.optionB;
      case 'option_c':
        return OptionsKey.optionC;
      case 'option_d':
        return OptionsKey.optionD;
      case 'option_e':
        return OptionsKey.optionE;
      case 'option_f':
        return OptionsKey.optionF;
      default:
        throw ArgumentError('Invalid OptionsKey: $key');
    }
  }

  String toStr() {
    switch (this) {
      case OptionsKey.optionA:
        return 'option_a';
      case OptionsKey.optionB:
        return 'option_b';
      case OptionsKey.optionC:
        return 'option_c';
      case OptionsKey.optionD:
        return 'option_d';
      case OptionsKey.optionE:
        return 'option_e';
      case OptionsKey.optionF:
        return 'option_f';
    }
  }

  String get letter => toStr().split('_').last.toUpperCase();
}

enum Confidence {
  noidea,
  notsure,
  mostlysure,
  confident;

  factory Confidence.fromStr(String key) {
    switch (key) {
      case 'noidea':
        return Confidence.noidea;
      case 'notsure':
        return Confidence.notsure;
      case 'mostlysure':
        return Confidence.mostlysure;
      case 'confident':
        return Confidence.confident;
      default:
        throw ArgumentError('Invalid Confidence: $key');
    }
  }

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case Confidence.noidea:
        return l10n.noIdea;
      case Confidence.notsure:
        return l10n.notSure;
      case Confidence.mostlysure:
        return l10n.mostlySure;
      case Confidence.confident:
        return l10n.confident;
    }
  }
}

class Asset {
  final String id;
  final String thumbnail;
  final String url;
  final String mediaType;

  Asset({
    required this.id,
    required this.thumbnail,
    required this.url,
    required this.mediaType,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: (json['id'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      mediaType: (json['mediatype'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thumbnail': thumbnail,
      'url': url,
      'mediatype': mediaType,
    };
  }
}

class Answer {
  OptionsKey? selectedOption;
  Confidence? confidence;
  bool? isCorrect;

  // set seleced
  void setSelectedOption(OptionsKey option) {
    selectedOption = option;
  }

  // set confidence
  void setConfidence(Confidence confidence) {
    this.confidence = confidence;
  }

  Answer({this.selectedOption, this.confidence, this.isCorrect});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      selectedOption: json['selectedoption'] != null
          ? OptionsKey.fromString(json['selectedoption'])
          : null,
      confidence: json['confidence'] != null
          ? Confidence.fromStr(json['confidence'])
          : null,
      isCorrect: bool.tryParse(json['iscorrect']) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedoption': selectedOption?.toStr(),
      'confidence': confidence?.name,
      'iscorrect': isCorrect,
    };
  }
}

class ProgressUpdate {
  final double beginnerProgress;
  final double competentProgress;
  final double expertProgress;

  ProgressUpdate({
    required this.beginnerProgress,
    required this.competentProgress,
    required this.expertProgress,
  });

  factory ProgressUpdate.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ProgressUpdate(
      beginnerProgress: parseDouble(json['beginnerprogress']),
      competentProgress: parseDouble(json['competentprogress']),
      expertProgress: parseDouble(json['expertprogress']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beginnerprogress': beginnerProgress,
      'competentprogress': competentProgress,
      'expertprogress': expertProgress,
    };
  }
}
