class BookingModel {
  final String id;
  final String tractorName;
  final String tractorImage;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final String status;

  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double landSize;
  final String landSizeUnit;
  final bool isAcceptedByAdmin; // Added this field

  BookingModel({
    required this.id,
    required this.tractorName,
    required this.tractorImage,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.landSize = 0.0,
    this.landSizeUnit = 'Acres',
    this.isAcceptedByAdmin = false, // Default to false (not accepted)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tractorName': tractorName,
      'tractorImage': tractorImage,
      'startDate': startDate,
      'endDate': endDate,
      'totalPrice': totalPrice,
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'landSize': landSize,
      'landSizeUnit': landSizeUnit,
      'isAcceptedByAdmin': isAcceptedByAdmin,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      tractorName: map['tractorName'],
      tractorImage: map['tractorImage'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      totalPrice: (map['totalPrice'] is int)
          ? (map['totalPrice'] as int).toDouble()
          : map['totalPrice'].toDouble(),
      status: map['status'],
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      landSize: (map['landSize'] is int)
          ? (map['landSize'] as int).toDouble()
          : map['landSize']?.toDouble() ?? 0.0,
      landSizeUnit: map['landSizeUnit'] ?? 'Acres',
      isAcceptedByAdmin: map['isAcceptedByAdmin'] ?? false,
    );
  }
}

class TractorModel {
  final String id;
  final String name;
  final String imageUrl;
  final String brand;
  final int horsePower;
  final double pricePerDay;
  final double pricePerAcre;
  final String description;

  TractorModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.brand,
    required this.horsePower,
    required this.pricePerDay,
    required this.pricePerAcre,
    required this.description,
  });
}
