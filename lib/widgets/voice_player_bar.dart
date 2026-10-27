import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_strings.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'audio_visualizer.dart';
import 'speed_scroll_selector.dart';
import 'system_voice_browser_dialog.dart';
import 'voice_control_sliders.dart';

class VoicePlayerBar extends StatefulWidget {
  final TtsService ttsService;
  final String textToSpeak;
  final VoidCallback? onSpeakRequested;
  final bool isArabic;

  const VoicePlayerBar({
    super.key,
    required this.ttsService,
    required this.textToSpeak,
    this.onSpeakRequested,
    this.isArabic = false,
  });

  @override
  State<VoicePlayerBar> createState() => _VoicePlayerBarState();
}

class _VoicePlayerBarState extends State<VoicePlayerBar> with SingleTickerProviderStateMixin {
  bool _showFineTuning = false;
  bool _showSpeedScroll = false;

  @override
  void initState() {
    super.initState();
    widget.ttsService.addListener(_onServiceChanged);
  }

  @override
  void didUpdateWidget(VoicePlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ttsService != widget.ttsService) {
      oldWidget.ttsService.removeListener(_onServiceChanged);
      widget.ttsService.addListener(_onServiceChanged);
    }
  }

  @override
  void dispose() {
    widget.ttsService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _toggleSpeed() {
    HapticFeedback.selectionClick();
    setState(() {
      _showSpeedScroll = !_showSpeedScroll;
      if (_showSpeedScroll) _showFineTuning = false;
    });
  }

  void _toggleFineTuning() {
    HapticFeedback.selectionClick();
    setState(() {
      _showFineTuning = !_showFineTuning;
      if (_showFineTuning) _showSpeedScroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final persona = widget.ttsService.currentPersona;
    final strings = AppStrings(isArabic: widget.isArabic);
    final isPlaying = widget.ttsService.isPlaying;
    final isPaused = widget.ttsService.isPaused;

    final displayName = widget.ttsService.selectedSystemVoice?['name'] ??
        (widget.isArabic ? persona.nameArabic : persona.name);
    final displayTag = widget.isArabic ? persona.tagArabic : persona.tag;

    final sayItText = isPlaying
        ? strings.pause
        : isPaused
            ? strings.resumePlayback
            : strings.sayIt;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withOpacity(0.85)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPlaying
                      ? persona.accentColor.withOpacity(0.4)
                      : isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                  width: isPlaying ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (isPlaying)
                    BoxShadow(
                      color: persona.accentColor.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated expansion drawers
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    child: Column(
                      children: [
                        if (_showSpeedScroll) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: SpeedScrollSelector(
                              currentRate: widget.ttsService.rate,
                              accentColor: persona.accentColor,
                              showSlider: true,
                              isArabic: widget.isArabic,
                              onRateChanged: (v) => widget.ttsService.setRate(v),
                            ),
                          ),
                          Divider(
                            height: 12,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ],
                        if (_showFineTuning) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: VoiceControlSliders(
                              pitch: widget.ttsService.pitch,
                              rate: widget.ttsService.rate,
                              volume: widget.ttsService.volume,
                              onPitchChanged: (v) => widget.ttsService.setPitch(v),
                              onRateChanged: (v) => widget.ttsService.setRate(v),
                              onVolumeChanged: (v) => widget.ttsService.setVolume(v),
                              onReset: () => widget.ttsService.applyPersona(widget.ttsService.currentPersona),
                            ),
                          ),
                          Divider(
                            height: 12,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Mini Waveform Visualizer & Spoken Word Indicator
                  if (isPlaying || isPaused) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: AudioVisualizer(
                              isPlaying: isPlaying,
                              isPaused: isPaused,
                              activeColor: persona.accentColor,
                              height: 22,
                              barCount: 26,
                            ),
                          ),
                          if (widget.ttsService.currentSpokenWord.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: persona.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.ttsService.currentSpokenWord,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: persona.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Main Interactive Mini-Player Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        // Left: Voice Persona Switcher Chip
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showDialog(
                                context: context,
                                builder: (c) => SystemVoiceBrowserDialog(ttsService: widget.ttsService),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: persona.accentColor.withOpacity(0.2),
                                    child: Icon(persona.icon, size: 14, color: persona.accentColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          displayTag,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.unfold_more_rounded,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Middle-1: Speed Pill Button
                        InkWell(
                          onTap: _toggleSpeed,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: _showSpeedScroll
                                  ? persona.accentColor.withOpacity(0.2)
                                  : isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showSpeedScroll
                                    ? persona.accentColor.withOpacity(0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.speed_rounded,
                                  size: 14,
                                  color: _showSpeedScroll ? persona.accentColor : theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.ttsService.rate.toStringAsFixed(1)}x',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _showSpeedScroll ? persona.accentColor : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Middle-2: Tune Button
                        IconButton(
                          tooltip: strings.adjustPitch,
                          padding: const EdgeInsets.all(7),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _showFineTuning ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _showFineTuning
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                          ),
                          onPressed: _toggleFineTuning,
                        ),
                        const SizedBox(width: 4),

                        // Optional Stop Button
                        if (isPlaying || isPaused) ...[
                          IconButton(
                            tooltip: strings.stop,
                            padding: const EdgeInsets.all(7),
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            icon: const Icon(Icons.stop_rounded, size: 16, color: AppColors.stop),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.stop.withOpacity(0.15),
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.ttsService.stop();
                            },
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Master Action Button (Play / Pause / Resume)
                        InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            if (widget.ttsService.isPlaying) {
                              widget.ttsService.pause();
                            } else {
                              if (widget.onSpeakRequested != null) {
                                widget.onSpeakRequested!();
                              } else {
                                widget.ttsService.speak(widget.textToSpeak);
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  persona.accentColor,
                                  persona.accentColor.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: persona.accentColor.withOpacity(isPlaying ? 0.5 : 0.3),
                                  blurRadius: isPlaying ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sayItText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
