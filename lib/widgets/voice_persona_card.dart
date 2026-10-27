import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/voice_persona.dart';
import '../theme/app_theme.dart';

class VoicePersonaCard extends StatelessWidget {
  final VoicePersona persona;
  final bool isSelected;
  final bool isArabic;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const VoicePersonaCard({
    super.key,
    required this.persona,
    required this.isSelected,
    this.isArabic = false,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final genderLabel = switch (persona.gender) {
      VoiceGender.male => isArabic ? 'رجل' : 'Male',
      VoiceGender.female => isArabic ? 'امرأة' : 'Female',
      VoiceGender.neutral => isArabic ? 'آلي' : 'Synth',
    };

    final genderBgColor = switch (persona.gender) {
      VoiceGender.male => const Color(0xFF3B82F6).withOpacity(0.12),
      VoiceGender.female => const Color(0xFFEC4899).withOpacity(0.12),
      VoiceGender.neutral => const Color(0xFF10B981).withOpacity(0.12),
    };

    final genderTextColor = switch (persona.gender) {
      VoiceGender.male => const Color(0xFF60A5FA),
      VoiceGender.female => const Color(0xFFF472B6),
      VoiceGender.neutral => const Color(0xFF34D399),
    };

    final displayName = isArabic ? persona.nameArabic : persona.name;
    final displayTag = isArabic ? persona.tagArabic : persona.tag;
    final previewText = isArabic ? 'تجربة' : 'Sample';

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: AppSizes.personaCardWidth,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1B2234) : Colors.white)
              : (isDark ? const Color(0xFF161A26) : Colors.white),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    persona.accentColor.withOpacity(isDark ? 0.22 : 0.12),
                    isDark ? const Color(0xFF171C2B) : Colors.white,
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected
                ? persona.accentColor
                : (isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: persona.accentColor.withOpacity(0.32),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Avatar with glow + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar with accent glow ring
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: persona.accentColor.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: persona.accentColor.withOpacity(isSelected ? 0.8 : 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      persona.icon,
                      size: 17,
                      color: persona.accentColor,
                    ),
                  ),
                ),
                // Gender / Active pill
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: persona.accentColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: persona.accentColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 11, color: persona.accentColor),
                        const SizedBox(width: 3),
                        Text(
                          genderLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: persona.accentColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: genderBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      genderLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: genderTextColor,
                      ),
                    ),
                  ),
              ],
            ),

            // Middle: Name & Tag
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isSelected
                          ? (isDark ? Colors.white : persona.accentColor)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayTag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: Preview / Sample Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPreview();
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? persona.accentColor
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: persona.accentColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.85),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      previewText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
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
