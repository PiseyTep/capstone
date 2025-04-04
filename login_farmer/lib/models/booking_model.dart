import 'dart:convert';

class BookingModel {
  final String id;
  final String? tractorId; // Added for API integration
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
  final bool isAcceptedByAdmin;

  BookingModel({
    required this.id,
    this.tractorId,
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
    this.isAcceptedByAdmin = false,
  });

  // Create a copy with modified fields
  BookingModel copyWith({
    String? id,
    String? tractorId,
    String? tractorName,
    String? tractorImage,
    String? startDate,
    String? endDate,
    double? totalPrice,
    String? status,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? landSize,
    String? landSizeUnit,
    bool? isAcceptedByAdmin,
  }) {
    return BookingModel(
      id: id ?? this.id,
      tractorId: tractorId ?? this.tractorId,
      tractorName: tractorName ?? this.tractorName,
      tractorImage: tractorImage ?? this.tractorImage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      landSize: landSize ?? this.landSize,
      landSizeUnit: landSizeUnit ?? this.landSizeUnit,
      isAcceptedByAdmin: isAcceptedByAdmin ?? this.isAcceptedByAdmin,
    );
  }

  // For local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tractorId': tractorId,
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

  // For API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tractor_id': tractorId,
      'tractor_name': tractorName,
      'tractor_image': tractorImage,
      'rental_date': startDate,
      'end_date': endDate,
      'total_price': totalPrice,
      'status': status,
      'farmer_name': customerName,
      'phone': customerPhone,
      'address': customerAddress,
      'land_size': landSize,
      'land_size_unit': landSizeUnit,
      'is_accepted_by_admin': isAcceptedByAdmin,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      tractorId: map['tractorId'],
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

  // From API response
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'].toString(),
      tractorId: json['tractor_id']?.toString(),
      tractorName:
          json['tractor_name'] ?? json['product_name'] ?? 'Unknown Tractor',
      tractorImage:
          json['tractor_image'] ?? 'assets/images/tractor_placeholder.png',
      startDate: json['rental_date'] ?? '',
      endDate: json['end_date'] ?? json['rental_date'] ?? '',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'Pending',
      customerName: json['farmer_name'] ?? '',
      customerPhone: json['phone'] ?? '',
      customerAddress: json['address'] ?? '',
      landSize: double.tryParse(json['land_size'].toString()) ?? 0.0,
      landSizeUnit: json['land_size_unit'] ?? 'Acres',
      isAcceptedByAdmin: json['is_accepted_by_admin'] ?? false,
    );
  }

  // For SharedPreferences storage
  String toJsonString() => jsonEncode(toMap());

  factory BookingModel.fromJsonString(String jsonString) {
    return BookingModel.fromMap(jsonDecode(jsonString));
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
  final bool isAvailable;
  final String category;

  TractorModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.brand,
    required this.horsePower,
    required this.pricePerDay,
    required this.pricePerAcre,
    required this.description,
    this.isAvailable = true,
    this.category = 'Standard',
  });

  // Create a copy with modified fields
  TractorModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? brand,
    int? horsePower,
    double? pricePerDay,
    double? pricePerAcre,
    String? description,
    bool? isAvailable,
    String? category,
  }) {
    return TractorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      horsePower: horsePower ?? this.horsePower,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerAcre: pricePerAcre ?? this.pricePerAcre,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
    );
  }

  // For local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'brand': brand,
      'horsePower': horsePower,
      'pricePerDay': pricePerDay,
      'pricePerAcre': pricePerAcre,
      'description': description,
      'isAvailable': isAvailable,
      'category': category,
    };
  }

  // For API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'brand': brand,
      'horse_power': horsePower,
      'price_per_day': pricePerDay,
      'price_per_acre': pricePerAcre,
      'description': description,
      'is_available': isAvailable,
      'category': category,
    };
  }

  factory TractorModel.fromMap(Map<String, dynamic> map) {
    return TractorModel(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      brand: map['brand'],
      horsePower: map['horsePower'],
      pricePerDay: (map['pricePerDay'] is int)
          ? (map['pricePerDay'] as int).toDouble()
          : map['pricePerDay'],
      pricePerAcre: (map['pricePerAcre'] is int)
          ? (map['pricePerAcre'] as int).toDouble()
          : map['pricePerAcre'],
      description: map['description'],
      isAvailable: map['isAvailable'] ?? true,
      category: map['category'] ?? 'Standard',
    );
  }

  // From API response
  factory TractorModel.fromJson(Map<String, dynamic> json) {
    return TractorModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Tractor',
      imageUrl: json['image_url'] ?? 'assets/images/tractor_placeholder.png',
      brand: json['brand'] ?? 'Unknown Brand',
      horsePower: json['horse_power'] ?? json['horsepower'] ?? 0,
      pricePerDay: double.tryParse(json['price_per_day'].toString()) ?? 0.0,
      pricePerAcre: double.tryParse(json['price_per_acre'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      isAvailable: json['is_available'] ?? true,
      category: json['category'] ?? 'Standard',
    );
  }

  // For SharedPreferences storage
  String toJsonString() => jsonEncode(toMap());

  factory TractorModel.fromJsonString(String jsonString) {
    return TractorModel.fromMap(jsonDecode(jsonString));
  }
}
