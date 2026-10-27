import 'package:flutter/material.dart';
import '../models/app_strings.dart';
import '../models/voice_persona.dart';
import '../services/tts_service.dart';
import 'voice_persona_card.dart';
import '../theme/app_theme.dart';

class VoicePersonaSelector extends StatelessWidget {
  final TtsService ttsService;
  final bool isArabic;
  final AppStrings strings;

  const VoicePersonaSelector({
    super.key,
    required this.ttsService,
    required this.isArabic,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final personas = isArabic ? VoicePersona.arabicPersonas : VoicePersona.englishPersonas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.spatial_audio_rounded, size: AppSizes.iconSm, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSizes.sm),
                  Flexible(
                    child: Text(
                      strings.selectVoiceTitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontMdLg,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              '${personas.length} ${strings.stylesAvailable}',
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        SizedBox(
          height: AppSizes.personaCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: personas.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSizes.lg),
            itemBuilder: (context, index) {
              final persona = personas[index];
              final isSelected = ttsService.currentPersona.id == persona.id;

              return VoicePersonaCard(
                persona: persona,
                isSelected: isSelected,
                isArabic: isArabic,
                onSelect: () => ttsService.applyPersona(persona),
                onPreview: () async {
                  await ttsService.applyPersona(persona);
                  await ttsService.speak(persona.getPreviewText(isArabic: isArabic));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
