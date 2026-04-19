import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioListener {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    final granted = await requestPermission();
    if (!granted) return false;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vyanjak_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    return true;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}