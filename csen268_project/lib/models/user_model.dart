class AppUser {
  final String id;
  final String username;
  final String password;
  final String userType;

  AppUser({required this.id, required this.username, required this.password, required this.userType});

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      username: data['username'] as String,
      password: data['password'] as String,
      userType: data['userType'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'userType': userType,
    };
  }

  static const String userTypeNormal = 'User';
  static const String userTypePremium = 'Premium';
}
