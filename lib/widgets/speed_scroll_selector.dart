import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeedPreset {
  final double rate;
  final String label;
  final String icon;

  const SpeedPreset({
    required this.rate,
    required this.label,
    required this.icon,
  });

  static const List<SpeedPreset> presets = [
    SpeedPreset(rate: 0.50, label: '0.50x', icon: '🐢'),
    SpeedPreset(rate: 0.75, label: '0.75x', icon: '☕'),
    SpeedPreset(rate: 0.90, label: '0.90x', icon: '📖'),
    SpeedPreset(rate: 1.00, label: '1.00x', icon: '✨'),
    SpeedPreset(rate: 1.15, label: '1.15x', icon: '🎙️'),
    SpeedPreset(rate: 1.25, label: '1.25x', icon: '⚡'),
    SpeedPreset(rate: 1.50, label: '1.50x', icon: '🏃'),
    SpeedPreset(rate: 1.75, label: '1.75x', icon: '🔥'),
    SpeedPreset(rate: 2.00, label: '2.00x', icon: '🚀'),
    SpeedPreset(rate: 2.50, label: '2.50x', icon: '🏎️'),
    SpeedPreset(rate: 3.00, label: '3.00x', icon: '🛸'),
    SpeedPreset(rate: 4.00, label: '4.00x', icon: '⚡'),
    SpeedPreset(rate: 5.00, label: '5.00x', icon: '🌌'),
  ];
}

class SpeedScrollSelector extends StatelessWidget {
  final double currentRate;
  final ValueChanged<double> onRateChanged;
  final Color accentColor;
  final bool showSlider;
  final bool isArabic;

  const SpeedScrollSelector({
    super.key,
    required this.currentRate,
    required this.onRateChanged,
    this.accentColor = const Color(0xFF6366F1),
    this.showSlider = true,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with active speed readout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.speed_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isArabic ? 'سرعة النطق' : 'Voice Speed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (currentRate - 1.00).abs() < 0.04
                    ? (isArabic ? '1.00x سرعة طبيعية ✨' : '1.00x Natural ✨')
                    : '${currentRate.toStringAsFixed(2)}x',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal Scrollable Speed Presets Dial
        SizedBox(
          height: AppSizes.xxl + AppSizes.lg, // 40 — 4pt grid
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SpeedPreset.presets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = SpeedPreset.presets[index];
              final isSelected = (currentRate - preset.rate).abs() < 0.06;
              final isDefaultNormal = (preset.rate - 1.00).abs() < 0.01;

              return InkWell(
                onTap: () => onRateChanged(preset.rate),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : (isDark ? const Color(0xFF1E2433) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : isDefaultNormal
                              ? accentColor.withOpacity(0.4)
                              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                      width: isSelected ? 1.5 : (isDefaultNormal ? 1.2 : 1),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isSelected || isDefaultNormal) ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Continuous Slider Wheel
        if (showSlider) ...[
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.15),
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: currentRate.clamp(0.25, 5.0),
              min: 0.25,
              max: 5.0,
              divisions: 95,
              onChanged: onRateChanged,
            ),
          ),
        ],
      ],
    );
  }
}
