import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _micGranted = false;
  bool _cameraGranted = false;
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    final mic = await Permission.microphone.request();
    final cam = await Permission.camera.request();
    setState(() {
      _micGranted = mic.isGranted;
      _cameraGranted = cam.isGranted;
      _isLoading = false;
    });
    if (mic.isGranted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to use Vyanjak.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Welcome to\nVyanjak',
                style: GoogleFonts.dancingScript(
                  color: AppTheme.spaceNavy,
                  fontSize: 62,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'A clinical-grade sanctuary for vocal health. Let\'s set up your environment.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textCharcoal.withOpacity(0.7), height: 1.6),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _PermissionTile(
                      icon: Icons.mic_rounded,
                      title: 'Microphone',
                      subtitle: 'Required — listens for speech intent.',
                      granted: _micGranted,
                    ),
                    const SizedBox(height: 14),
                    _PermissionTile(
                      icon: Icons.camera_alt_rounded,
                      title: 'Camera',
                      subtitle: 'Optional — visual context for better accuracy.',
                      granted: _cameraGranted,
                    ),
                    const SizedBox(height: 14),
                    _PermissionTile(
                      icon: Icons.sensors_rounded,
                      title: 'Motion Sensors',
                      subtitle: 'Detects frustration shake to assist faster.',
                      granted: true,
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                text: 'Initialize System',
                onPressed: _requestPermissions,
                isLoading: _isLoading,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppTheme.electricTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.electricTeal, size: 26),
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
          Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: granted ? AppTheme.electricTeal : Colors.grey.shade300,
            size: 22,
          ),
        ],
      ),
    );
  }
}