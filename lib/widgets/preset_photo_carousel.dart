import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/preset_demo_photo.dart';
import '../theme/app_theme.dart';

class PresetPhotoCarousel extends StatelessWidget {
  final ValueChanged<PresetDemoPhoto> onSelect;
  final String? selectedPresetId;
  final bool isArabic;

  const PresetPhotoCarousel({
    super.key,
    required this.onSelect,
    this.selectedPresetId,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final samples = PresetDemoPhoto.getSamples(isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, size: 14, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'نماذج سريعة للتجربة' : 'Quick OCR Samples',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                isArabic ? 'اضغط للتجربة الفورية' : '1-tap instant test',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: samples.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSizes.md),
            itemBuilder: (context, index) {
              final preset = samples[index];
              final isSelected = selectedPresetId == preset.id;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(preset);
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: AppSizes.presetCardWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl - 1),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.network(
                            preset.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? const Color(0xFF232938) : Colors.grey.shade300,
                              child: const Icon(Icons.image_rounded, size: 36),
                            ),
                          ),
                        ),
                        // Rich Gradient shadow
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.88),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Category Badge
                        Positioned(
                          top: 8,
                          left: isArabic ? null : 8,
                          right: isArabic ? 8 : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              preset.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        // Title and prompt
                        Positioned(
                          bottom: AppSizes.sm,
                          left: AppSizes.md,
                          right: AppSizes.md,
                          child: Column(
                            crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                    size: 12,
                                    color: isSelected ? Colors.greenAccent : Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSelected
                                        ? (isArabic ? 'تم التحميل' : 'Loaded')
                                        : (isArabic ? 'تجربة سريعة' : 'Tap to test'),
                                    style: TextStyle(
                                      color: isSelected ? Colors.greenAccent : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
