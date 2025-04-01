import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agribot/Providers/weather_provider.dart';
import 'recommendation_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      await Provider.of<WeatherProvider>(context, listen: false).fetchWeather();
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
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weather;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: Center(child: Text('Home')),
      ),
      backgroundColor: Colors.yellow.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: size.height * 0.02, horizontal: size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Widget
              if (errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(size.width * 0.03),
                  color: Colors.red[100],
                  child:
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                ),
              weatherProvider.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : weather == null
                      ? Center(child: Text("Error loading weather data"))
                      : Container(
                          padding: EdgeInsets.all(size.width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Weather",
                                  style: TextStyle(
                                      fontSize: size.width * 0.05,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: size.height * 0.01),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("NOW"),
                                      Text(capitalizeEachWord(
                                          weather.description)),
                                    ],
                                  ),
                                  Text("${weather.temperature}°C",
                                      style: TextStyle(
                                          fontSize: size.width * 0.08,
                                          fontWeight: FontWeight.bold)),
                                  Icon(Icons.cloud, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
              SizedBox(height: size.height * 0.02),

              // Products & Services Title
              Text('Products & Services',
                  style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: size.height * 0.015),

              // Crop Recommendation Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RecommendationPage()));
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            'assets/images/crop_selection.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text('Crop Recommendation',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Recommendation about the type of crops based on conditions.'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.015),

              // Fertilizer Prediction Card
              GestureDetector(
                onTap: () {
                  // Add navigation to Fertilizer Prediction Page if needed
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            'assets/images/fertilizer.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text('Fertilizer Prediction',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Find the best fertilizer for your crop based on soil.'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
