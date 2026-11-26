class UserProfile {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? imagePath;
  final String role;

  const UserProfile({
    this.id = 1,
    required this.name,
    this.phone,
    this.email,
    this.imagePath,
    this.role = 'manager',
  });

  bool get isManager => role == 'manager';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'image_path': imagePath,
        'role': role,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: (map['id'] as int?) ?? 1,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        imagePath: map['image_path'] as String?,
        role: (map['role'] as String?) ?? 'manager',
      );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? imagePath,
    String? role,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        imagePath: imagePath ?? this.imagePath,
        role: role ?? this.role,
      );
}
