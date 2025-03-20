import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

Widget buildCarousel(double height, List<String> imagePaths, int currentIndex) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: Text(
          "Informations",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      CarouselSlider(
        items: imagePaths.map((imagePath) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imagePath,
                fit: BoxFit.cover, width: double.infinity),
          );
        }).toList(),
        options: CarouselOptions(
          height: height * 0.3,
          viewportFraction: 0.8,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          enlargeCenterPage: true,
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: AnimatedSmoothIndicator(
          activeIndex: currentIndex,
          count: imagePaths.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Colors.green,
            dotColor: Colors.grey,
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
