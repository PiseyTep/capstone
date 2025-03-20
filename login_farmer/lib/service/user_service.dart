import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_farmer/models/user_model.dart'; // Import your user model

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user data to Firestore during signup
  Future<void> saveUserDataToFirestore({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'uuid': currentUser.uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'photoUrl': currentUser.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Get user data from Firestore
  Future<UserProfile?> getUserDataFromFirestore() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserProfile(
          uuid: currentUser.uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          photoUrl: data['photoUrl'],
        );
      }
    }
    return null;
  }

  // Save user data to SharedPreferences
  Future<void> saveUserToLocalStorage(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_uuid', user.uuid);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phoneNumber);
    if (user.photoUrl != null) {
      await prefs.setString('user_photo_url', user.photoUrl!);
    }
  }

  // Get user data from SharedPreferences
  Future<UserProfile?> getUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final userUuid = prefs.getString('user_uuid');
    if (userUuid == null || userUuid.isEmpty) {
      return null;
    }

    return UserProfile(
      uuid: userUuid,
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      phoneNumber: prefs.getString('user_phone') ?? '',
      photoUrl: prefs.getString('user_photo_url'),
    );
  }
}
