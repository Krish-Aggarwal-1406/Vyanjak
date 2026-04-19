import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class MotionDetector {
  StreamSubscription? _subscription;
  final List<double> _recentMagnitudes = [];
  Function? onFrustrationDetected;

  void startListening({required Function onFrustration}) {
    onFrustrationDetected = onFrustration;
    _subscription = accelerometerEventStream().listen((event) {
      final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      _recentMagnitudes.add(magnitude);
      if (_recentMagnitudes.length > 10) _recentMagnitudes.removeAt(0);
      if (_recentMagnitudes.length == 10) {
        final avg = _recentMagnitudes.reduce((a, b) => a + b) / 10;
        if (avg > 250) {
          onFrustrationDetected?.call();
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}