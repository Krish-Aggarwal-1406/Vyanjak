import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VadState { idle, speechDetected, hesitationDetected, silent }

class VadService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _pauseTimer;
  Timer? _silenceTimer;

  VadState _state = VadState.idle;
  bool _isRunning = false;
  String? _currentPath;

  static const double _speechThreshold = -30.0;
  static const Duration _hesitationDuration = Duration(milliseconds: 900);
  static const Duration _autoStopSilence = Duration(seconds: 2);

  Function(String audioPath)? onHesitationCaptured;
  Function()? onListeningStarted;
  Function()? onSilence;

  Future<void> startMonitoring({
    required Function(String audioPath) onHesitation,
    required Function() onStarted,
    required Function() onSilentStop,
  }) async {
    onHesitationCaptured = onHesitation;
    onListeningStarted = onStarted;
    onSilence = onSilentStop;
    _isRunning = true;
    _state = VadState.idle;
    await _startListeningCycle();
  }

  Future<void> _startListeningCycle() async {
    if (!_isRunning) return;
    final dir = await getTemporaryDirectory();
    _currentPath = '${dir.path}/vad_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _currentPath!,
    );

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen(_onAmplitude);
  }

  void _onAmplitude(Amplitude amp) {
    final double current = amp.current;

    if (current > _speechThreshold) {
      _silenceTimer?.cancel();
      _pauseTimer?.cancel();

      if (_state == VadState.idle || _state == VadState.silent) {
        _state = VadState.speechDetected;
        onListeningStarted?.call();
      }
      if (_state == VadState.hesitationDetected) {
        _state = VadState.speechDetected;
      }
    } else {
      if (_state == VadState.speechDetected) {
        _state = VadState.hesitationDetected;
        _pauseTimer?.cancel();
        _pauseTimer = Timer(_hesitationDuration, _onHesitationConfirmed);
      }
      if (_state == VadState.idle) {
        _silenceTimer?.cancel();
        _silenceTimer = Timer(_autoStopSilence, () {
          _state = VadState.silent;
          onSilence?.call();
        });
      }
    }
  }

  Future<void> _onHesitationConfirmed() async {
    if (!_isRunning) return;
    _state = VadState.idle;
    await _amplitudeSub?.cancel();
    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      onHesitationCaptured?.call(path);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isRunning) await _startListeningCycle();
  }

  Future<void> stopMonitoring() async {
    _isRunning = false;
    _pauseTimer?.cancel();
    _silenceTimer?.cancel();
    await _amplitudeSub?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _recorder.dispose();
  }
}