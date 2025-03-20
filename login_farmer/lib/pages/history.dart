import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_farmer/models/booking_model.dart';
import 'package:login_farmer/service/booking_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<BookingModel> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => isLoading = true);

    try {
      final loadedBookings = await BookingService.getBookings();
      setState(() => bookings = loadedBookings);
    } catch (error) {
      _showErrorSnackbar('Failed to load bookings. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Scheduled':
      case 'Upcoming':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(BookingModel booking) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Container(
            // Add a width constraint
            width: double.maxFinite,
            child: _buildBookingDetailsContent(booking, dateFormat),
          ),
        ),
        actions: _buildDialogActions(booking),
      ),
    );
  }

  Widget _buildBookingDetailsContent(
      BookingModel booking, DateFormat dateFormat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTractorImage(booking),
        const SizedBox(height: 16),
        _buildCustomerInfo(booking),
        const SizedBox(height: 16),
        _buildBookingDetails(booking, dateFormat),
      ],
    );
  }

  Widget _buildTractorImage(BookingModel booking) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        booking.tractorImage,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.agriculture, size: 60, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerInfo(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Name: ${booking.customerName}'),
        Text('Phone: ${booking.customerPhone}'),
        Text('Address: ${booking.customerAddress}'),
      ],
    );
  }

  Widget _buildBookingDetails(BookingModel booking, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Tractor: ${booking.tractorName}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
            'Harvest Date: ${dateFormat.format(DateTime.parse(booking.startDate))}'),
        if (booking.landSize > 0)
          Text(
              'Land Size: ${booking.landSize.toStringAsFixed(2)} ${booking.landSizeUnit}'),
        const SizedBox(height: 8),
        Text('Total Cost: \$${booking.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildStatusRow(booking),
        if (booking.status != 'Cancelled' && booking.status != 'Completed')
          _buildAdminApprovalRow(booking),
      ],
    );
  }

  Widget _buildStatusRow(BookingModel booking) {
    return Row(
      children: [
        const Text('Status: '),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(booking.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            booking.status,
            style: TextStyle(
              color: _getStatusColor(booking.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminApprovalRow(BookingModel booking) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Text('Admin approval: '),
          Text(
            booking.isAcceptedByAdmin ? 'Accepted' : 'Pending',
            style: TextStyle(
              color: booking.isAcceptedByAdmin ? Colors.green : Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDialogActions(BookingModel booking) {
    return [
      if ((booking.status == 'Scheduled' ||
              booking.status == 'Upcoming' ||
              booking.status == 'Pending') &&
          !booking.isAcceptedByAdmin)
        TextButton(
          onPressed: () => _confirmCancellation(booking),
          child:
              const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ];
  }

  void _confirmCancellation(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('Are you sure you want to cancel this booking?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog

              try {
                if (booking.status == 'Scheduled' &&
                    !booking.isAcceptedByAdmin) {
                  await BookingService.updateBookingStatus(
                      booking.id, 'Cancelled');
                  _showErrorSnackbar('Booking cancelled successfully');
                  _loadBookings(); // Refresh bookings
                } else {
                  _showErrorSnackbar('Booking cannot be cancelled.');
                }
              } catch (error) {
                _showErrorSnackbar(
                    'Failed to cancel booking. Please try again.');
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF375534),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: bookings.isEmpty
                  ? _buildEmptyBookingsView()
                  : Expanded(child: _buildBookingsList()), // Wrap in Expanded
            ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.all(8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showBookingDetails(booking),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBookingCardContent(booking),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCardContent(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                booking.tractorName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                booking.status,
                style: TextStyle(
                    color: _getStatusColor(booking.status),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            'Harvest Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.startDate))}'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${booking.totalPrice.toStringAsFixed(2)}'),
            _buildActionButton(booking),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BookingModel booking) {
    return Row(
      children: [
        if ((booking.status == 'Scheduled' ||
                booking.status == 'Upcoming' ||
                booking.status == 'Pending') &&
            !booking.isAcceptedByAdmin)
          TextButton(
            onPressed: () => _confirmCancellation(booking),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          )
        else
          TextButton(
            onPressed: () => _showBookingDetails(booking),
            child: const Text('View Details'),
          ),
      ],
    );
  }

  Widget _buildEmptyBookingsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No booking history available',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF375534)),
            child: const Text('Book a Tractor',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
