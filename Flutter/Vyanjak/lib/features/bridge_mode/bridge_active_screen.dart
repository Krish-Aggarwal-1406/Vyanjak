import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_theme.dart';
import '../../core/sensors/audio_listener.dart';
import '../../core/sensors/motion_detector.dart';
import '../../core/network/gemini_service.dart';
import '../../core/services/vad_service.dart';
import '../../core/services/firestore_service.dart';
import '../../widgets/frosted_card.dart';
import 'word_reveal_screen.dart';

class BridgeActiveScreen extends StatefulWidget {
  const BridgeActiveScreen({super.key});

  @override
  State<BridgeActiveScreen> createState() => _BridgeActiveScreenState();
}

class _BridgeActiveScreenState extends State<BridgeActiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final AudioListener _audioListener = AudioListener();
  final GeminiService _geminiService = GeminiService();
  final MotionDetector _motionDetector = MotionDetector();
  final VadService _vadService = VadService();
  final FirestoreService _db = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  bool _isManualMode = true;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isAutoListening = false;
  String _statusText = 'TAP ORB TO START';
  String _selectedContext = 'Kitchen — objects around me';
  int _sessionAttempts = 0;
  int _sessionSuccesses = 0;
  File? _contextImage;
  final List<Map<String, dynamic>> _sessionWords = [];

  final List<String> _contextOptions = [
    'Kitchen — objects around me',
    'Living Room — daily items',
    'Bedroom — personal items',
    'Outdoor — general surroundings',
    'Office — work environment',
  ];

  final List<String> _processingMessages = [
    'Analyzing your intent...',
    'Reading the hesitation...',
    'Consulting Gemini AI...',
    'Finding the word...',
  ];
  int _processingMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _motionDetector.startListening(onFrustration: _onFrustrationDetected);
  }

  void _onFrustrationDetected() {
    if (!_isRecording && !_isProcessing && _isManualMode) {
      HapticFeedback.heavyImpact();
      _startManualRecording();
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _contextImage = File(picked.path));
    }
  }

  Future<void> _startManualRecording() async {
    final started = await _audioListener.startRecording();
    if (!started) {
      _showError('Microphone permission denied.');
      return;
    }
    setState(() {
      _isRecording = true;
      _statusText = 'LISTENING...';
    });
    _pulseController.repeat(reverse: true);
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopManualAndAnalyze() async {
    if (!_isRecording) return;
    _pulseController.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusText = 'ANALYZING...';
      _processingMessageIndex = 0;
    });
    _startProcessingMessages();
    HapticFeedback.heavyImpact();
    final path = await _audioListener.stopRecording();
    if (path != null) await _sendToAI(path);
  }

  void _startProcessingMessages() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!_isProcessing || !mounted) return false;
      setState(() {
        _processingMessageIndex =
            (_processingMessageIndex + 1) % _processingMessages.length;
      });
      return true;
    });
  }

  Future<void> _startAutoMode() async {
    setState(() {
      _isAutoListening = true;
      _statusText = 'AUTO — WAITING FOR SPEECH';
    });
    _pulseController.repeat(reverse: true);
    HapticFeedback.mediumImpact();

    await _vadService.startMonitoring(
      onStarted: () {
        if (mounted) {
          setState(() => _statusText = 'SPEECH DETECTED');
          HapticFeedback.lightImpact();
        }
      },
      onHesitation: (audioPath) async {
        if (mounted) {
          setState(() {
            _statusText = 'ANALYZING HESITATION...';
            _isProcessing = true;
            _processingMessageIndex = 0;
          });
          _startProcessingMessages();
          HapticFeedback.heavyImpact();
          await _sendToAI(audioPath);
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _statusText = 'AUTO — WAITING FOR SPEECH';
            });
          }
        }
      },
      onSilentStop: () {
        if (mounted)
          setState(() => _statusText = 'AUTO — WAITING FOR SPEECH');
      },
    );
  }

  Future<void> _stopAutoMode() async {
    await _vadService.stopMonitoring();
    _pulseController.stop();
    setState(() {
      _isAutoListening = false;
      _statusText = 'TAP ORB TO START';
    });
  }

  Future<void> _sendToAI(String audioPath) async {
    try {
      final result =
      await _geminiService.predictWord(audioPath, _selectedContext);

      if (!mounted) return;

      final primaryGuess = result['primary_guess']?.toString() ?? '';
      final alternatives = List<String>.from(result['alternatives'] ?? []);
      final confidence = (result['confidence_score'] ?? 0.0) as num;

      if (primaryGuess.isEmpty) {
        _showError('AI returned empty response. Try again.');
        return;
      }

      _sessionAttempts++;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordRevealScreen(
            primaryGuess: primaryGuess,
            alternatives: alternatives,
            confidenceScore: confidence.toDouble(),
            onWordConfirmed: (confirmed) {
              if (confirmed) _sessionSuccesses++;
            },
          ),
        ),
      );

      _db.saveBridgeSession({
        'word': primaryGuess,
        'confidence': confidence.toDouble(),
        'context': _selectedContext,
      }).catchError((e) => print('Firestore save failed: $e'));

    } catch (e) {
      _showError('ERROR: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  void _toggleMode(bool manual) {
    if (_isRecording || _isAutoListening) return;
    setState(() {
      _isManualMode = manual;
      _statusText = manual ? 'TAP ORB TO START' : 'TAP ORB TO START AUTO';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioListener.dispose();
    _motionDetector.stopListening();
    _vadService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.spaceNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white54, size: 22),
                  ),
                  Text(
                    _statusText,
                    style: TextStyle(
                      color: _isRecording || _isAutoListening
                          ? AppTheme.electricTeal
                          : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleMode(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isManualMode
                                ? AppTheme.electricTeal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('Manual',
                                style: TextStyle(
                                  color: _isManualMode
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleMode(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isManualMode
                                ? AppTheme.electricTeal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('Auto Detect',
                                style: TextStyle(
                                  color: !_isManualMode
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FrostedCard(
                color: Colors.white.withOpacity(0.05),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedContext,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0D2B1F),
                    icon: const Icon(Icons.expand_more_rounded,
                        color: AppTheme.electricTeal),
                    style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                    items: _contextOptions
                        .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedContext = val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ── Optional image attach ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _contextImage != null
                          ? AppTheme.electricTeal
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _contextImage != null
                            ? Icons.check_circle_rounded
                            : Icons.add_photo_alternate_rounded,
                        color: _contextImage != null
                            ? AppTheme.electricTeal
                            : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _contextImage != null
                              ? 'Image attached — tap to change'
                              : 'Add photo for better context (optional)',
                          style: TextStyle(
                            color: _contextImage != null
                                ? AppTheme.electricTeal
                                : Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_contextImage != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _contextImage = null),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white38, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final isActive = _isRecording || _isAutoListening;
                return GestureDetector(
                  onTap: _isProcessing
                      ? null
                      : _isManualMode
                      ? (_isRecording
                      ? _stopManualAndAnalyze
                      : _startManualRecording)
                      : (_isAutoListening
                      ? _stopAutoMode
                      : _startAutoMode),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.electricTeal.withOpacity(
                          isActive
                              ? 0.15 * _pulseAnimation.value
                              : 0.08),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: AppTheme.electricTeal.withOpacity(
                              0.3 * _pulseAnimation.value),
                          blurRadius: 80 * _pulseAnimation.value,
                          spreadRadius:
                          20 * _pulseAnimation.value,
                        )
                      ]
                          : [],
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const CircularProgressIndicator(
                          color: AppTheme.electricTeal,
                          strokeWidth: 3)
                          : Icon(
                        _isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: AppTheme.electricTeal,
                        size: 72,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _isProcessing
                    ? _processingMessages[_processingMessageIndex]
                    : _isManualMode
                    ? (_isRecording
                    ? 'Tap to stop & analyze'
                    : 'Tap orb to begin recording')
                    : (_isAutoListening
                    ? 'Listening for hesitation — tap to stop'
                    : 'Tap orb to start auto detection'),
                key: ValueKey(_isProcessing
                    ? _processingMessageIndex
                    : _statusText),
                style: TextStyle(
                    color: _isProcessing
                        ? AppTheme.electricTeal
                        : Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            if (_sessionAttempts > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FrostedCard(
                  color: Colors.white.withOpacity(0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SessionStat(
                          label: 'Attempts',
                          value: '$_sessionAttempts'),
                      _SessionStat(
                          label: 'Confirmed',
                          value: '$_sessionSuccesses'),
                      _SessionStat(
                          label: 'Accuracy',
                          value: _sessionAttempts > 0
                              ? '${((_sessionSuccesses / _sessionAttempts) * 100).toStringAsFixed(0)}%'
                              : '—'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: FrostedCard(
                color: Colors.white.withOpacity(0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.vibration_rounded,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    Text('Shake phone to trigger manual analysis',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12)),
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

class _SessionStat extends StatelessWidget {
  final String label;
  final String value;
  const _SessionStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.electricTeal,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}