import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/network/pexel_service.dart';
import '../../widgets/frosted_card.dart';

class WordRevealScreen extends StatefulWidget {
  final String primaryGuess;
  final List<String> alternatives;
  final double confidenceScore;
  final Function(bool confirmed)? onWordConfirmed;

  const WordRevealScreen({
    super.key,
    required this.primaryGuess,
    required this.alternatives,
    required this.confidenceScore,
    this.onWordConfirmed,
  });

  @override
  State<WordRevealScreen> createState() => _WordRevealScreenState();
}

class _WordRevealScreenState extends State<WordRevealScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final PexelService _pexelService = PexelService();
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _imageUrl = '';
  bool _isLoadingImage = true;
  String _activeWord = '';
  bool _confirmed = false;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _activeWord = widget.primaryGuess;
    _entryController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
    _triggerHaptic();
    _fetchImage(_activeWord);
    _speakWord(_activeWord);
  }

  Future<void> _triggerHaptic() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _fetchImage(String word) async {
    setState(() { _isLoadingImage = true; _imageUrl = ''; });
    final url = await _pexelService.fetchClinicalImage(word);
    if (mounted) setState(() { _imageUrl = url; _isLoadingImage = false; });
  }

  Future<void> _speakWord(String word) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.speak(word);
  }

  void _selectAlternative(String word) {
    HapticFeedback.selectionClick();
    setState(() { _activeWord = word; _confirmed = false; _denied = false; });
    _fetchImage(word);
    _speakWord(word);
  }

  void _confirmWord() {
    HapticFeedback.heavyImpact();
    setState(() { _confirmed = true; _denied = false; });
    widget.onWordConfirmed?.call(true);
  }

  void _denyWord() {
    HapticFeedback.mediumImpact();
    setState(() { _denied = true; _confirmed = false; });
    widget.onWordConfirmed?.call(false);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.spaceNavy, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.electricTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(widget.confidenceScore * 100).toStringAsFixed(0)}% match',
                      style: const TextStyle(
                          color: AppTheme.spaceNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildImage(),
                    const SizedBox(height: 24),
                    Text(
                      _activeWord.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 68),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _speakWord(_activeWord),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.spaceNavy,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up_rounded,
                                color: AppTheme.electricTeal, size: 18),
                            SizedBox(width: 8),
                            Text('Tap to hear',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _confirmWord,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _confirmed
                              ? AppTheme.electricTeal
                              : AppTheme.electricTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                color: _confirmed
                                    ? Colors.white
                                    : AppTheme.electricTeal,
                                size: 22),
                            const SizedBox(width: 8),
                            Text('Yes, this!',
                                style: TextStyle(
                                    color: _confirmed
                                        ? Colors.white
                                        : AppTheme.electricTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _denyWord,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _denied
                              ? AppTheme.errorRed
                              : AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                color: _denied
                                    ? Colors.white
                                    : AppTheme.errorRed,
                                size: 22),
                            const SizedBox(width: 8),
                            Text('Not right',
                                style: TextStyle(
                                    color: _denied
                                        ? Colors.white
                                        : AppTheme.errorRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.alternatives.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DID YOU MEAN?',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                              color: Colors.grey,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: widget.alternatives
                            .take(3)
                            .map((alt) => GestureDetector(
                          onTap: () => _selectAlternative(alt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeWord == alt
                                  ? AppTheme.electricTeal
                                  : AppTheme.frostyWhite,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                color: _activeWord == alt
                                    ? AppTheme.electricTeal
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              alt.toUpperCase(),
                              style: TextStyle(
                                color: _activeWord == alt
                                    ? Colors.white
                                    : AppTheme.spaceNavy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricTeal,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('New Analysis',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: _isLoadingImage
          ? Container(
        height: 200,
        width: 200,
        color: AppTheme.frostyWhite,
        child: Center(
            child: CircularProgressIndicator(
                color: AppTheme.electricTeal, strokeWidth: 2.5)),
      )
          : _imageUrl.isNotEmpty
          ? Image.network(_imageUrl,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder())
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
          color: AppTheme.frostyWhite,
          borderRadius: BorderRadius.circular(24)),
      child: const Icon(Icons.image_outlined, size: 60, color: Colors.grey),
    );
  }
}