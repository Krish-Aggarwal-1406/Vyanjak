import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/frosted_card.dart';
import '../bridge_mode/bridge_active_screen.dart';
import '../practice_mode/practice_session.dart';
import '../analytics/therapist_stat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                      Text('Good Morning,',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textCharcoal.withOpacity(0.6))),
                      Text('Ravi',
                          style: Theme.of(context).textTheme.displayMedium),
                    ],
                  ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.electricTeal.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppTheme.spaceNavy, size: 26),
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
                            value: 0.82,
                            strokeWidth: 7,
                            backgroundColor: AppTheme.spaceNavy.withOpacity(0.06),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(AppTheme.electricTeal),
                          ),
                          Center(
                            child: Text('82%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
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
                          Text('Strong recovery pacing today.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Modes',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.textCharcoal.withOpacity(0.5), fontSize: 13, letterSpacing: 1.2)),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.graphic_eq_rounded,
                title: 'AI Speech Bridge',
                subtitle: 'Real-time word intent prediction',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BridgeActiveScreen())),
              ),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Targeted Practice',
                subtitle: 'Train your high-friction vocabulary',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PracticeSession())),
              ),
              const SizedBox(height: 14),
              _DashboardTile(
                icon: Icons.analytics_outlined,
                title: 'Clinical Analytics',
                subtitle: 'View progress & therapist reports',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TherapistStatScreen())),
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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