import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/models/booking_model.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/booking_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final landSizeController = TextEditingController(text: '1.0');

  final _formKey = GlobalKey<FormState>();

  final Map<String, double> unitConversions = {
    'Acres': 1.0,
    'Hectares': 2.47105,
    'Square Meters': 0.000247105,
  };

  @override
  void initState() {
    super.initState();
    landSizeController.addListener(_updateLandSize);
    // Initialize the controllers with the default values
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
            const SizedBox(height: 25),
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
              //maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildLandSizeField(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildDatePicker(),
            ),
            const SizedBox(height: 20),
            _buildConfirmButton(),
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
            content: const Text('Are you sure you want to book this tractor?'),
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

  Future<void> _processBooking() async {
    try {
      // Add this at the beginning of your method
      setState(() {
        isLoading = true;
      });

      // Get the current user ID (you'll need to have this stored after login)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Calculate land size in acres
      final landSizeInAcres = landSize * unitConversions[landSizeUnit]!;

      // Create rental data to match your controller's expectations
      final rentalData = {
        'user_id': userId,
        'tractor_id':
            widget.selectedTractor.id, // Make sure this matches your model
        'farmer_name': nameController.text,
        'product_name': widget.selectedTractor.name,
        'rental_date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'status': 'pending',
        // Add any other fields your model requires
      };

      // Use ApiService to send the rental request
      final apiService = ApiService();
      final result =
          await apiService.postData('rentals', rentalData, requiresAuth: true);

      // Set loading to false when API call is complete
      setState(() {
        isLoading = false;
      });

      if (result != null && result['success'] == true) {
        // If the API request was successful

        // Create a local booking record for offline access if needed
        final newBooking = BookingModel(
          id: result['data']['id'].toString(),
          tractorName: widget.selectedTractor.name,
          tractorImage: widget.selectedTractor.imageUrl,
          startDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
          endDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
          totalPrice: _calculateTotalPrice(),
          status: 'Pending',
          customerName: nameController.text,
          customerPhone: phoneController.text,
          customerAddress: addressController.text,
          landSize: landSizeInAcres,
          landSizeUnit: 'Acres',
        );

        // Save locally if needed
        await BookingService.saveBooking(newBooking);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rental request submitted successfully!')),
        );

        // Navigate back
        Navigator.of(context).pop();
      } else {
        // If the API request failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Rental request failed: ${result?['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      // Handle error and set loading to false
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rental: ${e.toString()}')),
      );
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
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Book Tractor',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
