// weather_widget.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key, this.asCardChild = false}) : super(key: key);
  final bool asCardChild; // when true, don't wrap with decorated container
  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Position? _position;
  Map<String, dynamic>? _forecast;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getWeather();
  }

  Future<void> _getWeather() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _position = pos);

      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=${pos.latitude}'
          '&longitude=${pos.longitude}'
          '&current=temperature_2m,relative_humidity_2m,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
          '&forecast_days=3'
          '&timezone=auto';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw Exception('Failed to fetch weather (HTTP ${res.statusCode})');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected weather payload');
      }

      if (!mounted) return;
      setState(() => _forecast = decoded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ---------- Helpers ----------
  double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  int? _toI(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  /// Accepts 'YYYY-MM-DD', 'YYYY-MM-DDTHH:mm', or full ISO
  DateTime? _safeParseIso(String s) {
    if (s.isEmpty) return null;
    try {
      if (s.length == 10) {
        return DateTime.tryParse('${s}T00:00:00');
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(s)) {
        return DateTime.tryParse('$s:00');
      }
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_forecast == null)
      return const Center(child: Text('No forecast available'));

    final current = (_forecast!['current'] as Map<String, dynamic>?) ?? {};
    final daily = (_forecast!['daily'] as Map<String, dynamic>?) ?? {};

    // Current values
    final String currentTimeIso = (current['time'] ?? '') as String;
    final double? currentTemp = _toD(current['temperature_2m']);
    final int? rh = _toI(current['relative_humidity_2m']);
    final double? wind = _toD(current['wind_speed_10m']);

    // Daily arrays
    final List times = (daily['time'] as List?) ?? const [];
    final List tMax = (daily['temperature_2m_max'] as List?) ?? const [];
    final List tMin = (daily['temperature_2m_min'] as List?) ?? const [];
    final List precip = (daily['precipitation_sum'] as List?) ?? const [];

    // Formatting
    final dfHeader = DateFormat('EEE, d MMM • HH:mm'); // top timestamp
    final dfTile = DateFormat('EEE dd-MM'); // tiles: EEE dd-MM

    final currentDt = _safeParseIso(currentTimeIso);
    final currentLine = currentDt != null ? dfHeader.format(currentDt) : '';

    // IMPORTANT: Use Column here (non-scrollable), since parent is a ListView
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // let column take only needed height
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                  color: Color(0x11000000),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // keep it compact
              children: [
                Text(
                  'Weather',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (currentLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
                const SizedBox(height: 12),

                // Current conditions row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentTemp != null
                          ? '${currentTemp.toStringAsFixed(1)}°C'
                          : '—',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                              label: 'Humidity',
                              value: rh != null ? '$rh%' : '—'),
                          _StatChip(
                              label: 'Wind',
                              value: wind != null
                                  ? '${wind.toStringAsFixed(1)} km/h'
                                  : '—'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                Text(
                  '3-Day Forecast',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),

                // The inner list is HORIZONTAL and has a fixed height; it's OK.
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: times.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final dateIso =
                          (i < times.length) ? times[i] as String : '';
                      final max = (i < tMax.length) ? _toD(tMax[i]) : null;
                      final min = (i < tMin.length) ? _toD(tMin[i]) : null;
                      final pr = (i < precip.length) ? _toD(precip[i]) : null;

                      final dt = _safeParseIso(dateIso);
                      final dateLabel = dt != null ? dfTile.format(dt) : '—';

                      return _ForecastTile(
                        dateLabel: dateLabel, // e.g., "Wed 24-09"
                        max: max,
                        min: min,
                        precipMm: pr,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Small stateless pieces ----------

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child:
          Text('$label: $value', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({
    required this.dateLabel,
    required this.max,
    required this.min,
    required this.precipMm,
  });

  final String dateLabel;
  final double? max;
  final double? min;
  final double? precipMm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel, // e.g., "Wed 24-09"
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text('Max: ${max != null ? max!.toStringAsFixed(1) : '—'}°C'),
          Text('Min: ${min != null ? min!.toStringAsFixed(1) : '—'}°C'),
          Text(
              'Rain: ${precipMm != null ? precipMm!.toStringAsFixed(1) : '—'} mm'),
        ],
      ),
    );
  }
}
