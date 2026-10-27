import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_strings.dart';
import '../models/voice_persona.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_persona_selector.dart';

class TextInputTab extends StatefulWidget {
  final TextEditingController textController;
  final TtsService ttsService;
  final ValueChanged<String> onTextUpdated;
  final VoidCallback onTriggerSpeak;
  final bool isArabic;

  const TextInputTab({
    super.key,
    required this.textController,
    required this.ttsService,
    required this.onTextUpdated,
    required this.onTriggerSpeak,
    this.isArabic = false,
  });

  @override
  State<TextInputTab> createState() => _TextInputTabState();
}

class _TextInputTabState extends State<TextInputTab> {
  AppStrings get strings => AppStrings(isArabic: widget.isArabic);

  final List<Map<String, String>> _englishPresets = [
    {
      'title': '💡 Perseverance',
      'text':
          'Success is not final, failure is not fatal: it is the courage to continue that counts. Believe you can and you are halfway there.',
    },
    {
      'title': '🚀 AI & Future',
      'text':
          'Artificial intelligence and neural speech engines are transforming how humans and computers communicate across continents and languages.',
    },
    {
      'title': '☕ Morning Story',
      'text':
          'The morning sun broke through the golden horizon, warming the misty cobblestone streets as the aroma of freshly ground coffee drifted into the crisp air.',
    },
    {
      'title': '👅 Tongue Twister',
      'text':
          'She sells seashells by the seashore, and the shells she sells are seashells for sure. How much wood would a woodchuck chuck if a woodchuck could chuck wood?',
    },
  ];

  final List<Map<String, String>> _arabicPresets = [
    {
      'title': '📜 حكمة ملهمة',
      'text':
          'العلم يبني بيوتاً لا عماد لها، والجهل يهدم بيوت العز والشرف. لا تحسبن العلم ينفع وحده ما لم يتوج ربه بخلاق.',
    },
    {
      'title': '🚀 ثورة الذكاء الاصطناعي',
      'text':
          'تطور تقنيات الذكاء الاصطناعي وتحويل النصوص العربية والصور إلى أصوات بشرية طبيعية يفتح آفاقاً واسعة لمستقبل التعليم والمعرفة والتواصل الإنساني.',
    },
    {
      'title': '☕ إشراقة الصباح',
      'text':
          'تنفست الطبيعة في هذا الصباح المشرق بنسمات هادئة عليلة، وتفتحت أزهار الياسمين لتملأ الأفق بعبيرها الفواح وأمل يوم جديد مليء بالنجاح.',
    },
    {
      'title': '👅 تحدي النطق السريع',
      'text':
          'خيط حرير على حيط خليل. وقبر حرب بمكان قفر، وليس قرب قبر حرب قبر. شمس تمشي وشمس مشمسة.',
    },
  ];

  void _applySample(String sampleText) {
    HapticFeedback.lightImpact();
    widget.textController.text = sampleText;
    widget.onTextUpdated(sampleText);

    if (TtsService.isArabicString(sampleText) && !widget.isArabic) {
      widget.ttsService.applyPersona(VoicePersona.arabicPersonas[0]);
    }

    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.textController.text = data.text!;
      widget.onTextUpdated(data.text!);

      if (TtsService.isArabicString(data.text!)) {
        widget.ttsService.applyPersona(VoicePersona.arabicPersonas[0]);
      }

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Text(widget.isArabic ? 'تم لصق النص بنجاح' : 'Text pasted from clipboard'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    final text = widget.textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(widget.isArabic ? 'تم نسخ النص إلى الحافظة' : 'Text copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _clearText() {
    HapticFeedback.selectionClick();
    widget.textController.clear();
    widget.onTextUpdated('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtlText = TtsService.isArabicString(widget.textController.text) || widget.isArabic;
    final presets = widget.isArabic ? _arabicPresets : _englishPresets;
    final persona = widget.ttsService.currentPersona;

    final wordCount = widget.textController.text.trim().isEmpty
        ? 0
        : widget.textController.text.trim().split(RegExp(r'\s+')).length;
    final readingTimeSeconds = (wordCount / 2.5).ceil();
    final hasText = widget.textController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        AppSizes.playerBarClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instant Inspiration Presets Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    strings.instantSampleTexts,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: presets.map((preset) {
                    final isCurrent = widget.textController.text == preset['text'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => _applySample(preset['text']!),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isCurrent ? AppColors.primaryGradient : null,
                            color: isCurrent
                                ? null
                                : (isDark ? AppColors.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            preset['title']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? Colors.white
                                  : theme.colorScheme.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Hero Text Editor Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSizes.cardInset),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: hasText
                    ? AppColors.primary.withOpacity(0.35)
                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                width: hasText ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                if (hasText)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editor Header & Quick Toolbelt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.textToSpeak,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Copy button
                        if (hasText)
                          IconButton(
                            tooltip: 'Copy text',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onPressed: _copyToClipboard,
                          ),
                        // Paste button
                        IconButton(
                          tooltip: 'Paste from clipboard',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(
                            Icons.paste_rounded,
                            size: 16,
                            color: AppColors.primary.withOpacity(0.85),
                          ),
                          onPressed: _pasteFromClipboard,
                        ),
                        // Clear button
                        if (hasText)
                          IconButton(
                            tooltip: strings.clear,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.stop.withOpacity(0.7),
                            ),
                            onPressed: _clearText,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Text Input Area
                TextField(
                  controller: widget.textController,
                  maxLines: 7,
                  minLines: 4,
                  textDirection: isRtlText ? TextDirection.rtl : TextDirection.ltr,
                  onChanged: (val) {
                    widget.onTextUpdated(val);
                    setState(() {});
                  },
                  style: const TextStyle(fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: strings.textInputHint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkInput : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$wordCount ${widget.isArabic ? "كلمة" : "words"} • ${widget.textController.text.length} ${widget.isArabic ? "حرف" : "chars"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~$readingTimeSeconds${widget.isArabic ? "ث صوت" : "s voice"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Voice Persona Selection Carousel
          VoicePersonaSelector(
            ttsService: widget.ttsService,
            isArabic: widget.isArabic,
            strings: strings,
          ),
          const SizedBox(height: 14),

          // Primary Speak Action Card
          InkWell(
            onTap: !hasText
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onTriggerSpeak();
                  },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                gradient: hasText
                    ? LinearGradient(
                        colors: [persona.accentColor, persona.accentColor.withOpacity(0.85)],
                      )
                    : null,
                color: hasText
                    ? null
                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: persona.accentColor.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.ttsService.isPlaying
                        ? Icons.pause_rounded
                        : widget.ttsService.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.volume_up_rounded,
                    color: hasText ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.ttsService.isPlaying
                        ? strings.pausePlayback
                        : widget.ttsService.isPaused
                            ? strings.resumePlayback
                            : strings.speakNowButton(
                                widget.isArabic
                                    ? persona.nameArabic
                                    : persona.name,
                                persona.gender == VoiceGender.male
                                    ? strings.man
                                    : strings.woman,
                              ),
                    style: TextStyle(
                      color: hasText ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
