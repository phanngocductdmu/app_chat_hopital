class UserInfoSmall {
  final String name;
  final String avatar;
  final String point;

  UserInfoSmall({
    required this.name,
    required this.avatar,
    required this.point,
  });

  factory UserInfoSmall.fromJson(Map<String, dynamic> json) {
    return UserInfoSmall(
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      point: json['point'] ?? '0',
    );
  }
}
