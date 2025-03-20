import 'package:flutter/material.dart';
import 'package:login_farmer/models/booking_model.dart';

import 'package:login_farmer/pages/bookiing_detail.dart';

class TractorCategoriesPage extends StatelessWidget {
  final List<TractorModel> tractors = [
    TractorModel(
      id: "t1",
      name: "Walking Tractor",
      imageUrl: "assets/images/walking tractor.jpg",
      brand: "",
      horsePower: 75,
      pricePerDay: .0,
      pricePerAcre: 1.31,
      description:
          "The Walking Tractor is a versatile and compact agricultural machine used primarily for plowing, tilling, and soil preparation. Designed for small-scale farming, it is ideal for rice fields, vegetable gardens, and orchards.",
    ),
    TractorModel(
      id: "t2",
      name: "Harvesting Rice",
      imageUrl: "assets/images/harvesting rice.jpg",
      brand: "Kubota",
      horsePower: 85,
      pricePerDay: .0,
      pricePerAcre: 2.0,
      description:
          "The Rice Harvester is an advanced agricultural machine designed for efficient rice harvesting. With its high-speed cutting and threshing capabilities, it significantly reduces manual labor and increases productivity.",
    ),
    TractorModel(
      id: "t3",
      name: "Plowing Machine",
      imageUrl: "assets/images/plowing machine.jpeg",
      brand: "Kubota",
      horsePower: 60,
      pricePerDay: .0,
      pricePerAcre: 1.5,
      description:
          "The Plowing Machine is an essential farming tool designed to prepare land for sowing seeds. It features a strong and durable plow that effectively breaks up soil, removes weeds, and improves aeration.",
    ),
  ];

  TractorCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tractor Categories',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF375534),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tractors.length,
        itemBuilder: (context, index) {
          final tractor = tractors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailsPage(
                      selectedTractor: tractor,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.asset(
                      tractor.imageUrl,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tractor.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF375534).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '\$${tractor.pricePerAcre.toStringAsFixed(2)}/acre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF375534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Brand: ${tractor.brand}'),
                        Text('Horsepower: ${tractor.horsePower} HP'),
                        const SizedBox(height: 8),
                        Text(
                          tractor.description,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
