class UserProfile {
  final String uuid;
  final String name;
  final String email;
  final String phoneNumber;
  final String? photoUrl;

  UserProfile({
    required this.uuid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
  }) {
    if (uuid.isEmpty) throw ArgumentError('UUID cannot be empty');
    if (name.isEmpty) throw ArgumentError('Name cannot be empty');
    if (email.isEmpty || !email.contains('@'))
      throw ArgumentError('Invalid email');
    if (phoneNumber.isEmpty)
      throw ArgumentError('Phone number cannot be empty');
  }

  // Create from shared preferences
  factory UserProfile.fromSharedPrefs(Map<String, dynamic> data) {
    return UserProfile(
      uuid: data['user_uuid'] ?? '',
      name: data['user_name'] ?? '',
      email: data['user_email'] ?? '',
      phoneNumber: data['user_phone'] ?? '',
      photoUrl: data['user_photo_url'],
    );
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uuid: json['uuid'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'user_uuid': uuid,
      'user_name': name,
      'user_email': email,
      'user_phone': phoneNumber,
      'user_photo_url': photoUrl,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }

  // CopyWith method
  UserProfile copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return UserProfile(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          email == other.email;

  @override
  int get hashCode => uuid.hashCode ^ email.hashCode;
}
