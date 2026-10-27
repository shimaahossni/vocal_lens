class AppStrings {
  final bool isArabic;

  const AppStrings({required this.isArabic});

  // App Bar
  String get appTitle => 'VocalLens';
  String get appSubtitle => isArabic
      ? 'تحويل الصور والنصوص إلى صوت بأصوات رجال ونساء'
      : 'Photo & Text Speech with Men & Women Sounds';
  String get aiBadge => isArabic ? 'ذكاء اصطناعي' : 'AI VOICE';

  // Tabs
  String get tabPhoto => isArabic ? 'صورة إلى صوت' : 'Photo to Speech';
  String get tabText => isArabic ? 'نص إلى صوت' : 'Text to Speech';

  // Actions
  String get takePhoto => isArabic ? 'التقاط صورة' : 'Take Photo';
  String get useCamera => isArabic ? 'الكاميرا' : 'Use Camera';
  String get choosePhoto => isArabic ? 'اختيار صورة' : 'Choose Photo';
  String get fromGallery => isArabic ? 'المعرض' : 'From Gallery';
  String get quickSamples => isArabic ? 'نماذج جاهزة للاختبار' : 'Quick Test Samples';
  String get tapToTest => isArabic ? 'اضغط لتجربة الصوت' : 'Tap to test OCR & Voice';

  // OCR
  String get recognizedText => isArabic ? 'النص المستخرج' : 'Recognized Text';
  String get extractingText => isArabic ? 'جاري استخراج النص من الصورة...' : 'Extracting text from photo...';
  String get ocrHint => isArabic
      ? 'النص المستخرج من الصورة سيظهر هنا. يمكنك التعديل والكتابة بحرية...'
      : 'Recognized text from photo appears here. You can also edit, paste, or type directly...';

  // Text Tab
  String get instantSampleTexts => isArabic ? 'نصوص جاهزة فورية' : 'Instant Sample Texts';
  String get textToSpeak => isArabic ? 'النص المراد نطقه' : 'Text to Speak';
  String get textInputHint => isArabic
      ? 'اكتب أو الصق أي نص هنا لسماعه بأصوات رجال ونساء عربية وإنجليزية...'
      : 'Type, paste, or pick any sample text here to hear it with men or women voices...';

  // Voice Selection
  String get selectVoiceTitle => isArabic
      ? 'اختر الصوت (أصوات رجال ونساء متعددة)'
      : 'Select Voice (Multiple Men & Women)';
  String get stylesAvailable => isArabic ? 'أنماط صوتية متاحة' : 'styles available';
  String get preview => isArabic ? 'معاينة' : 'Preview';
  String get speedScroll => isArabic ? 'سرعة النطق' : 'Voice Speed Scroll';
  String get speedSuffix => isArabic ? 'سرعة' : 'Speed';

  // Speak CTA
  String speakExtractedButton(String name, String gender) => isArabic
      ? 'انطق النص بصوت $name ($gender)'
      : 'Speak Extracted Text with $name ($gender)';

  String speakNowButton(String name, String gender) => isArabic
      ? 'انطق الآن بصوت $name ($gender)'
      : 'Speak Now with $name ($gender)';

  String get pausePlayback => isArabic ? 'إيقاف مؤقت' : 'Pause Playback';
  String get stop => isArabic ? 'إيقاف' : 'Stop';
  String get sayIt => isArabic ? 'انطق' : 'Say It';
  String get pause => isArabic ? 'إيقاف مؤقت' : 'Pause';
  String get resumePlayback => isArabic ? 'متابعة' : 'Resume';

  // Gender
  String get man => isArabic ? 'رجل' : 'Man';
  String get woman => isArabic ? 'امرأة' : 'Woman';
  String get synth => isArabic ? 'آلي' : 'Synth';

  // History & Dialogs
  String get history => isArabic ? 'سجل التسجيلات' : 'Speech History';
  String get deviceVoices => isArabic ? 'أصوات النظام المثبتة' : 'Device System Voices';
  String get noHistory => isArabic ? 'لا يوجد سجل بعد' : 'No speech history yet';
  String get clear => isArabic ? 'مسح' : 'Clear';
  String get copy => isArabic ? 'نسخ' : 'Copy';
  String get copied => isArabic ? 'تم النسخ إلى الحافظة!' : 'Copied to clipboard!';
  String get enterTextAlert => isArabic
      ? 'الرجاء اختيار صورة أو كتابة نص للنطق!'
      : 'Please select a photo or enter text to speak!';

  // Player Bar & Actions
  String get tapToChange => isArabic ? 'اضغط للتغيير' : 'Tap to change';
  String get adjustPitch => isArabic ? 'ضبط النبرة والسرعة' : 'Adjust Pitch & Speed';
  String speakingWord(String word) => isArabic ? 'يتم نطق: "$word"' : 'Speaking: "$word"';
  String get paste => isArabic ? 'لصق' : 'Paste from clipboard';
  String wordCountLabel(int words, int chars) => isArabic
      ? '$words كلمة • $chars حرف'
      : '$words words • $chars chars';
  String audioTimeLabel(int seconds) =>
      isArabic ? '~$secondsث تسجيل' : '~$seconds s audio';

  // Photo OCR Hub Strings
  String get scanHeroTitle => isArabic ? 'مسح مستند أو صورة' : 'Scan Document or Photo';
  String get scanHeroSubtitle => isArabic
      ? 'التقط صورة بكاميرا هاتفك أو اختر من المعرض لاستخراج النص وسماعه بصوت طبيعي'
      : 'Capture with your camera or pick from gallery to extract text & listen aloud';
  String get cameraScan => isArabic ? 'مسح بالكاميرا' : 'Camera Scanner';
  String get photoLibrary => isArabic ? 'معرض الصور' : 'Photo Library';
  String get browseFiles => isArabic ? 'تصفح الملفات' : 'Browse Files';
  String get orTryPreset => isArabic ? 'أو جرب نماذج فحص سريعة' : 'Or try instant sample documents';
  String get newScan => isArabic ? 'مسح جديد' : 'New Scan';
  String get rescan => isArabic ? 'إعادة الفحص' : 'Rescan';
  String get listenToText => isArabic ? 'استماع للنص' : 'Listen to Text';
  String get changeVoice => isArabic ? 'تغيير الصوت' : 'Change Voice';
}
