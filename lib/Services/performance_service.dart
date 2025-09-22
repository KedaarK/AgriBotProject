import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;

  Future<T> trackOperation<T>({
    required String traceName,
    required Future<T> Function() operation,
    Map<String, int>? metrics,
  }) async {
    final Trace trace = _performance.newTrace(traceName);
    await trace.start();
    try {
      final T result = await operation();
      // Optionally add custom metrics
      metrics?.forEach((key, value) => trace.setMetric(key, value));
      return result;
    } finally {
      await trace.stop();
    }
  }

  Future<T> trackCameraOperation<T>({
    required Future<T> Function() operation,
    Map<String, int>? metrics,
  }) async {
    return trackOperation(
      traceName: 'camera_operation',
      operation: operation,
      metrics: metrics,
    );
  }
}
