import 'dart:convert';
import 'package:login_farmer/main.dart';
import 'package:login_farmer/models/booking_model.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  final ApiService _apiService = getIt<ApiService>();

  // Get all bookings for the current user
  Future<List<BookingModel>> getBookings() async {
    try {
      final result = await _apiService.getData('user/rentals');

      if (result['success'] == true && result['data'] != null) {
        final List bookingsJson = result['data'];
        return bookingsJson.map((json) => BookingModel.fromJson(json)).toList();
      } else {
        throw Exception(result['message'] ?? 'Failed to load bookings');
      }
    } catch (e) {
      // Fall back to local storage if API fails
      return _getLocalBookings();
    }
  }

  // Save a booking through the API
  Future<Map<String, dynamic>> saveBooking(BookingModel booking) async {
    try {
      // Map BookingModel to the API's expected format
      final Map<String, dynamic> apiData = {
        'tractor_id': booking.tractorId,
        'rental_date': booking.startDate,
        'return_date': booking.endDate,
        'total_price': booking.totalPrice,
        'customer_name': booking.customerName,
        'customer_phone': booking.customerPhone,
        'customer_address': booking.customerAddress,
        'land_size': booking.landSize,
        'land_size_unit': booking.landSizeUnit,
        'notes': '',
      };

      // Send to API
      final result = await _apiService.postData('user/rentals', apiData);

      // If successful, also save locally as backup
      if (result['success'] == true) {
        await _saveLocalBooking(booking);
      }

      return result;
    } catch (e) {
      // If API fails, save locally and return error
      await saveOfflineBooking(booking);
      throw Exception('Failed to save booking to API: $e');
    }
  }

  // Update booking status
  Future<Map<String, dynamic>> updateBookingStatus(
      String id, String status) async {
    try {
      final result =
          await _apiService.putData('user/rentals/$id', {'status': status});

      // Update local copy too
      if (result['success'] == true) {
        await _updateLocalBookingStatus(id, status);
      }

      return result;
    } catch (e) {
      // Update locally if API fails
      await _updateLocalBookingStatus(id, status);
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String id) async {
    try {
      final result = await _apiService.deleteData('user/rentals/$id/cancel');

      // Update local copy too
      if (result['success'] == true) {
        await _updateLocalBookingStatus(id, 'Cancelled');
      }

      return result;
    } catch (e) {
      // Update locally if API fails
      await _updateLocalBookingStatus(id, 'Cancelled');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Save booking to local storage for offline mode
  Future<void> saveOfflineBooking(BookingModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline bookings
      List<String> offlineBookings =
          prefs.getStringList('offline_bookings') ?? [];

      // Add new booking
      offlineBookings.add(booking.toJsonString());

      // Save back to preferences
      await prefs.setStringList('offline_bookings', offlineBookings);

      // Also save to regular bookings list
      await _saveLocalBooking(booking);
    } catch (e) {
      throw Exception('Failed to save offline booking: $e');
    }
  }

  // Sync offline bookings with API
  Future<Map<String, dynamic>> syncOfflineBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get offline bookings
      List<String> offlineBookings =
          prefs.getStringList('offline_bookings') ?? [];

      if (offlineBookings.isEmpty) {
        return {'success': true, 'message': 'No offline bookings to sync'};
      }

      int successCount = 0;
      int failCount = 0;

      // Try to sync each booking
      for (String bookingJson in offlineBookings) {
        try {
          BookingModel booking = BookingModel.fromJsonString(bookingJson);

          // Skip if already synced (has a non-offline ID)
          if (!booking.id.startsWith('offline_')) {
            successCount++;
            continue;
          }

          // Try to save to API
          await saveBooking(booking);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      // Clear offline bookings that were successfully synced
      if (failCount == 0) {
        await prefs.setStringList('offline_bookings', []);
      }

      return {
        'success': true,
        'message': 'Synced $successCount bookings. Failed: $failCount'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to sync offline bookings: $e'
      };
    }
  }

  // PRIVATE METHODS

  // Get bookings from local storage
  Future<List<BookingModel>> _getLocalBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all bookings
      List<String> bookingsJson = prefs.getStringList('bookings') ?? [];

      return bookingsJson
          .map((json) => BookingModel.fromJsonString(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save a booking to local storage
  Future<void> _saveLocalBooking(BookingModel booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing bookings
      List<String> bookings = prefs.getStringList('bookings') ?? [];

      // Check if booking already exists
      int existingIndex = bookings.indexWhere((item) {
        try {
          BookingModel existing = BookingModel.fromJsonString(item);
          return existing.id == booking.id;
        } catch (e) {
          return false;
        }
      });

      // Update or add
      if (existingIndex >= 0) {
        bookings[existingIndex] = booking.toJsonString();
      } else {
        bookings.add(booking.toJsonString());
      }

      // Save back to preferences
      await prefs.setStringList('bookings', bookings);
    } catch (e) {
      throw Exception('Failed to save local booking: $e');
    }
  }

  // Update booking status in local storage
  Future<void> _updateLocalBookingStatus(String id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing bookings
      List<String> bookingsJson = prefs.getStringList('bookings') ?? [];

      // Find and update the booking
      for (int i = 0; i < bookingsJson.length; i++) {
        try {
          BookingModel booking = BookingModel.fromJsonString(bookingsJson[i]);

          if (booking.id == id) {
            // Update status
            BookingModel updatedBooking = booking.copyWith(status: status);
            bookingsJson[i] = updatedBooking.toJsonString();
            break;
          }
        } catch (e) {
          continue;
        }
      }

      // Save back to preferences
      await prefs.setStringList('bookings', bookingsJson);
    } catch (e) {
      throw Exception('Failed to update local booking status: $e');
    }
  }
}
