import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../service/config.dart';
import 'package:intl/intl.dart';

class Weather {
  final String areaName;
  final String time;
  final String date;
  final String weekday;
  final String temperature;
  final String condition;
  final String maxTemp;
  final String minTemp;
  final String wind;
  final String humidity;
  final String iconCode;
  final String sunrise;
  final String sunset;

  Weather({
    required this.areaName,
    required this.time,
    required this.date,
    required this.weekday,
    required this.temperature,
    required this.condition,
    required this.maxTemp,
    required this.minTemp,
    required this.wind,
    required this.humidity,
    required this.iconCode,
    required this.sunrise,
    required this.sunset,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    DateTime now = DateTime.now();
    String formattedWeekday = DateFormat('EEEE').format(now);
    String formattedDate = DateFormat('MM/dd/yyyy').format(now);

    // Convert sunrise and sunset from Unix timestamp to formatted time
    DateTime sunriseTime =
        DateTime.fromMillisecondsSinceEpoch(json['sys']['sunrise'] * 1000);
    DateTime sunsetTime =
        DateTime.fromMillisecondsSinceEpoch(json['sys']['sunset'] * 1000);

    return Weather(
      areaName: json['name'],
      time: DateFormat.jm().format(now),
      date: formattedDate,
      weekday: formattedWeekday,
      temperature: (json['main']['temp']).toStringAsFixed(1),
      condition: json['weather'][0]['description'],
      maxTemp: (json['main']['temp_max']).toStringAsFixed(1),
      minTemp: (json['main']['temp_min']).toStringAsFixed(1),
      wind: '${json['wind']['speed']} m/s',
      humidity: '${json['main']['humidity']}%',
      iconCode: json['weather'][0]['icon'],
      sunrise: DateFormat.jm().format(sunriseTime),
      sunset: DateFormat.jm().format(sunsetTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaName': areaName,
      'time': time,
      'date': date,
      'weekday': weekday,
      'temperature': temperature,
      'condition': condition,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'wind': wind,
      'humidity': humidity,
      'iconCode': iconCode,
      'sunrise': sunrise,
      'sunset': sunset,
    };
  }

  factory Weather.fromCachedJson(Map<String, dynamic> json) {
    return Weather(
      areaName: json['areaName'],
      time: json['time'],
      date: json['date'],
      weekday: json['weekday'],
      temperature: json['temperature'],
      condition: json['condition'],
      maxTemp: json['maxTemp'],
      minTemp: json['minTemp'],
      wind: json['wind'],
      humidity: json['humidity'],
      iconCode: json['iconCode'],
      sunrise: json['sunrise'] ??
          '6:00 AM', // Default values in case cached data doesn't have these fields
      sunset: json['sunset'] ?? '6:00 PM',
    );
  }
}

class HourlyForecast {
  final String time;
  final String temperature;
  final String condition;
  final String iconCode;
  final String wind;
  final String humidity;
  final bool isSunrise;
  final bool isSunset;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.iconCode,
    required this.wind,
    required this.humidity,
    this.isSunrise = false,
    this.isSunset = false,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    DateTime forecastTime =
        DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000);

    return HourlyForecast(
      time: DateFormat.jm().format(forecastTime),
      temperature: json['main']['temp'].toStringAsFixed(1),
      condition: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      wind: '${json['wind']['speed']} m/s',
      humidity: '${json['main']['humidity']}%',
    );
  }

  // Create a forecast for intermediate hours by interpolating between two forecasts
  factory HourlyForecast.interpolate(
      HourlyForecast prev, HourlyForecast next, String timeStr) {
    return HourlyForecast(
      time: timeStr,
      temperature: prev
          .temperature, // Simple approach: just use previous forecast values
      condition: prev.condition,
      iconCode: prev.iconCode,
      wind: prev.wind,
      humidity: prev.humidity,
    );
  }

  // Special constructor for sunrise/sunset indicators
  factory HourlyForecast.specialEvent(
      String time, bool isSunrise, bool isSunset) {
    return HourlyForecast(
      time: time,
      temperature: "",
      condition: isSunrise ? "Sunrise" : "Sunset",
      iconCode:
          isSunrise ? "01d" : "01n", // Sun icon for sunrise, moon for sunset
      wind: "",
      humidity: "",
      isSunrise: isSunrise,
      isSunset: isSunset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
      'condition': condition,
      'iconCode': iconCode,
      'wind': wind,
      'humidity': humidity,
      'isSunrise': isSunrise,
      'isSunset': isSunset,
    };
  }

  factory HourlyForecast.fromCachedJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'],
      temperature: json['temperature'],
      condition: json['condition'],
      iconCode: json['iconCode'],
      wind: json['wind'],
      humidity: json['humidity'],
      isSunrise: json['isSunrise'] ?? false,
      isSunset: json['isSunset'] ?? false,
    );
  }
}

class ForecastDay {
  final String date;
  final String weekday;
  final String maxTemp;
  final String minTemp;
  final String condition;
  final String iconCode;

  ForecastDay({
    required this.date,
    required this.weekday,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.iconCode,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000);

    return ForecastDay(
      date: DateFormat('MM/dd').format(date),
      weekday: DateFormat('EEE').format(date),
      maxTemp: json['temp']['max'].toStringAsFixed(1),
      minTemp: json['temp']['min'].toStringAsFixed(1),
      condition: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weekday': weekday,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'condition': condition,
      'iconCode': iconCode,
    };
  }

  factory ForecastDay.fromCachedJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'],
      weekday: json['weekday'],
      maxTemp: json['maxTemp'],
      minTemp: json['minTemp'],
      condition: json['condition'],
      iconCode: json['iconCode'],
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Weather? weatherData;
  List<ForecastDay> forecastData = [];
  List<HourlyForecast> hourlyForecastData = [];
  bool isLoading = true;
  String currentCity = 'Phnom Penh'; // Default city
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadCachedData().then((_) {
      fetchWeather(forceRefresh: false);
    });
  }

  Future<void> _cacheData() async {
    if (weatherData == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('currentCity', currentCity);
    await prefs.setString('lastUpdated', DateTime.now().toIso8601String());
    await prefs.setString('weatherData', jsonEncode(weatherData!.toJson()));

    List<Map<String, dynamic>> forecastJson =
        forecastData.map((f) => f.toJson()).toList();
    await prefs.setString('forecastData', jsonEncode(forecastJson));

    List<Map<String, dynamic>> hourlyJson =
        hourlyForecastData.map((h) => h.toJson()).toList();
    await prefs.setString('hourlyData', jsonEncode(hourlyJson));
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? savedCity = prefs.getString('currentCity');
      if (savedCity != null && savedCity.isNotEmpty) {
        currentCity = savedCity;
      }

      String? lastUpdatedStr = prefs.getString('lastUpdated');
      if (lastUpdatedStr != null) {
        lastUpdated = DateTime.parse(lastUpdatedStr);
      }

      String? weatherJson = prefs.getString('weatherData');
      if (weatherJson != null && weatherJson.isNotEmpty) {
        Map<String, dynamic> weatherMap = jsonDecode(weatherJson);
        weatherData = Weather.fromCachedJson(weatherMap);
      }

      String? forecastJson = prefs.getString('forecastData');
      if (forecastJson != null && forecastJson.isNotEmpty) {
        List<dynamic> forecastList = jsonDecode(forecastJson);
        forecastData = forecastList
            .map((item) => ForecastDay.fromCachedJson(item))
            .toList();
      }

      String? hourlyJson = prefs.getString('hourlyData');
      if (hourlyJson != null && hourlyJson.isNotEmpty) {
        List<dynamic> hourlyList = jsonDecode(hourlyJson);
        hourlyForecastData = hourlyList
            .map((item) => HourlyForecast.fromCachedJson(item))
            .toList();
      }

      if (weatherData != null) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  bool _isCacheFresh() {
    if (lastUpdated == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);

    return difference.inMinutes < 30;
  }

  Widget getWeatherIcon(String iconCode,
      {double size = 48, bool isSunrise = false, bool isSunset = false}) {
    // Special icons for sunrise and sunset
    if (isSunrise) {
      return Icon(
        Icons.wb_sunny,
        size: size,
        color: Colors.amber,
      );
    }

    if (isSunset) {
      return Icon(
        Icons.nightlight_round,
        size: size,
        color: Colors.deepOrange,
      );
    }

    Map<String, IconData> iconMap = {
      '01d': Icons.wb_sunny, // clear sky day
      '01n': Icons.nightlight_round, // clear sky night
      '02d': Icons.wb_cloudy, // few clouds day
      '02n': Icons.nights_stay, // few clouds night
      '03d': Icons.cloud, // scattered clouds
      '03n': Icons.cloud, // scattered clouds
      '04d': Icons.cloud_queue, // broken clouds
      '04n': Icons.cloud_queue, // broken clouds
      '09d': FontAwesomeIcons.cloudShowersHeavy, // shower rain
      '09n': FontAwesomeIcons.cloudShowersHeavy, // shower rain
      '10d': FontAwesomeIcons.cloudRain, // rain day
      '10n': FontAwesomeIcons.cloudMoonRain, // rain night
      '11d': FontAwesomeIcons.bolt, // thunderstorm
      '11n': FontAwesomeIcons.bolt, // thunderstorm
      '13d': FontAwesomeIcons.snowflake, // snow
      '13n': FontAwesomeIcons.snowflake, // snow
      '50d': FontAwesomeIcons.smog, // mist
      '50n': FontAwesomeIcons.smog, // mist
    };
    return Icon(
      iconMap[iconCode] ?? Icons.help_outline,
      size: size,
      color: _getIconColor(iconCode),
    );
  }

  Color _getIconColor(String iconCode) {
    if (iconCode.startsWith('01') || iconCode.startsWith('02')) {
      return Colors.amber; // Sunny or partly cloudy
    } else if (iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Colors.grey; // Cloudy
    } else if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return Colors.blueAccent; // Rain
    } else if (iconCode.startsWith('11')) {
      return Colors.deepPurple; // Thunderstorm
    } else if (iconCode.startsWith('13')) {
      return Colors.lightBlueAccent; // Snow
    } else {
      return Colors.grey; // Default
    }
  }

  // Generate hourly forecasts for a full day
  List<HourlyForecast> _generateHourlyForecasts(
      List<HourlyForecast> apiForecasts,
      DateTime sunriseTime,
      DateTime sunsetTime) {
    Map<int, HourlyForecast> hourMap = {};

    // Map API forecasts by hour
    for (var forecast in apiForecasts) {
      DateTime forecastTime = DateFormat.jm().parse(forecast.time);
      hourMap[forecastTime.hour] = forecast;
    }

    List<HourlyForecast> result = [];
    DateTime now = DateTime.now();

    // Start from current hour and go for 24 hours
    for (int i = 0; i < 24; i++) {
      DateTime currentHour =
          DateTime(now.year, now.month, now.day, now.hour + i);
      String timeStr = DateFormat.jm().format(currentHour);

      // Add special sunrise entry if it falls within the current hour
      if (i == 0 && sunriseTime.hour > now.hour) {
        result.add(HourlyForecast.specialEvent(
            DateFormat.jm().format(sunriseTime), true, false));
      }

      // Add special sunset entry if it falls within the current hour
      if (i == 0 && sunsetTime.hour > now.hour) {
        result.add(HourlyForecast.specialEvent(
            DateFormat.jm().format(sunsetTime), false, true));
      }

      // If we have actual data for this hour, use it
      if (hourMap.containsKey(currentHour.hour)) {
        result.add(hourMap[currentHour.hour]!);
      } else {
        // Find the closest hours we have data for
        int prevHour = currentHour.hour;
        int nextHour = currentHour.hour;

        while (prevHour >= 0 && !hourMap.containsKey(prevHour)) {
          prevHour--;
        }

        while (nextHour < 24 && !hourMap.containsKey(nextHour)) {
          nextHour++;
        }

        // Generate an interpolated forecast
        if (prevHour >= 0 && nextHour < 24) {
          result.add(HourlyForecast.interpolate(
              hourMap[prevHour]!, hourMap[nextHour]!, timeStr));
        } else if (prevHour >= 0) {
          result.add(HourlyForecast.interpolate(
              hourMap[prevHour]!, hourMap[prevHour]!, timeStr));
        } else if (nextHour < 24) {
          result.add(HourlyForecast.interpolate(
              hourMap[nextHour]!, hourMap[nextHour]!, timeStr));
        }
      }
    }

    return result;
  }

  Future<void> fetchWeather({bool forceRefresh = true}) async {
    if (!forceRefresh && _isCacheFresh()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Current weather
      final weatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$currentCity&appid=$apiKey&units=metric'));

      if (weatherResponse.statusCode == 200) {
        final weatherJson = json.decode(weatherResponse.body);

        // Get coordinates for better forecast accuracy
        double lat = weatherJson['coord']['lat'];
        double lon = weatherJson['coord']['lon'];

        // Get sunrise and sunset times
        DateTime sunriseTime = DateTime.fromMillisecondsSinceEpoch(
            weatherJson['sys']['sunrise'] * 1000);
        DateTime sunsetTime = DateTime.fromMillisecondsSinceEpoch(
            weatherJson['sys']['sunset'] * 1000);

        // Forecast data using 5-day forecast API
        final forecastResponse = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));

        if (forecastResponse.statusCode == 200) {
          final forecastJson = json.decode(forecastResponse.body);

          // Process forecast data to get daily forecasts
          Map<String, ForecastDay> dailyForecasts = {};
          List<HourlyForecast> hourlyForecasts = [];

          // Get current date to filter hourly forecasts
          final now = DateTime.now();
          final currentDate = DateFormat('yyyy-MM-dd').format(now);

          // Process the list items for both daily and hourly forecasts
          for (var item in forecastJson['list']) {
            DateTime forecastDate =
                DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
            String dateKey = DateFormat('yyyy-MM-dd').format(forecastDate);

            // Add to daily forecasts if not exists or if it's noon forecast
            if (!dailyForecasts.containsKey(dateKey) ||
                forecastDate.hour == 12 ||
                forecastDate.hour == 13) {
              // Create a simplified structure for daily forecast
              dailyForecasts[dateKey] = ForecastDay(
                date: DateFormat('MM/dd').format(forecastDate),
                weekday: DateFormat('EEE').format(forecastDate),
                maxTemp: item['main']['temp_max'].toStringAsFixed(1),
                minTemp: item['main']['temp_min'].toStringAsFixed(1),
                condition: item['weather'][0]['description'],
                iconCode: item['weather'][0]['icon'],
              );
            }

            // Add to hourly forecasts if it's for today
            if (dateKey == currentDate) {
              hourlyForecasts.add(HourlyForecast.fromJson(item));
            }
          }

          // Convert daily forecasts map to list and take first 5 days
          List<ForecastDay> forecasts = dailyForecasts.values.toList();
          if (forecasts.length > 5) {
            forecasts = forecasts.sublist(0, 5);
          }

          // Generate hourly forecasts for the current day with sunrise and sunset
          List<HourlyForecast> hourlyDetailedForecasts =
              _generateHourlyForecastsForCurrentDay(
                  hourlyForecasts, sunriseTime, sunsetTime);

          setState(() {
            weatherData = Weather.fromJson(weatherJson);
            forecastData = forecasts;
            hourlyForecastData = hourlyDetailedForecasts;
            isLoading = false;
            lastUpdated = DateTime.now();
          });

          // Cache the data
          _cacheData();
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('City not found. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().substring(0, 100)}')),
      );
    }
  }

  List<HourlyForecast> _generateHourlyForecastsForCurrentDay(
      List<HourlyForecast> apiForecasts,
      DateTime sunriseTime,
      DateTime sunsetTime) {
    Map<int, HourlyForecast> hourMap = {};

    // Map API forecasts by hour
    for (var forecast in apiForecasts) {
      DateTime forecastTime = DateFormat.jm().parse(forecast.time);
      hourMap[forecastTime.hour] = forecast;
    }

    List<HourlyForecast> result = [];
    DateTime now = DateTime.now();

    // Start from current hour and go for 24 hours
    for (int i = 0; i < 24; i++) {
      DateTime currentHour =
          DateTime(now.year, now.month, now.day, now.hour + i);
      String timeStr = DateFormat.jm().format(currentHour);

      // Add special sunrise entry if it falls within the current hour
      if (currentHour.hour == sunriseTime.hour) {
        result.add(HourlyForecast.specialEvent(
            DateFormat.jm().format(sunriseTime), true, false));
      }

      // Add special sunset entry if it falls within the current hour
      if (currentHour.hour == sunsetTime.hour) {
        result.add(HourlyForecast.specialEvent(
            DateFormat.jm().format(sunsetTime), false, true));
      }

      // If we have actual data for this hour, use it
      if (hourMap.containsKey(currentHour.hour)) {
        result.add(hourMap[currentHour.hour]!);
      } else {
        // Find the closest hours we have data for
        int prevHour = currentHour.hour;
        int nextHour = currentHour.hour;

        while (prevHour >= 0 && !hourMap.containsKey(prevHour)) {
          prevHour--;
        }

        while (nextHour < 24 && !hourMap.containsKey(nextHour)) {
          nextHour++;
        }

        // Generate an interpolated forecast
        if (prevHour >= 0 && nextHour < 24) {
          result.add(HourlyForecast.interpolate(
              hourMap[prevHour]!, hourMap[nextHour]!, timeStr));
        } else if (prevHour >= 0) {
          result.add(HourlyForecast.interpolate(
              hourMap[prevHour]!, hourMap[prevHour]!, timeStr));
        } else if (nextHour < 24) {
          result.add(HourlyForecast.interpolate(
              hourMap[nextHour]!, hourMap[nextHour]!, timeStr));
        }
      }
    }

    return result;
  }

  String getLastUpdatedText() {
    if (lastUpdated == null) return '';

    return 'Last updated: ${DateFormat.jm().format(lastUpdated!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF375534),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => fetchWeather(forceRefresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Last updated text
          if (lastUpdated != null && !isLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  getLastUpdatedText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => fetchWeather(forceRefresh: true),
                    child: weatherData == null
                        ? Center(child: Text('No weather data available'))
                        : SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Current weather display
                                  Text(weatherData!.areaName,
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text(weatherData!.time,
                                      style: TextStyle(fontSize: 24)),
                                  Text(
                                      '${weatherData!.weekday}, ${weatherData!.date}',
                                      style: TextStyle(fontSize: 16)),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      getWeatherIcon(weatherData!.iconCode,
                                          size: 64),
                                      SizedBox(width: 16),
                                      Text(weatherData!.condition,
                                          style: TextStyle(fontSize: 20)),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text('${weatherData!.temperature} °C',
                                      style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold)),
                                  Container(
                                    margin: EdgeInsets.only(top: 20),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF375534),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.wb_sunny,
                                                color: Colors.amber),
                                            SizedBox(width: 8),
                                            Text(
                                                'Sunrise: ${weatherData!.sunrise}',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            SizedBox(width: 16),
                                            Icon(Icons.nightlight_round,
                                                color: Colors.amber),
                                            SizedBox(width: 8),
                                            Text(
                                                'Sunset: ${weatherData!.sunset}',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('Max: ${weatherData!.maxTemp} °C',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text('Min: ${weatherData!.minTemp} °C',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text('Wind: ${weatherData!.wind}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        Text(
                                            'Humidity: ${weatherData!.humidity}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),

                                  // Hourly forecast
                                  SizedBox(height: 32),
                                  Text('Hourly Forecast',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 16),
                                  if (hourlyForecastData.isNotEmpty)
                                    Container(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: hourlyForecastData.length,
                                        itemBuilder: (context, index) {
                                          final forecast =
                                              hourlyForecastData[index];

                                          // Special styling for sunrise/sunset
                                          Color cardColor = Color(0xFFF5F5F5);
                                          if (forecast.isSunrise) {
                                            cardColor =
                                                Colors.amber.withOpacity(0.3);
                                          } else if (forecast.isSunset) {
                                            cardColor = Colors.deepOrange
                                                .withOpacity(0.3);
                                          }

                                          return Container(
                                            width: 120,
                                            margin: EdgeInsets.only(right: 12),
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(forecast.time,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                SizedBox(height: 12),
                                                getWeatherIcon(
                                                    forecast.iconCode,
                                                    isSunrise:
                                                        forecast.isSunrise,
                                                    isSunset:
                                                        forecast.isSunset),
                                                SizedBox(height: 8),
                                                if (forecast.isSunrise ||
                                                    forecast.isSunset)
                                                  Text(
                                                    forecast.isSunrise
                                                        ? 'Sunrise'
                                                        : 'Sunset',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: forecast
                                                                .isSunrise
                                                            ? Colors.amber[800]
                                                            : Colors
                                                                .deepOrange),
                                                  )
                                                else
                                                  Text(
                                                    '${forecast.temperature}°C',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                SizedBox(height: 5),
                                                if (!forecast.isSunrise &&
                                                    !forecast.isSunset)
                                                  Text(forecast.condition,
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                if (!forecast.isSunrise &&
                                                    !forecast.isSunset)
                                                  SizedBox(height: 5),
                                                if (!forecast.isSunrise &&
                                                    !forecast.isSunset)
                                                  Text(forecast.wind,
                                                      style: TextStyle(
                                                          fontSize: 11),
                                                      textAlign:
                                                          TextAlign.center),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  // 5-day forecast
                                  SizedBox(height: 32),
                                  Text('5-Day Forecast',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 16),
                                  if (forecastData.isNotEmpty)
                                    Container(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: forecastData.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            width: 120,
                                            margin: EdgeInsets.only(right: 12),
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF5F5F5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    forecastData[index].weekday,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(forecastData[index].date),
                                                SizedBox(height: 8),
                                                getWeatherIcon(
                                                    forecastData[index]
                                                        .iconCode),
                                                SizedBox(height: 8),
                                                Text(
                                                    forecastData[index]
                                                        .condition,
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                        '${forecastData[index].maxTemp}°',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Text(
                                                        ' / ${forecastData[index].minTemp}°'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
