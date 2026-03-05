// lib/screens/ai_meal_capture_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../generated/app_localizations.dart';
import '../services/ai_service.dart';
import '../widgets/global_app_bar.dart';
import 'ai_meal_review_screen.dart';
import 'ai_settings_screen.dart';

/// Screen for capturing meal input via photo(s), voice, or text before AI analysis.
///
/// Minimalist design — AI gradient is concentrated only on the primary
/// "Analyze" CTA button. All other UI elements use standard theme colours.
class AiMealCaptureScreen extends StatefulWidget {
  const AiMealCaptureScreen({super.key});

  @override
  State<AiMealCaptureScreen> createState() => _AiMealCaptureScreenState();
}

class _AiMealCaptureScreenState extends State<AiMealCaptureScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Input mode: 0 = photo, 1 = voice, 2 = text
  int _selectedMode = 0;

  // Photo state
  final List<File> _images = [];
  static const int _maxImages = 4;

  // Voice state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceText = '';

  // Analysis state
  bool _isAnalyzing = false;

  // Single animation controller for pulse (mic) and shimmer (button loading)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo actions
  // ---------------------------------------------------------------------------

  Future<void> _takePhoto() async {
    if (_images.length >= _maxImages) return;
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (photo != null && mounted) {
      setState(() => _images.add(File(photo.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _images.addAll(
          picked.take(remaining).map((x) => File(x.path)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ---------------------------------------------------------------------------
  // Voice actions
  // ---------------------------------------------------------------------------

  void _toggleListening() {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Detect locale for speech recognition (e.g. 'de_DE' for German)
      final locale = Localizations.localeOf(context);
      final localeId =
          '${locale.languageCode}_${locale.countryCode ?? locale.languageCode.toUpperCase()}';

      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _voiceText = result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      setState(() => _isListening = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  bool get _hasInput {
    switch (_selectedMode) {
      case 0:
        return _images.isNotEmpty;
      case 1:
        return _voiceText.trim().isNotEmpty;
      case 2:
        return _textController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _analyze() async {
    if (!_hasInput) return;
    setState(() => _isAnalyzing = true);

    // Pass the current app language so the AI returns localised food names
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      List<AiSuggestedItem> results;

      switch (_selectedMode) {
        case 0: // Photo
          results = await AiService.instance.analyzeImages(
            _images,
            textHint: _textController.text.trim().isNotEmpty
                ? _textController.text.trim()
                : null,
            languageCode: languageCode,
          );
          break;
        case 1: // Voice
          results = await AiService.instance
              .analyzeText(_voiceText, languageCode: languageCode);
          break;
        case 2: // Text
          results = await AiService.instance.analyzeText(
            _textController.text.trim(),
            languageCode: languageCode,
          );
          break;
        default:
          return;
      }

      if (!mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AiMealReviewScreen(
            suggestions: results,
            originalImages: _images,
          ),
        ),
      );
      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AiKeyMissingException {
      if (!mounted) return;
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showKeyMissingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key Required'),
        content: Text(l10n.aiErrorNoKey),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              );
            },
            child: Text(l10n.aiSettingsTitle),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.aiCaptureTitle),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Segmented input toggle (standard themed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ThemedSegmentedToggle(
              selectedIndex: _selectedMode,
              labels: [
                l10n.aiCaptureTabPhoto,
                l10n.aiCaptureTabVoice,
                l10n.aiCaptureTabText,
              ],
              icons: const [
                Icons.camera_alt_rounded,
                Icons.mic_rounded,
                Icons.edit_rounded,
              ],
              onChanged: (i) => setState(() => _selectedMode = i),
            ),
          ),

          const SizedBox(height: 20),

          // Tab content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_selectedMode),
                child: _selectedMode == 0
                    ? _buildPhotoContent(l10n, theme, isDark)
                    : _selectedMode == 1
                        ? _buildVoiceContent(l10n, theme, isDark)
                        : _buildTextContent(l10n, theme, isDark),
              ),
            ),
          ),

          // Analyze button — AI gradient CTA with inline loading
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: _AiAnalyzeButton(
              onPressed: (_hasInput && !_isAnalyzing) ? _analyze : null,
              isAnalyzing: _isAnalyzing,
              l10n: l10n,
              pulseController: _pulseController,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content: Photo
  // ---------------------------------------------------------------------------

  Widget _buildPhotoContent(
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    // Show empty-state placeholder when no images are added
    if (_images.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_outlined,
        text: l10n.aiCapturePhotoHint,
        theme: theme,
        actionRow: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l10n.aiCaptureTabPhoto),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(l10n.tabFavorites),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Photo grid
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _buildPhotoThumbnail(i, theme),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _images.length < _maxImages ? _takePhoto : null,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(l10n.aiCaptureTabPhoto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _images.length < _maxImages ? _pickFromGallery : null,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(l10n.tabFavorites),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_images.length} / $_maxImages',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index, ThemeData theme) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _images[index],
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Content: Voice
  // ---------------------------------------------------------------------------

  Widget _buildVoiceContent(
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    // Show empty-state when voice has not been used yet
    if (_voiceText.isEmpty && !_isListening) {
      return _buildEmptyState(
        icon: Icons.mic_none_rounded,
        text: l10n.aiCaptureVoiceHint,
        theme: theme,
        actionRow: ElevatedButton.icon(
          onPressed: _speechAvailable ? _toggleListening : null,
          icon: const Icon(Icons.mic_rounded),
          label: Text(l10n.aiCaptureTabVoice),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Standard microphone button
          GestureDetector(
            onTap: _speechAvailable ? _toggleListening : null,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    _isListening ? 1.0 + (_pulseController.value * 0.08) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 36,
                      color: _isListening
                          ? theme.colorScheme.onError
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                );
              },
            ),
          ),

          if (!_speechAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Speech recognition not available',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),

          const SizedBox(height: 24),

          // Transcription display
          if (_voiceText.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _voiceText,
                        style: theme.textTheme.bodyLarge,
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

  // ---------------------------------------------------------------------------
  // Content: Text
  // ---------------------------------------------------------------------------

  Widget _buildTextContent(
      AppLocalizations l10n, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: l10n.aiCaptureTextHint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  /// Builds a centered empty-state placeholder with a faded icon, helper text,
  /// and an optional action row (e.g. buttons to take photo / start recording).
  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    required ThemeData theme,
    Widget? actionRow,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            if (actionRow != null) ...[
              const SizedBox(height: 24),
              actionRow,
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Standard themed segmented toggle (no gradient)
// =============================================================================

class _ThemedSegmentedToggle extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onChanged;

  const _ThemedSegmentedToggle({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              // Animated selection indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Tap targets
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChanged(i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 18,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// AI Analyze button — gradient CTA with inline animated shimmer loading
// =============================================================================

/// The AI gradient colours used for the analyze button and entry-point accents.
const _aiGradientColors = [
  Color(0xFFE88DCC),
  Color(0xFFF4A77A),
  Color(0xFFF7D06B),
  Color(0xFF7DDEAE),
  Color(0xFF6DC8D9),
];

class _AiAnalyzeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isAnalyzing;
  final AppLocalizations l10n;
  final AnimationController pulseController;

  const _AiAnalyzeButton({
    required this.onPressed,
    required this.isAnalyzing,
    required this.l10n,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || isAnalyzing;
    final theme = Theme.of(context);

    // Base button content (icon + text)
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isAnalyzing)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else
          Icon(
            Icons.auto_awesome_rounded,
            size: 24,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 10),
        Text(
          isAnalyzing ? l10n.aiAnalyzing : l10n.aiAnalyzeButton,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    if (!enabled) {
      // Disabled state — flat, no gradient
      return GestureDetector(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: buttonContent,
        ),
      );
    }

    // Enabled / analysing — gradient background with text on top via Stack
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, _) {
          final t = pulseController.value;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isAnalyzing
                  ? LinearGradient(
                      begin: Alignment(-1.0 + (t * 4.0), 0),
                      end: Alignment(1.0 + (t * 4.0), 0),
                      colors: const [
                        Color(0xFFE88DCC),
                        Color(0xFFF4A77A),
                        Color(0xFFF7D06B),
                        Color(0xFF7DDEAE),
                        Color(0xFF6DC8D9),
                        Color(0xFFE88DCC),
                      ],
                      tileMode: TileMode.repeated,
                    )
                  : const LinearGradient(
                      colors: _aiGradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE88DCC).withValues(alpha: 0.30),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: buttonContent,
          );
        },
      ),
    );
  }
}
