import 'package:agribot/Widgets/sensor_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('sensors');

  Map<String, dynamic> sensorData = {
    'temperature': 0,
    'humidity': 0,
    'soilMoisture': 0,
    'distance': 0,
  };

  List<FlSpot> tempDataPoints = [];
  List<FlSpot> moistureDataPoints = [];

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  void _fetchSensorData() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value == null) {
        print("No data found at 'Sensors' node.");
        return;
      }

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          sensorData['temperature'] = data['temperature'] ?? 0;
          sensorData['humidity'] = data['humidity'] ?? 0;
          sensorData['soilMoisture'] = data['soilMoisture'] ?? 0;
          sensorData['distance'] = data['distance'] ?? 0;

          if (tempDataPoints.length >= 15) {
            tempDataPoints.removeAt(0);
          }
          tempDataPoints.add(
            FlSpot(tempDataPoints.length.toDouble(),
                sensorData['temperature'].toDouble()),
          );

          if (moistureDataPoints.length >= 10) {
            moistureDataPoints.removeAt(0);
          }
          moistureDataPoints.add(
            FlSpot(moistureDataPoints.length.toDouble(),
                sensorData['soilMoisture'].toDouble()),
          );
        });
      } catch (e) {
        print("Error fetching data: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.green),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: ListView(
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: size.width * 0.04,
              mainAxisSpacing: size.height * 0.02,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SensorCard(
                  title: 'Temperature',
                  value: '${sensorData['temperature']} °C',
                  subtitle: _evaluateTemperature(sensorData['temperature']),
                ),
                SensorCard(
                  title: 'Humidity',
                  value: '${sensorData['humidity']}%',
                  subtitle: _evaluateHumidity(sensorData['humidity']),
                ),
                SensorCard(
                  title: 'Soil Moisture',
                  value: '${sensorData['soilMoisture']}',
                  subtitle: _evaluateSoilMoisture(sensorData['soilMoisture']),
                ),
                SensorCard(
                  title: 'Distance',
                  value: '${sensorData['distance']} cm',
                  subtitle: 'Proximity Data',
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),

            // Temperature Trend Graph
            Text(
              'Temperature Trend',
              style: TextStyle(
                  fontSize: size.width * 0.045, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: size.height * 0.25,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: tempDataPoints,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.amber,
                      belowBarData: BarAreaData(
                          show: true, color: Colors.amber.withOpacity(0.2)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),

            // Soil Moisture Trend Graph
            Text(
              'Soil Moisture Trend',
              style: TextStyle(
                  fontSize: size.width * 0.045, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: size.height * 0.25,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: moistureDataPoints,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.2)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _evaluateTemperature(dynamic temp) {
    if (temp == null) return 'No Data';
    double tempValue = (temp as num).toDouble();
    if (tempValue < 20) return 'Low';
    if (tempValue > 30) return 'High';
    return 'Optimal';
  }

  String _evaluateHumidity(dynamic humidity) {
    if (humidity == null) return 'No Data';
    double humidityValue = (humidity as num).toDouble();
    if (humidityValue > 70) return 'High Humidity';
    return 'Normal';
  }

  String _evaluateSoilMoisture(dynamic soilMoisture) {
    if (soilMoisture == null) return 'No Data';
    double moisture = (soilMoisture as num).toDouble();
    if (moisture < 300) return 'Dry';
    if (moisture > 700) return 'Wet';
    return 'Optimal';
  }
}
