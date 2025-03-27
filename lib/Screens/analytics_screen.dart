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
          // Store sensor data
          sensorData['temperature'] = data['temperature'] ?? 0;
          sensorData['humidity'] = data['humidity'] ?? 0;
          sensorData['soilMoisture'] = data['soilMoisture'] ?? 0;
          sensorData['distance'] = data['distance'] ?? 0;

          // Add new temperature point, keeping only the last 15 values
          if (tempDataPoints.length >= 15) {
            tempDataPoints.removeAt(0); // Remove oldest value
          }
          tempDataPoints.add(
            FlSpot(tempDataPoints.length.toDouble(),
                sensorData['temperature'].toDouble()),
          );

          // Add new soil moisture point, keeping only the last 10 values
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
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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
            const SizedBox(height: 16),

            // Temperature Trend Graph
            const Text('Temperature Trend'),
            SizedBox(
              height: 200,
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
            const SizedBox(height: 16),

            // Soil Moisture Trend Graph
            const Text('Soil Moisture Trend'),
            SizedBox(
              height: 200,
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

  // Evaluation functions for better insights
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
