// lib/models/user.dart
class User {
  final String id;
  final String email;
  String? username;
  String? phoneNumber;
  String? avatar;

  User({
    required this.id,
    required this.email,
    this.username,
    this.phoneNumber,
    this.avatar,
  });

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? phoneNumber,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phone_number': phoneNumber,
      'avatar': avatar,
    };
  }
}
