import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:agribot/Widgets/weather_widget.dart';

enum TimeFilter { entire, month, week }

// ---------- Model ----------
class WeatherSoilData {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double rainfall;
  final double rainyDays;
  final double sunHours;
  final double soilMoisture;
  final double soilPh;
  final double nitrogen;
  final double potassium;
  final double salinity;

  WeatherSoilData({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainfall,
    required this.rainyDays,
    required this.sunHours,
    required this.soilMoisture,
    required this.soilPh,
    required this.nitrogen,
    required this.potassium,
    required this.salinity,
  });

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateFormat('dd-MM-yyyy').parse(v);
      } catch (_) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  factory WeatherSoilData.fromMap(Map<String, dynamic> m) {
    double numOf(dynamic x) => (x == null)
        ? 0.0
        : (x is num ? x.toDouble() : double.tryParse('$x') ?? 0.0);

    return WeatherSoilData(
      date: _parseDate(m['date']),
      maxTemp: numOf(m['maxTemp']),
      minTemp: numOf(m['minTemp']),
      rainfall: numOf(m['rainfall']),
      rainyDays: numOf(m['rainyDays']),
      sunHours: numOf(m['sunHours']),
      soilMoisture: numOf(m['soilMoisture']),
      soilPh: numOf(m['soilPh']),
      nitrogen: numOf(m['nitrogen']),
      potassium: numOf(m['potassium']),
      salinity: numOf(m['salinity']),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'rainfall': rainfall,
        'rainyDays': rainyDays,
        'sunHours': sunHours,
        'soilMoisture': soilMoisture,
        'soilPh': soilPh,
        'nitrogen': nitrogen,
        'potassium': potassium,
        'salinity': salinity,
      };
}

// ---------- Screen ----------
class AnalyticsScreen2 extends StatefulWidget {
  const AnalyticsScreen2({super.key});

  @override
  State<AnalyticsScreen2> createState() => _AnalyticsScreen2State();
}

class _AnalyticsScreen2State extends State<AnalyticsScreen2> {
  TimeFilter _filter = TimeFilter.entire;

  // Chart behaviors
  final _zoom = ZoomPanBehavior(
      enablePanning: true, enablePinching: true, zoomMode: ZoomMode.x);
  final _tooltip = TooltipBehavior(enable: true);
  final _trackball =
      TrackballBehavior(enable: true, activationMode: ActivationMode.singleTap);
  final _crosshair = CrosshairBehavior(enable: false);

  // Typed converter
  late final CollectionReference<WeatherSoilData> _col = FirebaseFirestore
      .instance
      .collection('hi')
      .withConverter<WeatherSoilData>(
        fromFirestore: (snap, _) => WeatherSoilData.fromMap(snap.data() ?? {}),
        toFirestore: (obj, _) => obj.toMap(),
      );

  // Streams
  Stream<List<WeatherSoilData>> _streamMainWindow() {
    const limit = 800;
    return _col
        .orderBy('date', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => d.data()).toList(),
        );
  }

  Stream<List<WeatherSoilData>> _streamLiveTail() {
    return _col
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      return list.reversed.toList(); // ascending for charts
    });
  }

  // Filter & aggregation
  List<WeatherSoilData> _applyFilter(List<WeatherSoilData> data) {
    if (data.isEmpty) return data;
    final now = DateTime.now();

    if (_filter == TimeFilter.week) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return data
          .where((d) => !d.date.isBefore(start) && d.date.isBefore(end))
          .toList();
    }
    if (_filter == TimeFilter.month) {
      return data
          .where((d) => d.date.year == now.year && d.date.month == now.month)
          .toList();
    }

    // entire: aggregate by year
    final byYear = <int, List<WeatherSoilData>>{};
    for (final d in data) {
      byYear.putIfAbsent(d.date.year, () => []).add(d);
    }
    double avg(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    double sum(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b);

    final out = byYear.entries.map((e) {
      final list = e.value;
      return WeatherSoilData(
        date: DateTime(e.key),
        maxTemp: avg(list.map((x) => x.maxTemp)),
        minTemp: avg(list.map((x) => x.minTemp)),
        rainfall: sum(list.map((x) => x.rainfall)),
        rainyDays: sum(list.map((x) => x.rainyDays)),
        sunHours: avg(list.map((x) => x.sunHours)),
        soilMoisture: avg(list.map((x) => x.soilMoisture)),
        soilPh: avg(list.map((x) => x.soilPh)),
        nitrogen: avg(list.map((x) => x.nitrogen)),
        potassium: avg(list.map((x) => x.potassium)),
        salinity: avg(list.map((x) => x.salinity)),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return out;
  }

  // Downsample
  List<WeatherSoilData> _downsample(List<WeatherSoilData> data,
      {int maxPoints = 500}) {
    if (data.length <= maxPoints) return data;
    final k = (data.length / maxPoints).ceil();
    final out = <WeatherSoilData>[];
    for (int i = 0; i < data.length; i += k) {
      out.add(data[i]);
    }
    if (out.isEmpty || out.last.date != data.last.date) out.add(data.last);
    return out;
  }

  // 7-point moving average helper
  List<WeatherSoilData> _movingAvg(
      List<WeatherSoilData> data, double Function(WeatherSoilData) sel,
      {int window = 7}) {
    if (data.length < 2) return data;
    final out = <WeatherSoilData>[];
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - (window - 1));
      final sub = data.sublist(start, i + 1);
      final v = sub.map(sel).fold<double>(0, (a, b) => a + b) / sub.length;
      // clone date + only one value (reuse nitrogen to carry MA)
      out.add(WeatherSoilData(
        date: data[i].date,
        maxTemp: 0,
        minTemp: 0,
        rainfall: 0,
        rainyDays: 0,
        sunHours: 0,
        soilMoisture: 0,
        soilPh: 0,
        nitrogen: v, // we’ll read this field as MA value
        potassium: 0,
        salinity: 0,
      ));
    }
    return out;
  }

  String _xFormat(TimeFilter f) {
    switch (f) {
      case TimeFilter.entire:
        return 'y';
      case TimeFilter.month:
      case TimeFilter.week:
        return 'MMM d';
    }
  }

  (double minY, double maxY) _safeYBounds(Iterable<double> ys) {
    if (ys.isEmpty) return (0, 1);
    final minV = ys.reduce(min);
    final maxV = ys.reduce(max);
    if (minV == maxV) return (minV - 1, maxV + 1);
    return (minV, maxV);
  }

  Widget _buildAnalyticsSection(List<WeatherSoilData> data) {
    final minDate = data.first.date;
    final maxDate = data.last.date;

    final (minY, maxY) = _safeYBounds(
      data.map((e) => e.minTemp) + data.map((e) => e.maxTemp),
    );

    // moving averages
    final nMA = _movingAvg(data, (d) => d.nitrogen);
    final kMA = _movingAvg(data, (d) => d.potassium);

    return Column(
      children: [
        _card(child: _overviewRow(data)),
        const SizedBox(height: 12),

        // Temperature
        _card(
          title: 'Temperature',
          child: SfCartesianChart(
            legend: const Legend(isVisible: true),
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            trackballBehavior: _trackball,
            crosshairBehavior: _crosshair,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            primaryYAxis: NumericAxis(
              minimum: minY - 1,
              maximum: maxY + 1,
            ),
            series: <CartesianSeries>[
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.maxTemp,
                name: 'Max',
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.minTemp,
                name: 'Min',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rainfall vs Rainy Days
        _card(
          title: 'Rainfall vs Rainy Days',
          child: SfCartesianChart(
            legend: const Legend(isVisible: true),
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            series: <CartesianSeries>[
              ColumnSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.rainfall,
                name: 'Rainfall (mm)',
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.rainyDays,
                name: 'Rainy Days',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Soil Moisture
        _card(
          title: 'Soil Moisture',
          child: SfCartesianChart(
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            series: <CartesianSeries>[
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.soilMoisture,
                name: 'Moisture',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Nutrient Focus
        _card(
          title: 'Nutrient Focus (N & K)',
          child: SfCartesianChart(
            legend: const Legend(isVisible: true),
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            series: <CartesianSeries>[
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.nitrogen,
                name: 'Nitrogen',
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: nMA,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.nitrogen,
                name: 'N (7-pt MA)',
                dashArray: const <double>[4, 3],
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.potassium,
                name: 'Potassium',
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: kMA,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.nitrogen,
                name: 'K (7-pt MA)',
                dashArray: const <double>[4, 3],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // pH & Salinity
        _card(
          title: 'pH & Salinity',
          child: SfCartesianChart(
            legend: const Legend(isVisible: true),
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            primaryYAxis: const NumericAxis(
              plotBands: <PlotBand>[
                PlotBand(
                  isVisible: true,
                  start: 6.0,
                  end: 7.5,
                  color: Color(0x1100AA00),
                  text: 'Optimal pH',
                  textStyle: TextStyle(fontSize: 11),
                ),
              ],
            ),
            series: <CartesianSeries>[
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.soilPh,
                name: 'pH',
              ),
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.salinity,
                name: 'Salinity',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Sun Hours
        _card(
          title: 'Sun Hours',
          child: SfCartesianChart(
            tooltipBehavior: _tooltip,
            zoomPanBehavior: _zoom,
            primaryXAxis: DateTimeAxis(
              minimum: minDate,
              maximum: maxDate,
              intervalType: _filter == TimeFilter.entire
                  ? DateTimeIntervalType.years
                  : DateTimeIntervalType.days,
              dateFormat: DateFormat(_xFormat(_filter)),
            ),
            series: <CartesianSeries>[
              LineSeries<WeatherSoilData, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.sunHours,
                name: 'Sun Hours',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TimeFilter>(
                value: _filter,
                items: const [
                  DropdownMenuItem(
                      value: TimeFilter.entire, child: Text('Entire Timeline')),
                  DropdownMenuItem(
                      value: TimeFilter.month, child: Text('This Month')),
                  DropdownMenuItem(
                      value: TimeFilter.week, child: Text('This Week')),
                ],
                onChanged: (v) => setState(() => _filter = v!),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // global page padding
          SliverPadding(
            padding: pad,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),

                // === WeatherWidget (exact same structure you used) ===
                ListView(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // disable inner scrolling
                  children: [
                    Row(
                      children: [Expanded(child: WeatherWidget())],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ========== LIVE (last 10) – now part of the same scroll ==========
                _card(
                  title: 'Live (last 10)',
                  child: StreamBuilder<List<WeatherSoilData>>(
                    stream: _streamLiveTail(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('Live error: ${snap.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }
                      final data = snap.data ?? [];
                      if (data.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('No recent points.'),
                        );
                      }

                      final minDate = data.first.date;
                      final maxDate = data.last.date;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _liveOverviewRow(data),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: SfCartesianChart(
                              margin: EdgeInsets.zero,
                              primaryXAxis: DateTimeAxis(
                                minimum: minDate,
                                maximum: maxDate,
                                dateFormat: DateFormat('HH:mm'),
                              ),
                              series: <CartesianSeries>[
                                LineSeries<WeatherSoilData, DateTime>(
                                  dataSource: data,
                                  xValueMapper: (d, _) => d.date,
                                  yValueMapper: (d, _) => d.maxTemp,
                                  name: 'Max Temp',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.reversed.take(10).map((d) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(DateFormat('MMM d, HH:mm')
                                          .format(d.date))),
                                  Text('Tmax ${d.maxTemp.toStringAsFixed(1)}°'),
                                  const SizedBox(width: 12),
                                  Text(
                                      'Rain ${d.rainfall.toStringAsFixed(1)}mm'),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ========== ANALYTICS WINDOW (make it non-scrollable; we’re in one scroll) ==========
                StreamBuilder<List<WeatherSoilData>>(
                  stream: _streamMainWindow(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Error loading data: ${snap.error}',
                            style: const TextStyle(color: Colors.red)),
                      );
                    }

                    final raw = (snap.data ?? []);
                    var data = _applyFilter(raw);
                    data = _downsample(data,
                        maxPoints: _filter == TimeFilter.entire ? 300 : 600);

                    if (data.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child:
                            Center(child: Text('No data for selected range.')),
                      );
                    }

                    // Build and return the whole analytics section as one Column.
                    return _buildAnalyticsSection(data);
                  },
                ),

                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _card({String? title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: TextStyle(
                    color: Colors.green.shade900, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _overviewRow(List<WeatherSoilData> data) {
    double avg(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    double sum(Iterable<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b);
    final avgMax = avg(data.map((e) => e.maxTemp));
    final avgMin = avg(data.map((e) => e.minTemp));
    final totalRain = sum(data.map((e) => e.rainfall));
    final avgMoist = avg(data.map((e) => e.soilMoisture));

    Widget metric(String label, String value, {IconData? icon}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: Colors.green.shade700),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value),
          ],
        ),
      );
    }

    return Row(
      children: [
        metric('Avg Max', '${avgMax.toStringAsFixed(1)}°',
            icon: Icons.thermostat),
        metric('Avg Min', '${avgMin.toStringAsFixed(1)}°',
            icon: Icons.ac_unit_outlined),
        metric('Rain (Σ)', '${totalRain.toStringAsFixed(1)} mm',
            icon: Icons.umbrella_outlined),
        metric('Moisture', '${avgMoist.toStringAsFixed(1)}',
            icon: Icons.water_drop_outlined),
      ],
    );
  }

  Widget _liveOverviewRow(List<WeatherSoilData> data) {
    final last = data.last;
    final prev = data.length > 1 ? data[data.length - 2] : null;

    String delta(double a, double? b, {String suffix = ''}) {
      if (b == null) return '—';
      final d = a - b;
      final s = d == 0
          ? '0'
          : (d > 0 ? '+${d.toStringAsFixed(1)}' : d.toStringAsFixed(1));
      return '$s$suffix';
    }

    Widget chip(String label, String value) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text(value),
          ],
        ),
      );
    }

    return Wrap(
      children: [
        chip('Tmax',
            '${last.maxTemp.toStringAsFixed(1)}° (${delta(last.maxTemp, prev?.maxTemp, suffix: "°")})'),
        chip('Rain',
            '${last.rainfall.toStringAsFixed(1)}mm (${delta(last.rainfall, prev?.rainfall, suffix: "mm")})'),
        chip('Moisture',
            '${last.soilMoisture.toStringAsFixed(1)} (${delta(last.soilMoisture, prev?.soilMoisture)})'),
        chip('N',
            '${last.nitrogen.toStringAsFixed(1)} (${delta(last.nitrogen, prev?.nitrogen)})'),
      ],
    );
  }
}

// Small extension to combine iterables for min/max calc
extension _Concat<E> on Iterable<E> {
  Iterable<E> operator +(Iterable<E> other) sync* {
    yield* this;
    yield* other;
  }
}
