import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../widgets/frosted_card.dart';
import '../bridge_mode/bridge_active_screen.dart';
import '../practice_mode/practice_session.dart';
import '../analytics/therapist_stat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();
  String _userName = '';
  double _vocalScore = 0;
  bool _loadingScore = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName?.split(' ').first ?? 'there';
        });
      }
      final sessions = await _db.getPracticeSessions();
      if (sessions.isNotEmpty) {
        final avg = sessions.fold<double>(
            0,
                (prev, s) =>
            prev + ((s['accuracy'] ?? 0.0) as num).toDouble()) /
            sessions.length;
        setState(() {
          _vocalScore = avg;
          _loadingScore = false;
        });
      } else {
        setState(() {
          _vocalScore = 0;
          _loadingScore = false;
        });
      }
    } catch (e) {
      setState(() {
        _vocalScore = 0;
        _loadingScore = false;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _scoreMessage() {
    if (_vocalScore >= 0.8) return 'Strong recovery pacing today.';
    if (_vocalScore >= 0.5) return 'Keep going, steady progress!';
    if (_vocalScore > 0) return 'Practice more to improve your score.';
    return 'Complete a session to see your score.';
  }

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                              color: AppTheme.textCharcoal
                                  .withOpacity(0.6))),
                      Text(
                        _userName.isEmpty ? '...' : _userName,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppTheme.errorRed, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              FrostedCard(
                child: Row(
                  children: [
                    SizedBox(
                      height: 72,
                      width: 72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _loadingScore ? 0 : _vocalScore,
                            strokeWidth: 7,
                            backgroundColor:
                            AppTheme.spaceNavy.withOpacity(0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.electricTeal),
                          ),
                          Center(
                            child: _loadingScore
                                ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.electricTeal))
                                : Text(
                                '${(_vocalScore * 100).toInt()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vocal Clarity Score',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppTheme.spaceNavy)),
                          const SizedBox(height: 4),
                          Text(_scoreMessage(),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Modes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textCharcoal.withOpacity(0.5),
                      fontSize: 13,
                      letterSpacing: 1.2)),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.graphic_eq_rounded,
                title: 'AI Speech Bridge',
                subtitle: 'Real-time word intent prediction',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const BridgeActiveScreen())),
              ),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Targeted Practice',
                subtitle: 'Train your high-friction vocabulary',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const PracticeSession())),
              ),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.analytics_outlined,
                title: 'Clinical Analytics',
                subtitle: 'View progress & therapist reports',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TherapistStatScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.electricTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.electricTeal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppTheme.spaceNavy)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.spaceNavy.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }
}