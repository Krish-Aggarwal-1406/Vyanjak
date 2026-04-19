import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vyanjak/core/services/firestore_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/network/pexel_service.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/practice_flashcard.dart';

class PracticeSession extends StatefulWidget {
  const PracticeSession({super.key});

  @override
  State<PracticeSession> createState() => _PracticeSessionState();
}

class _PracticeSessionState extends State<PracticeSession> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final PexelService _pexelService = PexelService();

  final List<String> _allWords = [
    'Kettle', 'Wallet', 'Keys', 'Apple', 'Glasses',
    'Phone', 'Water', 'Chair', 'Table', 'Bottle',
    'Spoon', 'Clock', 'Lamp', 'Book', 'Pen',
    'Shoe', 'Bag', 'Cup', 'Door', 'Window',
  ];

  late List<String> _sessionWords;
  int _currentIndex = 0;
  String _imageUrl = '';
  bool _isLoadingImage = false;
  bool _wordVisible = false;
  bool _isListening = false;
  bool _sttAvailable = false;
  String _heardText = '';
  bool? _lastAttemptCorrect;

  int _score = 0;
  int _attempts = 0;
  bool _sessionComplete = false;
  final List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    _sessionWords = List.from(_allWords)..shuffle(Random());
    _sessionWords = _sessionWords.take(8).toList();
    _sttAvailable = await _stt.initialize();
    _loadCard(0);
  }

  Future<void> _loadCard(int index) async {
    setState(() {
      _isLoadingImage = true;
      _wordVisible = false;
      _imageUrl = '';
      _heardText = '';
      _lastAttemptCorrect = null;
    });
    final url = await _pexelService.fetchClinicalImage(_sessionWords[index]);
    if (mounted) setState(() { _imageUrl = url; _isLoadingImage = false; });
  }

  Future<void> _speak() async {
    HapticFeedback.lightImpact();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.speak(_sessionWords[_currentIndex]);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      _showSnack('Speech recognition not available on this device.');
      return;
    }
    setState(() { _isListening = true; _heardText = ''; _lastAttemptCorrect = null; });
    HapticFeedback.mediumImpact();
    await _stt.listen(
      onResult: (result) {
        setState(() => _heardText = result.recognizedWords);
        if (result.finalResult) _evaluateAttempt(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _isListening = false);
  }

  void _evaluateAttempt(String heard) {
    _stt.stop();
    final target = _sessionWords[_currentIndex].toLowerCase().trim();
    final spokenWords = heard.toLowerCase().trim().split(' ');
    final correct = spokenWords.any((w) =>
    w == target ||
        (w.length > 3 && target.contains(w)) ||
        (target.length > 3 && w.contains(target)));

    setState(() {
      _isListening = false;
      _lastAttemptCorrect = correct;
      _attempts++;
      if (correct) _score++;
    });

    HapticFeedback.heavyImpact();
    _results.add({
      'word': _sessionWords[_currentIndex],
      'heard': heard,
      'correct': correct,
    });
  }

  void _next() {
    if (_lastAttemptCorrect == null) {
      _showSnack('Try saying the word first!');
      return;
    }
    HapticFeedback.selectionClick();
    if (_currentIndex < _sessionWords.length - 1) {
      setState(() => _currentIndex++);
      _loadCard(_currentIndex);
    } else {
      _finishSession();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex--);
      _loadCard(_currentIndex);
    }
  }

  Future<void> _finishSession() async {
    final _db = FirestoreService();

    await _db.savePracticeSession({
      'date': DateTime.now().toIso8601String(),
      'score': _score,
      'total': _sessionWords.length,
      'accuracy': _score / _sessionWords.length,
      'results': _results,
    });

    await _db.updateStruggleWords(_results);

    setState(() => _sessionComplete = true);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionComplete) return _buildSummary();
    return _buildSession();
  }

  Widget _buildSession() {
    final word = _sessionWords[_currentIndex];
    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.spaceNavy),
        title: Text('Practice Session',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppTheme.spaceNavy)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$_score / $_attempts',
                  style: const TextStyle(
                      color: AppTheme.electricTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _sessionWords.length,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.electricTeal),
                borderRadius: BorderRadius.circular(8),
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Text('${_currentIndex + 1} of ${_sessionWords.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 16),
              PracticeFlashcard(
                  imageUrl: _imageUrl, isLoading: _isLoadingImage),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _wordVisible = !_wordVisible),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _wordVisible
                      ? Text(word.toUpperCase(),
                      key: const ValueKey('visible'),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 48))
                      : Container(
                      key: const ValueKey('hidden'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.spaceNavy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Tap to reveal word',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey))),
                ),
              ),
              if (_heardText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _lastAttemptCorrect == true
                        ? AppTheme.electricTeal.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _lastAttemptCorrect == true
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _lastAttemptCorrect == true
                            ? AppTheme.electricTeal
                            : AppTheme.errorRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastAttemptCorrect == true
                            ? 'Correct! You said "$_heardText"'
                            : 'Heard "$_heardText" — try again',
                        style: TextStyle(
                          color: _lastAttemptCorrect == true
                              ? AppTheme.electricTeal
                              : AppTheme.errorRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              FrostedCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.spaceNavy),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _speak,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.spaceNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.volume_up_rounded,
                                    color: AppTheme.spaceNavy, size: 18),
                                SizedBox(width: 6),
                                Text('Hear',
                                    style: TextStyle(
                                        color: AppTheme.spaceNavy,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap:
                          _isListening ? _stopListening : _startListening,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? AppTheme.electricTeal
                                  : AppTheme.electricTeal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    _isListening
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: _isListening
                                        ? Colors.white
                                        : AppTheme.electricTeal,
                                    size: 18),
                                const SizedBox(width: 6),
                                Text(
                                    _isListening ? 'Stop' : 'Say it',
                                    style: TextStyle(
                                        color: _isListening
                                            ? Colors.white
                                            : AppTheme.electricTeal,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.spaceNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final accuracy = _attempts > 0 ? (_score / _attempts * 100).toInt() : 0;
    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text('Session Complete!',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text('Great work today.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 40),
              FrostedCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryTile(label: 'Score', value: '$_score/${_sessionWords.length}'),
                    _SummaryTile(label: 'Accuracy', value: '$accuracy%'),
                    _SummaryTile(label: 'Attempts', value: '$_attempts'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FrostedCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      return ListTile(
                        title: Text(r['word'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.spaceNavy)),
                        subtitle: Text('Said: ${r['heard'].isEmpty ? "—" : r['heard']}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        trailing: Icon(
                          r['correct']
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: r['correct']
                              ? AppTheme.electricTeal
                              : AppTheme.errorRed,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricTeal,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Back to Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.spaceNavy,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}