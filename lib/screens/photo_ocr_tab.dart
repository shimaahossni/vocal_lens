import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/app_strings.dart';
import '../models/preset_demo_photo.dart';
import '../models/voice_persona.dart';
import '../services/ocr_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/preset_photo_carousel.dart';
import '../widgets/voice_persona_selector.dart';

class PhotoOcrTab extends StatefulWidget {
  final TextEditingController textController;
  final TtsService ttsService;
  final ValueChanged<String> onTextUpdated;
  final VoidCallback onTriggerSpeak;
  final bool isArabic;

  const PhotoOcrTab({
    super.key,
    required this.textController,
    required this.ttsService,
    required this.onTextUpdated,
    required this.onTriggerSpeak,
    this.isArabic = false,
  });

  @override
  State<PhotoOcrTab> createState() => _PhotoOcrTabState();
}

class _PhotoOcrTabState extends State<PhotoOcrTab> with SingleTickerProviderStateMixin {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedPresetId;
  String? _lastFilePath;
  bool _isProcessingOcr = false;
  Duration? _lastOcrDuration;

  late AnimationController _scanAnimationController;

  AppStrings get strings => AppStrings(isArabic: widget.isArabic);

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  void _startScanningAnimation() {
    _scanAnimationController.repeat(reverse: true);
  }

  void _stopScanningAnimation() {
    _scanAnimationController.stop();
    _scanAnimationController.reset();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
          _selectedPresetId = null;
          _lastFilePath = file.path;
        });

        await _processOcr(bytes: bytes, filePath: file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isArabic ? 'تعذر فتح الكاميرا/المعرض: $e' : 'Could not access camera/gallery: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickFromFilePicker() async {
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes ?? await file.xFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
          _selectedPresetId = null;
          _lastFilePath = file.path;
        });

        await _processOcr(bytes: bytes, filePath: file.path);
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  Future<void> _loadPreset(PresetDemoPhoto preset) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetId = preset.id;
      _selectedImageName = preset.title;
      _isProcessingOcr = true;
    });
    _startScanningAnimation();

    try {
      final response = await http.get(Uri.parse(preset.imageUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _selectedImageBytes = response.bodyBytes;
          _lastFilePath = null;
        });
      }
    } catch (e) {
      debugPrint("Failed to load preset image: $e");
    }

    widget.textController.text = preset.extractedText;
    widget.onTextUpdated(preset.extractedText);

    // If preset is Arabic, auto-switch to Arabic voice if needed
    if (preset.isArabic && !widget.isArabic) {
      widget.ttsService.applyPersona(VoicePersona.arabicPersonas[0]);
    }

    _stopScanningAnimation();
    if (mounted) {
      setState(() {
        _isProcessingOcr = false;
        _lastOcrDuration = const Duration(milliseconds: 320);
      });
    }
  }

  Future<void> _processOcr({required Uint8List bytes, String? filePath}) async {
    setState(() {
      _isProcessingOcr = true;
    });
    _startScanningAnimation();

    try {
      OcrResult result;
      if (!kIsWeb && filePath != null && filePath.isNotEmpty && _ocrService.isMlKitSupported) {
        result = await _ocrService.recognizeTextFromPath(filePath);
      } else {
        result = await _ocrService.recognizeTextFromBytes(bytes);
      }

      if (result.isSuccess && result.text.isNotEmpty) {
        widget.textController.text = result.text;
        widget.onTextUpdated(result.text);

        // Auto-select Arabic voice if detected text is Arabic
        if (TtsService.isArabicString(result.text)) {
          widget.ttsService.applyPersona(VoicePersona.arabicPersonas[0]);
        }

        if (mounted) {
          setState(() {
            _lastOcrDuration = result.processingTime;
          });
        }
      }
    } catch (e) {
      debugPrint("OCR processing error: $e");
    } finally {
      _stopScanningAnimation();
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  void _clearImageAndText() {
    HapticFeedback.lightImpact();
    _stopScanningAnimation();
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedPresetId = null;
      _lastFilePath = null;
      _lastOcrDuration = null;
      _isProcessingOcr = false;
    });
    widget.textController.clear();
    widget.onTextUpdated('');
  }

  void _rescanCurrentPhoto() {
    if (_selectedImageBytes != null) {
      _processOcr(bytes: _selectedImageBytes!, filePath: _lastFilePath);
    }
  }

  void _openVoicePickerSheet() {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141824) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            VoicePersonaSelector(
              ttsService: widget.ttsService,
              isArabic: widget.isArabic,
              strings: strings,
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _selectedImageBytes != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        AppSizes.playerBarClearance,
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 280),
        crossFadeState: hasPhoto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildEmptyStateView(context),
        secondChild: hasPhoto ? _buildActivePhotoView(context) : const SizedBox.shrink(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. EMPTY / WELCOME STATE: Clean, professional scanner hub
  // ─────────────────────────────────────────────────────────────
  Widget _buildEmptyStateView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Scanner Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161A26) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Scanner Glowing Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                strings.scanHeroTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  strings.scanHeroSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons: Camera (Primary) & Gallery (Secondary)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        strings.cameraScan,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        strings.photoLibrary,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Browse Files subtle button
              TextButton.icon(
                onPressed: _pickFromFilePicker,
                icon: Icon(Icons.folder_open_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                label: Text(
                  strings.browseFiles,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sectionGap),

        // Quick OCR Preset Test Samples
        PresetPhotoCarousel(
          selectedPresetId: _selectedPresetId,
          isArabic: widget.isArabic,
          onSelect: _loadPreset,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. ACTIVE STATE: Photo Preview + Extracted Text + Quick Listen
  // ─────────────────────────────────────────────────────────────
  Widget _buildActivePhotoView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtlText = TtsService.isArabicString(widget.textController.text) || widget.isArabic;
    final wordCount = widget.textController.text.trim().isEmpty
        ? 0
        : widget.textController.text.trim().split(RegExp(r'\s+')).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Photo Preview Card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: [
                if (_selectedImageBytes != null)
                  Image.memory(
                    _selectedImageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                // Top Header Pill with file name & action buttons
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _selectedImageName ?? (widget.isArabic ? 'صورة المستند' : 'Document Image'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Top Action Pills: Rescan & New Scan
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _rescanCurrentPhoto,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.72),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.rescan,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _clearImageAndText,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.72),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    strings.newScan,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Animated Laser Scanning Beam overlay when OCR is in progress
                if (_isProcessingOcr)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _scanAnimationController,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(0, (_scanAnimationController.value * 2) - 1),
                                child: Container(
                                  height: 3,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF38BDF8),
                                        Color(0xFF818CF8),
                                        Color(0xFF38BDF8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strings.extractingText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Extracted Text Card & Direct Audio Playback
        Container(
          padding: const EdgeInsets.all(AppSizes.cardInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161A26) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title, Duration Badge & Copy Tool
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            strings.recognizedText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_lastOcrDuration != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '⚡ ${_lastOcrDuration!.inMilliseconds}ms',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Quick Tools: Copy & Clear
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        tooltip: strings.copy,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (widget.textController.text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: widget.textController.text));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.copied),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      if (widget.textController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 17),
                          tooltip: strings.clear,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            widget.textController.clear();
                            widget.onTextUpdated('');
                            HapticFeedback.selectionClick();
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Editable text box
              TextField(
                controller: widget.textController,
                maxLines: 6,
                minLines: 3,
                textDirection: isRtlText ? TextDirection.rtl : TextDirection.ltr,
                onChanged: (val) {
                  widget.onTextUpdated(val);
                  setState(() {});
                },
                style: const TextStyle(fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  hintText: strings.ocrHint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF10131D) : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(AppSizes.lg),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Word / Char Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$wordCount ${widget.isArabic ? "كلمة" : "words"} • ${widget.textController.text.length} ${widget.isArabic ? "حرف" : "chars"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (wordCount > 0)
                    Text(
                      '~${(wordCount / 2.5).ceil()} ${widget.isArabic ? "ثانية قراءة" : "sec read"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Unified Single Audio Action Bar: Quick Voice Pill + Direct Listen CTA
              Row(
                children: [
                  // Voice Selector Chip (Tapping opens voice sheet modal)
                  InkWell(
                    onTap: _openVoicePickerSheet,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: widget.ttsService.currentPersona.accentColor.withOpacity(isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.ttsService.currentPersona.accentColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.ttsService.currentPersona.icon,
                            size: 15,
                            color: widget.ttsService.currentPersona.accentColor,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              widget.isArabic
                                  ? widget.ttsService.currentPersona.nameArabic
                                  : widget.ttsService.currentPersona.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Direct Listen CTA (Focuses & Drives the Floating Player seamlessly)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.textController.text.trim().isEmpty ? null : widget.onTriggerSpeak,
                      icon: Icon(
                        widget.ttsService.isPlaying
                            ? Icons.pause_rounded
                            : widget.ttsService.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.volume_up_rounded,
                        size: 17,
                      ),
                      label: Text(
                        widget.ttsService.isPlaying
                            ? strings.pause
                            : widget.ttsService.isPaused
                                ? strings.resumePlayback
                                : strings.listenToText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.ttsService.currentPersona.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
