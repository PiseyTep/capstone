import 'package:login_farmer/models/booking_model.dart';

class BookingService {
  // Simulated data storage for bookings
  static List<Map<String, dynamic>> _bookingsData = [];

  // Constants for simulated delays
  static const Duration _fetchDelay = Duration(seconds: 1);
  static const Duration _saveUpdateDelay = Duration(milliseconds: 500);

  /// Fetches all bookings for the current user.
  static Future<List<BookingModel>> getBookings() async {
    try {
      // Simulate fetching data from a backend or database
      final fetchedBookings = await _simulateDataFetch();

      // Convert the fetched data to BookingModel objects
      return fetchedBookings.map((data) {
        return BookingModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  /// Saves a new booking to the data source.
  static Future<void> saveBooking(BookingModel booking) async {
    try {
      // Simulate saving data to a backend or database
      await _simulateDataSave(booking.toMap());
      print('Booking saved: ${booking.toMap()}');
    } catch (e) {
      print('Error saving booking: $e');
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  /// Updates the status of a specific booking.
  static Future<void> updateBookingStatus(
      String bookingId, String newStatus) async {
    try {
      // Simulate updating data in a backend or database
      await _simulateDataUpdate(bookingId, {'status': newStatus});
      print('Booking $bookingId status updated to $newStatus');
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  /// Cancels a booking if it has not been accepted by the admin.
  static Future<void> cancelBooking(String bookingId) async {
    try {
      // Fetch all bookings
      final bookings = await getBookings();

      // Find the booking to cancel
      final booking = bookings.firstWhere(
        (booking) => booking.id == bookingId,
        orElse: () => throw Exception('Booking not found'),
      );

      // Check if the booking can be canceled
      if (!booking.isAcceptedByAdmin) {
        // Simulate updating the booking status to 'Cancelled'
        await _simulateDataUpdate(bookingId, {'status': 'Cancelled'});
        print('Booking $bookingId has been canceled.');
      } else {
        throw Exception(
            'Booking cannot be canceled (already accepted by admin).');
      }
    } catch (e) {
      print('Error canceling booking: $e');
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  /// Marks a booking as accepted by the admin.
  static Future<void> acceptBooking(String bookingId) async {
    try {
      // Simulate updating the booking in the backend
      await _simulateDataUpdate(bookingId, {
        'status': 'Accepted',
        'isAcceptedByAdmin': true,
      });
      print('Booking $bookingId has been accepted by the admin.');
    } catch (e) {
      print('Error accepting booking: $e');
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  /// Simulates fetching data from a backend or database.
  static Future<List<Map<String, dynamic>>> _simulateDataFetch() async {
    // Simulate network delay
    await Future.delayed(_fetchDelay);
    // Return the current list of bookings
    return _bookingsData;
  }

  /// Simulates saving data to a backend or database.
  static Future<void> _simulateDataSave(
      Map<String, dynamic> bookingData) async {
    // Simulate network delay
    await Future.delayed(_saveUpdateDelay);
    // Add the new booking to the list
    _bookingsData.add(bookingData);
    print('Booking saved: $bookingData');
  }

  /// Simulates updating data in a backend or database.
  static Future<void> _simulateDataUpdate(
      String id, Map<String, dynamic> data) async {
    // Simulate network delay
    await Future.delayed(_saveUpdateDelay);
    // Find the booking with matching id
    final index = _bookingsData.indexWhere((booking) => booking['id'] == id);
    if (index != -1) {
      // Update the booking with the new data
      data.forEach((key, value) {
        _bookingsData[index][key] = value;
      });
      print('Booking $id updated with: $data');
    } else {
      print('Booking $id not found for update.');
    }
  }
}
