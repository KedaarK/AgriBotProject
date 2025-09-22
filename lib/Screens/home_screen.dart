// // home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:agribot/Providers/weather_provider.dart';
// import 'package:agribot/Providers/weather_provider.dart';
// import 'package:agribot/screens/recommendation_page.dart';
// import 'package:agribot/Services/performance_service.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String errorMessage = "";
//   final ScrollController _scrollController = ScrollController();
//   int _itemsToShow = 2;
//   final int _increment = 2;
//   bool _isLoadingMore = false;

//   final List<Map<String, dynamic>> services = [
//     {
//       'title': 'Crop Recommendation',
//       'subtitle': 'Recommendation about the type of crops based on conditions.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': () => RecommendationPage(),
//     },
//     {
//       'title': 'Fertilizer Prediction',
//       'subtitle': 'Find the best fertilizer for your crop based on soil.',
//       'image': 'assets/images/fertilizer.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Irrigation Advice',
//       'subtitle': 'Get water management suggestions.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Soil Health Card',
//       'subtitle': 'Monitor and improve soil fertility.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Market Price Trends',
//       'subtitle': 'Check crop prices in your region.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Pest Detection',
//       'subtitle': 'Detect pests using camera and get action suggestions.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Crop Yield Estimation',
//       'subtitle': 'Estimate potential yield from current crop.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'AgriBot Estimation',
//       'subtitle': 'Estimate potential yield from current crop.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'AgriBot Estimation',
//       'subtitle': 'Estimate potential yield from current crop.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'AgriBot Estimation',
//       'subtitle': 'Estimate potential yield from current crop.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Fetch weather data wrapped in a performance trace.
//     fetchWeather();
//     _scrollController.addListener(_scrollListener);
//   }

//   Future<void> fetchWeather() async {
//     try {
//       // Using our performance service to trace the weather fetch operation.
//       await PerformanceService().trackOperation(
//         traceName: 'fetch_weather',
//         operation: () =>
//             Provider.of<WeatherProvider>(context, listen: false).fetchWeather(),
//       );
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//       });
//     }
//   }

//   void _scrollListener() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent &&
//         !_isLoadingMore &&
//         _itemsToShow < services.length) {
//       setState(() {
//         _isLoadingMore = true;
//       });
//       // Wrap the lazy load operation in a performance trace.
//       PerformanceService().trackOperation(
//         traceName: 'lazy_load_operation',
//         operation: () async {
//           await Future.delayed(Duration(seconds: 2));
//           setState(() {
//             _itemsToShow = (_itemsToShow + _increment) > services.length
//                 ? services.length
//                 : _itemsToShow + _increment;
//             _isLoadingMore = false;
//           });
//         },
//       );
//     }
//   }

//   String capitalizeEachWord(String text) {
//     if (text.isEmpty) return text;
//     return text
//         .split(' ')
//         .map((word) => word[0].toUpperCase() + word.substring(1))
//         .join(' ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final weatherProvider = Provider.of<WeatherProvider>(context);
//     final weather = weatherProvider.weather;
//     final size = MediaQuery.of(context).size;

//     // Calculate itemCount: 1 for the weather card, 1 for the header, then service cards,
//     // plus an extra item for the loader if needed.
//     int itemCount = _itemsToShow + 2 + (_isLoadingMore ? 1 : 0);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Home"),
//       ),
//       backgroundColor: Colors.yellow.shade50,
//       body: ListView.builder(
//         controller: _scrollController,
//         padding: EdgeInsets.all(size.width * 0.04),
//         itemCount: itemCount,
//         itemBuilder: (context, index) {
//           if (index == 0) {
//             // Weather card at the top.
//             return _buildWeatherCard(weatherProvider, weather, size);
//           } else if (index == 1) {
//             // Header for the services section.
//             return Padding(
//               padding: EdgeInsets.only(bottom: size.height * 0.015),
//               child: Text(
//                 'Products & Services',
//                 style: TextStyle(
//                   fontSize: size.width * 0.05,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             );
//           } else if (index == _itemsToShow + 2 && _isLoadingMore) {
//             // Loader widget for lazy loading.
//             return Padding(
//               padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
//               child: Center(child: CircularProgressIndicator()),
//             );
//           } else {
//             // Service cards.
//             final service = services[index - 2];
//             return ServiceCard(service: service);
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildWeatherCard(
//       WeatherProvider weatherProvider, weather, Size size) {
//     if (errorMessage.isNotEmpty) {
//       return Container(
//         padding: EdgeInsets.all(size.width * 0.03),
//         color: Colors.red[100],
//         child: Text(errorMessage, style: TextStyle(color: Colors.red)),
//       );
//     }

//     if (weatherProvider.isLoading) {
//       return Center(child: CircularProgressIndicator());
//     }

//     if (weather == null) {
//       return Center(child: Text("Error loading weather data"));
//     }

//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(size.width * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.green[100],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Weather",
//             style: TextStyle(
//               fontSize: size.width * 0.05,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: size.height * 0.01),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("NOW"),
//                   Text(capitalizeEachWord(weather.description)),
//                 ],
//               ),
//               Text(
//                 "${weather.temperature}°C",
//                 style: TextStyle(
//                   fontSize: size.width * 0.08,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Icon(Icons.cloud, color: Colors.blue),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// // A separate modular widget for building service cards.
// class ServiceCard extends StatelessWidget {
//   final Map<String, dynamic> service;
//   const ServiceCard({Key? key, required this.service}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return GestureDetector(
//       onTap: service['onTap'] != null
//           ? () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => service['onTap']()),
//               );
//             }
//           : null,
//       child: Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         elevation: 4,
//         margin: EdgeInsets.only(bottom: 16),
//         child: Column(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//               child: AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: Image.asset(
//                   service['image'],
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             ListTile(
//               title: Text(
//                 service['title'],
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(service['subtitle']),
//               trailing: Icon(Icons.arrow_forward_ios),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:agribot/Providers/weather_provider.dart';
// import 'package:agribot/screens/recommendation_page.dart';
// import 'package:agribot/Services/performance_service.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:agribot/Widgets/service_card.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String errorMessage = "";
//   // We still use a ScrollController if needed, but no lazy load logic is applied.
//   final ScrollController _scrollController = ScrollController();

//   // Load all items at once (set to full list length).
//   final int _itemsToShow = 10;

//   final List<Map<String, dynamic>> services = [
//     {
//       'title': 'Crop Recommendation',
//       'subtitle': 'Recommendation about the type of crops based on conditions.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': () => RecommendationPage(),
//     },
//     {
//       'title': 'Fertilizer Prediction',
//       'subtitle': 'Find the best fertilizer for your crop based on soil.',
//       'image': 'assets/images/fertilizer.jpg',
//       'onTap': null,
//     },
//     {
//       'title': 'Irrigation Advice',
//       'subtitle': 'Get water management suggestions.',
//       'image': 'assets/images/crop_selection.jpg',
//       'onTap': null,
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Fetch weather data once using Firebase Performance trace.
//     fetchWeather();
//   }

//   Future<void> fetchWeather() async {
//     try {
//       // Trace the weather fetching operation.
//       await PerformanceService().trackOperation(
//         traceName: 'fetch_weather_no_lazy',
//         operation: () =>
//             Provider.of<WeatherProvider>(context, listen: false).fetchWeather(),
//       );
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//       });
//     }
//   }

//   // Helper function: Capitalize each word.
//   String capitalizeEachWord(String text) {
//     if (text.isEmpty) return text;
//     return text
//         .split(' ')
//         .map((word) => word[0].toUpperCase() + word.substring(1))
//         .join(' ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final weatherProvider = Provider.of<WeatherProvider>(context);
//     final weather = weatherProvider.weather;
//     final size = MediaQuery.of(context).size;

//     // Since we're not lazy loading, itemCount is weather card + header + all service cards.
//     int itemCount = _itemsToShow + 2;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Home"),
//       ),
//       backgroundColor: Colors.yellow.shade50,
//       body: ListView.builder(
//         controller: _scrollController,
//         padding: EdgeInsets.all(size.width * 0.04),
//         itemCount: itemCount,
//         itemBuilder: (context, index) {
//           if (index == 0) {
//             // Weather card at the top.
//             return _buildWeatherCard(weatherProvider, weather, size);
//           } else if (index == 1) {
//             // Header for the services section.
//             return Padding(
//               padding: EdgeInsets.only(bottom: size.height * 0.015),
//               child: Text(
//                 'Products & Services',
//                 style: TextStyle(
//                   fontSize: size.width * 0.05,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             );
//           } else {
//             // Build all service cards.
//             final service = services[index - 2];
//             return ServiceCard(service: service);
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildWeatherCard(
//       WeatherProvider weatherProvider, dynamic weather, Size size) {
//     if (errorMessage.isNotEmpty) {
//       return Container(
//         padding: EdgeInsets.all(size.width * 0.03),
//         color: Colors.red[100],
//         child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
//       );
//     }

//     if (weatherProvider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (weather == null) {
//       return const Center(child: Text("Error loading weather data"));
//     }

//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(size.width * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.green[100],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Weather",
//             style: TextStyle(
//               fontSize: size.width * 0.05,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: size.height * 0.01),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("NOW"),
//                   Text(capitalizeEachWord(weather.description)),
//                 ],
//               ),
//               Text(
//                 "${weather.temperature}°C",
//                 style: TextStyle(
//                   fontSize: size.width * 0.08,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Icon(Icons.cloud, color: Colors.blue),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
// }
// ################################################################3

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agribot/Providers/weather_provider.dart';
import 'package:agribot/screens/recommendation_page.dart';
import 'package:agribot/Services/performance_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:agribot/Widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage; // <-- add this
  const HomeScreen({required this.onChangeLanguage, super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String errorMessage = "";
  final ScrollController _scrollController = ScrollController();
  final int _itemsToShow = 10;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      await PerformanceService().trackOperation(
        traceName: 'fetch_weather_no_lazy',
        operation: () =>
            Provider.of<WeatherProvider>(context, listen: false).fetchWeather(),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  String capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  widget.onChangeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिन्दी'),
                onTap: () {
                  widget.onChangeLanguage(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('मराठी'),
                onTap: () {
                  widget.onChangeLanguage(const Locale('mr'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weather;
    final size = MediaQuery.of(context).size;

    // Build localized services list (UI unchanged; just strings come from ARB)
    final List<Map<String, dynamic>> services = [
      {
        'title': l10n.serviceCropRecommendationTitle,
        'subtitle': l10n.serviceCropRecommendationSubtitle,
        'image': 'assets/images/crop_selection.jpg',
        'onTap': () => RecommendationPage(),
      },
      {
        'title': l10n.serviceFertilizerPredictionTitle,
        'subtitle': l10n.serviceFertilizerPredictionSubtitle,
        'image': 'assets/images/fertilizer.jpg',
        'onTap': null,
      },
      {
        'title': l10n.serviceIrrigationAdviceTitle,
        'subtitle': l10n.serviceIrrigationAdviceSubtitle,
        'image': 'assets/images/crop_selection.jpg',
        'onTap': null,
      },
    ];

    final int itemCount = _itemsToShow + 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.selectLanguage,
            onPressed: _showLanguageDialog,
          ),
        ],
      ),
      backgroundColor: Colors.yellow.shade50,
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(size.width * 0.04),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildWeatherCard(weatherProvider, weather, size);
          } else if (index == 1) {
            return Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.015),
              child: Text(
                l10n.productsAndServices,
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          } else {
            final service = services[index - 2];
            return ServiceCard(service: service);
          }
        },
      ),
    );
  }

  Widget _buildWeatherCard(
      WeatherProvider weatherProvider, dynamic weather, Size size) {
    final l10n = AppLocalizations.of(context)!;

    if (errorMessage.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(size.width * 0.03),
        color: Colors.red[100],
        child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    if (weatherProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weather == null) {
      return Center(child: Text(l10n.errorLoadingWeather));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weatherLabel,
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nowLabel),
                  Text(capitalizeEachWord(weather.description)),
                ],
              ),
              Text(
                "${weather.temperature}°C",
                style: TextStyle(
                  fontSize: size.width * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.cloud, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
