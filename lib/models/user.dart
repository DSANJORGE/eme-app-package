class User {
  final String id;
  final String firstName;
  final String lastName;
  final String screenName;
  final String assetPortrait;
  final String email;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.screenName,
    required this.assetPortrait,
    required this.email,
  });

  String get fullName {
    if (screenName.isNotEmpty) return screenName;
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return '';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      screenName: json['screenname'] as String? ?? '',
      assetPortrait: json['assetportrait'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstName,
      'lastname': lastName,
      'screenname': screenName,
      'assetportrait': assetPortrait,
      'email': email,
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? screenName,
    String? assetPortrait,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      screenName: screenName ?? this.screenName,
      assetPortrait: assetPortrait ?? this.assetPortrait,
      email: email ?? this.email,
    );
  }
}
