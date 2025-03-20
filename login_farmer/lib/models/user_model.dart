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
  });

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

  // Method to convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'user_uuid': uuid,
      'user_name': name,
      'user_email': email,
      'user_phone': phoneNumber,
      'user_photo_url': photoUrl,
    };
  }
}
