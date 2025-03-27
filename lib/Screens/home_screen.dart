import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agribot/Providers/weather_provider.dart';
// import 'package:agribot/Widgets/date_time_picker.dart';
import 'recommendation_page.dart'; // Import your recommendation page

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 104),
              child: Text('Home', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.yellow.shade50,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Weather Widget
            if (errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.red[100],
                child: Text(errorMessage, style: TextStyle(color: Colors.red)),
              ),
            weatherProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : weather == null
                    ? Center(child: Text("Error loading weather data"))
                    : Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Weather",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("NOW"),
                                    Text(capitalizeEachWord(
                                        weather.description)),
                                  ],
                                ),
                                Text("${weather.temperature}°C",
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold)),
                                Icon(Icons.cloud, color: Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
            SizedBox(height: 20),

            // Products & Services Title
            Text('Products & Services',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            SizedBox(height: 10),

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
                      child: Image.asset(
                        'assets/images/crop_selection.jpg', // Use appropriate image asset
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      title: Text('Crop Recommendation',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Recommendation about the type of crops to be cultivated based on conditions.'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            ),

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
                      child: Image.asset(
                        'assets/images/fertilizer.jpg', // Use appropriate image asset
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      title: Text('Fertilizer Prediction',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Find out the best fertilizer for your crop based on the soil.'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
