class User {
  final String id;
  final String firstName;
  final String lastName;
  final String screenName;
  final String assetPortrait;
  final String email;
  final bool dataConsent;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.screenName,
    required this.assetPortrait,
    required this.email,
    this.dataConsent = false,
  });

  String get displayName {
    if (screenName.isNotEmpty) return screenName;
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return 'N/A';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      screenName: json['screenname'] as String? ?? '',
      assetPortrait: json['assetportrait'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dataConsent: bool.parse(json['dataconsent'] as String? ?? 'false'),
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
      'dataconsent': dataConsent,
    };
  }
}
