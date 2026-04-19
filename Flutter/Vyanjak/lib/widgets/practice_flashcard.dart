import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';

class PracticeFlashcard extends StatelessWidget {
  final String imageUrl;
  final bool isLoading;

  const PracticeFlashcard({
    super.key,
    required this.imageUrl,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.spaceNavy.withOpacity(0.07),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: AppTheme.electricTeal,
            strokeWidth: 2.5,
          ),
        )
            : imageUrl.isEmpty
            ? Center(
          child: Icon(Icons.image_outlined,
              size: 72, color: AppTheme.electricTeal.withOpacity(0.4)),
        )
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
                child: CircularProgressIndicator(
                    color: AppTheme.electricTeal, strokeWidth: 2.5));
          },
          errorBuilder: (context, error, stack) => Center(
            child: Icon(Icons.broken_image_outlined,
                size: 72, color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}