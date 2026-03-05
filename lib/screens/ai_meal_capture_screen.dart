// lib/screens/ai_meal_capture_screen.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

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
/// Features an animated AI-themed background and glassmorphic input toggle.
class AiMealCaptureScreen extends StatefulWidget {
  const AiMealCaptureScreen({super.key});

  @override
  State<AiMealCaptureScreen> createState() => _AiMealCaptureScreenState();
}

class _AiMealCaptureScreenState extends State<AiMealCaptureScreen>
    with TickerProviderStateMixin {
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

  // Animation controllers — coprime durations avoid visible reset
  late AnimationController _aura1Controller; // orbs 1 & 2
  late AnimationController _aura2Controller; // orbs 3 & 4
  late AnimationController _aura3Controller; // orb 5
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _aura1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat();
    _aura2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 17),
    )..repeat();
    _aura3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 23),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
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
    _aura1Controller.dispose();
    _aura2Controller.dispose();
    _aura3Controller.dispose();
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

    try {
      List<AiSuggestedItem> results;

      switch (_selectedMode) {
        case 0: // Photo
          results = await AiService.instance.analyzeImages(
            _images,
            textHint: _textController.text.trim().isNotEmpty
                ? _textController.text.trim()
                : null,
          );
          break;
        case 1: // Voice
          results = await AiService.instance.analyzeText(_voiceText);
          break;
        case 2: // Text
          results = await AiService.instance.analyzeText(
            _textController.text.trim(),
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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiCaptureTitle),
      body: Stack(
        children: [
          // Animated AI aura background
          _AnimatedAuraBackground(
            aura1Controller: _aura1Controller,
            aura2Controller: _aura2Controller,
            aura3Controller: _aura3Controller,
            pulseController: _pulseController,
            isDark: isDark,
            isAnalyzing: _isAnalyzing,
          ),

          // Main content
          Column(
            children: [
              SizedBox(height: topPadding + 8),

              // Glassmorphic input toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _GlassSegmentedToggle(
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
                  isDark: isDark,
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

              // Analyze button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: _GlassAnalyzeButton(
                  onPressed: (_hasInput && !_isAnalyzing) ? _analyze : null,
                  isAnalyzing: _isAnalyzing,
                  isDark: isDark,
                  l10n: l10n,
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isAnalyzing)
            _AnalyzingOverlay(
              isDark: isDark,
              l10n: l10n,
              theme: theme,
              pulseController: _pulseController,
              spinController: _aura1Controller,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Hint text
          _buildHintText(l10n.aiCapturePhotoHint, theme),
          const SizedBox(height: 16),

          // Photo grid
          if (_images.isNotEmpty)
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _buildPhotoThumbnail(i, isDark),
              ),
            ),

          if (_images.isNotEmpty) const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _GlassActionButton(
                  onPressed: _images.length < _maxImages ? _takePhoto : null,
                  icon: Icons.camera_alt_rounded,
                  label: l10n.aiCaptureTabPhoto,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassActionButton(
                  onPressed:
                      _images.length < _maxImages ? _pickFromGallery : null,
                  icon: Icons.photo_library_rounded,
                  label: l10n.tabFavorites,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          if (_images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_images.length} / $_maxImages',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index, bool isDark) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE88DCC).withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildHintText(l10n.aiCaptureVoiceHint, theme),
          const SizedBox(height: 32),

          // Animated microphone button
          GestureDetector(
            onTap: _speechAvailable ? _toggleListening : null,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    _isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isListening
                            ? [const Color(0xFFFF5252), const Color(0xFFD50000)]
                            : [
                                const Color(0xFFE88DCC),
                                const Color(0xFFF4A77A),
                                const Color(0xFFF7D06B),
                                const Color(0xFF7DDEAE),
                                const Color(0xFF6DC8D9),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFFE88DCC))
                              .withValues(
                                  alpha: 0.4 + (_pulseController.value * 0.2)),
                          blurRadius: 24 + (_pulseController.value * 16),
                          spreadRadius: _isListening ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 42,
                      color: Colors.white,
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
            _buildGlassCard(
              isDark: isDark,
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
          _buildGlassCard(
            isDark: isDark,
            child: TextField(
              controller: _textController,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.aiCaptureTextHint,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
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

  Widget _buildHintText(String text, ThemeData theme) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        height: 1.4,
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// Animated AI aura background
// =============================================================================

class _AnimatedAuraBackground extends StatelessWidget {
  final AnimationController aura1Controller;
  final AnimationController aura2Controller;
  final AnimationController aura3Controller;
  final AnimationController pulseController;
  final bool isDark;
  final bool isAnalyzing;

  const _AnimatedAuraBackground({
    required this.aura1Controller,
    required this.aura2Controller,
    required this.aura3Controller,
    required this.pulseController,
    required this.isDark,
    required this.isAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        aura1Controller,
        aura2Controller,
        aura3Controller,
        pulseController,
      ]),
      builder: (context, _) {
        // Each controller completes exactly one full circle → seamless loop
        // Combined pattern repeats after 13*17*23 = 5083 seconds ≈ 85 minutes
        final a1 = aura1Controller.value * 2 * math.pi;
        final a2 = aura2Controller.value * 2 * math.pi;
        final a3 = aura3Controller.value * 2 * math.pi;
        final pulse = 0.85 + (pulseController.value * 0.3);
        final baseAlpha = isAnalyzing ? 0.50 : 0.35;

        return Stack(
          children: [
            // Orb 1: Hot pink / magenta (top-right) — a1 (13s)
            Positioned(
              top: -40 + math.sin(a1) * 40,
              right: -100 + math.cos(a1) * 30,
              child: Container(
                width: 420 * pulse,
                height: 420 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6EC7).withValues(alpha: baseAlpha),
                      const Color(0xFFD946EF)
                          .withValues(alpha: baseAlpha * 0.5),
                      const Color(0xFFD946EF).withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Orb 2: Cyan / turquoise (bottom-left) — a1 reversed (13s)
            Positioned(
              bottom: 80 + math.cos(a1) * 50,
              left: -80 + math.sin(a1) * 35,
              child: Container(
                width: 400 * pulse,
                height: 400 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: baseAlpha),
                      const Color(0xFF06B6D4)
                          .withValues(alpha: baseAlpha * 0.5),
                      const Color(0xFF06B6D4).withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Orb 3: Warm orange / yellow (center) — a2 (17s)
            Positioned(
              top: 200 + math.sin(a2) * 60,
              right: -30 + math.cos(a2) * 45,
              child: Container(
                width: 350 * pulse,
                height: 350 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFBBF24)
                          .withValues(alpha: baseAlpha * 0.9),
                      const Color(0xFFF97316)
                          .withValues(alpha: baseAlpha * 0.4),
                      const Color(0xFFF97316).withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Orb 4: Deep purple (bottom-right) — a2 reversed (17s)
            Positioned(
              bottom: -30 + math.cos(a2) * 35,
              right: -60 + math.sin(a2) * 45,
              child: Container(
                width: 320 * pulse,
                height: 320 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA855F7)
                          .withValues(alpha: baseAlpha * 0.7),
                      const Color(0xFF7C3AED).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Orb 5: Emerald green (mid-left) — a3 (23s)
            Positioned(
              top: 400 + math.cos(a3) * 40,
              left: -60 + math.sin(a3) * 50,
              child: Container(
                width: 280 * pulse,
                height: 280 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF34D399)
                          .withValues(alpha: baseAlpha * 0.7),
                      const Color(0xFF10B981)
                          .withValues(alpha: baseAlpha * 0.3),
                      const Color(0xFF10B981).withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Glassmorphic segmented toggle
// =============================================================================

class _GlassSegmentedToggle extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _GlassSegmentedToggle({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              width: 1.2,
            ),
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
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFE88DCC),
                            Color(0xFFF4A77A),
                            Color(0xFFF7D06B),
                            Color(0xFF7DDEAE),
                            Color(0xFF6DC8D9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE88DCC).withValues(alpha: 0.25),
                            blurRadius: 14,
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
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black45),
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
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white60
                                          : Colors.black45),
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
        ),
      ),
    );
  }
}

// =============================================================================
// Glassmorphic analyze button (with sparkle)
// =============================================================================

class _GlassAnalyzeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isAnalyzing;
  final bool isDark;
  final AppLocalizations l10n;

  const _GlassAnalyzeButton({
    required this.onPressed,
    required this.isAnalyzing,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE88DCC),
                    Color(0xFFF4A77A),
                    Color(0xFFF7D06B),
                    Color(0xFF7DDEAE),
                    Color(0xFF6DC8D9),
                  ],
                )
              : null,
          color: enabled ? null : (isDark ? Colors.white12 : Colors.black12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFE88DCC).withValues(alpha: 0.30),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
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
                color: enabled ? Colors.white : Colors.white38,
              ),
            const SizedBox(width: 10),
            Text(
              isAnalyzing ? l10n.aiAnalyzing : l10n.aiAnalyzeButton,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Glassmorphic action button (camera / gallery)
// =============================================================================

class _GlassActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isDark;

  const _GlassActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.10 : 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? (isDark ? Colors.white70 : Colors.black54)
                      : Colors.white24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? (isDark ? Colors.white70 : Colors.black54)
                        : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Analysis loading overlay
// =============================================================================

class _AnalyzingOverlay extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final ThemeData theme;
  final AnimationController pulseController;
  final AnimationController spinController;

  const _AnalyzingOverlay({
    required this.isDark,
    required this.l10n,
    required this.theme,
    required this.pulseController,
    required this.spinController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, spinController]),
      builder: (context, _) {
        final spin = spinController.value * 2 * math.pi;
        final pulse = pulseController.value;

        // Cycle through pastel rainbow for the icon
        final iconColor = HSLColor.fromAHSL(
          1.0,
          (spinController.value * 360) % 360,
          0.55,
          0.70,
        ).toColor();

        return Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rotating gradient ring + pulsing icon
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Rotating ring
                            Transform.rotate(
                              angle: spin,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      const Color(0xFFE88DCC)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFFF4A77A)
                                          .withValues(alpha: 0.6),
                                      const Color(0xFFF7D06B)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF7DDEAE)
                                          .withValues(alpha: 0.6),
                                      const Color(0xFF6DC8D9)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFFE88DCC)
                                          .withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Inner cutout (makes it a ring)
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1A1A2E)
                                    : const Color(0xFFF5F5FA),
                              ),
                            ),
                            // Sparkle icon
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 32 + (pulse * 4),
                              color: iconColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.aiAnalyzing,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Animated gradient progress bar
                      SizedBox(
                        width: 140,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.08),
                              ),
                              AnimatedBuilder(
                                animation: spinController,
                                builder: (context, _) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        0.3 + (math.sin(spin * 2).abs() * 0.5),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFE88DCC),
                                            Color(0xFFF7D06B),
                                            Color(0xFF6DC8D9),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
