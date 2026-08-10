class TutorChannel {
  final String id;
  final String channelType;
  final String chatApplicationId;
  final String name;
  final String dataId;
  final String searchType;
  final String user;
  final String refreshDate;
  final String date;

  TutorChannel({
    required this.id,
    required this.channelType,
    required this.chatApplicationId,
    required this.name,
    required this.dataId,
    required this.searchType,
    required this.user,
    required this.refreshDate,
    required this.date,
  });

  factory TutorChannel.fromJson(Map<String, dynamic> json) {
    return TutorChannel(
      id: json['id'] as String? ?? '',
      channelType: json['channeltype'] as String? ?? '',
      chatApplicationId: json['chatapplicationid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dataId: json['dataid'] as String? ?? '',
      searchType: json['searchtype'] as String? ?? '',
      user: json['user'] as String? ?? '',
      refreshDate: json['refreshdate'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channeltype': channelType,
      'chatapplicationid': chatApplicationId,
      'name': name,
      'dataid': dataId,
      'searchtype': searchType,
      'user': user,
      'refreshdate': refreshDate,
      'date': date,
    };
  }
}
