import 'dart:async'; // For TimeoutException
import 'dart:io'; // For SocketException

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_farmer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/models/booking_model.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/booking_service.dart';

class BookingDetailsPage extends StatefulWidget {
  final TractorModel selectedTractor;

  const BookingDetailsPage({
    Key? key,
    required this.selectedTractor,
  }) : super(key: key);

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  DateTime? selectedDate;
  String landSizeUnit = 'Acres';
  double landSize = 1.0;
  bool isLoading = false;
  bool isOfflineMode = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final landSizeController = TextEditingController(text: '1.0');

  final _formKey = GlobalKey<FormState>();

  // Service instances
  final BookingService _bookingService = BookingService();
  final _apiService = getIt<ApiService>(); // ✅ Correct

  final Map<String, double> unitConversions = {
    'Acres': 1.0,
    'Hectares': 2.47105,
    'Square Meters': 0.000247105,
  };

  @override
  void initState() {
    super.initState();
    landSizeController.addListener(_updateLandSize);
    _loadUserData();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      // Check if we can connect to the API
      final result = await _apiService
          .getData('status', requiresAuth: false)
          .timeout(const Duration(seconds: 5));

      setState(() {
        isOfflineMode = !(result['success'] == true);
      });
    } catch (e) {
      // If we can't connect, set offline mode
      setState(() {
        isOfflineMode = true;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      phoneController.text = prefs.getString('user_phone') ?? '';
      addressController.text = prefs.getString('user_address') ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    landSizeController.dispose();
    super.dispose();
  }

  void _updateLandSize() {
    setState(() {
      landSize = double.tryParse(landSizeController.text) ?? 0.0;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.selectedTractor.name}',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Offline mode warning
            if (isOfflineMode)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are in offline mode. Your booking will be saved locally and synced when you reconnect.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Tractor Preview Card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      widget.selectedTractor.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.agriculture,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.selectedTractor.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Brand: ${widget.selectedTractor.brand}',
                            style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text('${widget.selectedTractor.horsePower} HP',
                            style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Text(
                            'Price per Acre: \$${widget.selectedTractor.pricePerAcre.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.green[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User Information Fields
            _buildTextField(
              controller: nameController,
              label: 'Name',
              bottomPadding: 16,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              bottomPadding: 16,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: addressController,
              label: 'Address',
              bottomPadding: 16,
            ),
            const SizedBox(height: 16),
            _buildLandSizeField(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildDatePicker(),
            ),

            // Price information
            _buildPriceInfo(),

            const SizedBox(height: 20),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo() {
    if (selectedDate == null) return const SizedBox.shrink();

    final totalPrice = _calculateTotalPrice();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Land Size: ${landSize.toStringAsFixed(2)} $landSizeUnit'),
                Text(
                    'Acres: ${(landSize * unitConversions[landSizeUnit]!).toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per Acre:'),
                Text(
                    '\$${widget.selectedTractor.pricePerAcre.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Price:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    double bottomPadding = 0,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please enter your $label' : null,
    );
  }

  TextFormField _buildLandSizeField() {
    return TextFormField(
      controller: landSizeController,
      decoration: InputDecoration(
        labelText: 'Land Size ($landSizeUnit)',
        border: const OutlineInputBorder(),
        suffixIcon: DropdownButton<String>(
          value: landSizeUnit,
          items: unitConversions.keys.map((String unit) {
            return DropdownMenuItem<String>(value: unit, child: Text(unit));
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                landSizeUnit = newValue;
                landSizeController.text = landSize.toString();
              });
            }
          },
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter land size';
        }
        final landSizeValue = double.tryParse(value);
        if (landSizeValue == null || landSizeValue <= 0) {
          return 'Please enter a valid land size';
        }
        return null;
      },
    );
  }

  Card _buildDatePicker() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        title: const Text('Harvest Date'),
        subtitle: Text(selectedDate == null
            ? 'Select a date'
            : DateFormat('MMM dd, yyyy').format(selectedDate!)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => _selectDate(context),
      ),
    );
  }

  void _showBookingConfirmationDialog() {
    if (_formKey.currentState!.validate()) {
      // Check if date is selected
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a harvest date')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to book this tractor?'),
                const SizedBox(height: 8),
                Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
                Text('Land Size: ${landSize.toStringAsFixed(2)} $landSizeUnit'),
                Text(
                    'Total Price: \$${_calculateTotalPrice().toStringAsFixed(2)}'),
                if (isOfflineMode)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Note: You are in offline mode. Your booking will be synced when you reconnect.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _processBooking();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // ... [Previous build methods remain the same until _processBooking] ...
// Inside _processBooking() in BookingDetailsPage
  Future<void> _processBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a harvest date')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('User not logged in');

      final landSizeInAcres = landSize * unitConversions[landSizeUnit]!;
      final totalPrice = _calculateTotalPrice();

      // Create a BookingModel for the API
      final BookingModel newBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        tractorId: widget.selectedTractor.id,
        tractorName: widget.selectedTractor.name,
        tractorImage: widget.selectedTractor.imageUrl,
        startDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        endDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        totalPrice: totalPrice,
        status: 'Pending',
        customerName: nameController.text,
        customerPhone: phoneController.text,
        customerAddress: addressController.text,
        landSize: landSizeInAcres,
        landSizeUnit: 'Acres',
        isAcceptedByAdmin: false,
      );

      // Try to submit booking to API if we're online
      if (!isOfflineMode) {
        final result = await _bookingService.saveBooking(newBooking);

        if (result['success'] == true) {
          // Update UI
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking successful!')),
          );
        } else {
          throw Exception(result['message'] ?? 'Booking failed');
        }
      } else {
        // We're offline, save booking locally with pending sync status
        await _bookingService.saveOfflineBooking(newBooking);

        // Show success message with offline indicator
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Booking saved locally. It will be synced when you reconnect.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

// Fix for _handleOfflineBooking()
  Future<void> _handleOfflineBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('User not logged in');

      final landSizeInAcres = landSize * unitConversions[landSizeUnit]!;
      final totalPrice = _calculateTotalPrice();

      // Create a model for offline storage
      final BookingModel offlineBooking = BookingModel(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        tractorId: widget.selectedTractor.id,
        tractorName: widget.selectedTractor.name,
        tractorImage: widget.selectedTractor.imageUrl,
        startDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        endDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        totalPrice: totalPrice,
        status: 'Pending',
        customerName: nameController.text,
        customerPhone: phoneController.text,
        customerAddress: addressController.text,
        landSize: landSizeInAcres,
        landSizeUnit: 'Acres',
        isAcceptedByAdmin: false,
      );

      // Use the instance method instead of a static method
      await _bookingService.saveOfflineBooking(offlineBooking);

      // Navigate back
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Error saving offline booking: $e');
    }
  }

  double _calculateTotalPrice() {
    final tractor = widget.selectedTractor;
    double sizeInAcres = landSize * unitConversions[landSizeUnit]!;
    return tractor.pricePerAcre * sizeInAcres;
  }

  ElevatedButton _buildConfirmButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _showBookingConfirmationDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Book Tractor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
  // ... [Rest of the methods remain the same] ...
}
