import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_strings.dart';
import '../models/speech_history_item.dart';
import '../models/voice_persona.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/history_bottom_sheet.dart';
import '../widgets/system_voice_browser_dialog.dart';
import '../widgets/voice_player_bar.dart';
import 'photo_ocr_tab.dart';
import 'text_input_tab.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _photoTextController = TextEditingController();
  final TextEditingController _manualTextController = TextEditingController();
  final TtsService _ttsService = TtsService();

  final List<SpeechHistoryItem> _history = [];
  bool _isArabic = false;

  AppStrings get strings => AppStrings(isArabic: _isArabic);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _ttsService.initialize();
    _ttsService.addListener(_onTtsUpdated);
  }

  void _onTtsUpdated() {
    if (mounted) setState(() {});
  }

  void _toggleLanguage() {
    HapticFeedback.lightImpact();
    setState(() {
      _isArabic = !_isArabic;
      _ttsService.setArabicMode(_isArabic);
    });
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsUpdated);
    _tabController.dispose();
    _photoTextController.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  String get _currentActiveText {
    if (_tabController.index == 0) {
      return _photoTextController.text;
    } else {
      return _manualTextController.text;
    }
  }

  Future<void> _speakCurrentText({HistorySourceType source = HistorySourceType.textInput}) async {
    if (_ttsService.isPaused) {
      await _ttsService.resume();
      return;
    }

    final text = _currentActiveText.trim();
    if (text.isEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(strings.enterTextAlert)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final personaName = _isArabic
        ? '${_ttsService.currentPersona.nameArabic} (${_ttsService.currentPersona.gender == VoiceGender.male ? strings.man : strings.woman})'
        : '${_ttsService.currentPersona.name} (${_ttsService.currentPersona.gender == VoiceGender.male ? "Man" : "Woman"})';

    // Save to history
    final historyItem = SpeechHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      voicePersonaName: personaName,
      source: source,
    );

    setState(() {
      _history.insert(0, historyItem);
      if (_history.length > 50) {
        _history.removeLast();
      }
    });

    await _ttsService.speak(text);
  }

  void _openHistorySheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryBottomSheet(
        items: _history,
        onClearAll: () {
          setState(() => _history.clear());
          Navigator.pop(context);
        },
        onSelect: (item) {
          Navigator.pop(context);
          if (_tabController.index == 0) {
            _photoTextController.text = item.text;
          } else {
            _manualTextController.text = item.text;
          }
          setState(() {});
          _speakCurrentText(source: item.source);
        },
      ),
    );
  }

  void _openSystemVoicesDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => SystemVoiceBrowserDialog(
        ttsService: _ttsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkSurface.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          titleSpacing: AppSizes.screenPadding,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            strings.appTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.secondary.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            strings.aiBadge,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      strings.appSubtitle,
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
            ],
          ),
          actions: [
            // Modern Animated Language Switcher Pill
            InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isArabic ? '🇸🇦' : '🇺🇸', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      _isArabic ? 'عربي' : 'EN',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // History with count badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: strings.history,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  onPressed: _openHistorySheet,
                ),
                if (_history.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${_history.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // More Options Menu (Consolidates Device Voices & Theme)
            PopupMenuButton<String>(
              tooltip: 'Options',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? AppColors.darkCard : Colors.white,
              onSelected: (value) {
                if (value == 'theme') {
                  HapticFeedback.selectionClick();
                  widget.onToggleTheme();
                } else if (value == 'voices') {
                  _openSystemVoicesDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'voices',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_voice_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Text(
                        strings.deviceVoices,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding, vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.65),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(strings.tabPhoto),
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(strings.tabText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Photo OCR to Speech
                PhotoOcrTab(
                  textController: _photoTextController,
                  ttsService: _ttsService,
                  isArabic: _isArabic,
                  onTextUpdated: (text) => setState(() {}),
                  onTriggerSpeak: () => _speakCurrentText(source: HistorySourceType.photo),
                ),

                // Tab 2: Direct Text to Speech
                TextInputTab(
                  textController: _manualTextController,
                  ttsService: _ttsService,
                  isArabic: _isArabic,
                  onTextUpdated: (text) => setState(() {}),
                  onTriggerSpeak: () => _speakCurrentText(source: HistorySourceType.textInput),
                ),
              ],
            ),

            // Bottom Gradient Fade so content scrolls smoothly under floating player
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withOpacity(0.0),
                        theme.scaffoldBackgroundColor.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Glassmorphic Voice Player Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VoicePlayerBar(
                ttsService: _ttsService,
                textToSpeak: _currentActiveText,
                isArabic: _isArabic,
                onSpeakRequested: _speakCurrentText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
