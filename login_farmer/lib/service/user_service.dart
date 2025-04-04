///Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/login_farmer/lib/service/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_farmer/models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Update Firebase user profile
      await currentUser.updateProfile(
        displayName: name ?? currentUser.displayName,
      );

      // Update local storage
      await _updateLocalStorage(name: name, phoneNumber: phoneNumber);

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
      };
    }
  }

  // Change email
  Future<Map<String, dynamic>> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update email
      await currentUser.updateEmail(newEmail);

      // Update local storage
      await _updateLocalStorage(email: newEmail);

      return {
        'success': true,
        'message': 'Email updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to change email: ${e.toString()}',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPassword);

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to change password: ${e.toString()}',
      };
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Delete Firebase user
      await currentUser.delete();

      // Clear local storage
      await _clearLocalStorage();

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete account: ${e.toString()}',
      };
    }
  }

  // Save user data to SharedPreferences
  Future<void> saveUserToLocalStorage(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_uuid', user.uuid);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phoneNumber ?? '');
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
      phoneNumber: '', // Firebase auth doesn't store phone number by default
      photoUrl: prefs.getString('user_photo_url'),
    );
  }

  // Update local storage with new data
  Future<void> _updateLocalStorage({
    String? name,
    String? phoneNumber,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);
    // Note: Phone number isn't stored in Firebase Auth by default
  }

  // Clear local storage
  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
