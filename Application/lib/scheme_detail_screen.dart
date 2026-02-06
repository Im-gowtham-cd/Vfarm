import 'package:flutter/material.dart';
import 'package:vfarm/models/govt_scheme_model.dart';
import 'package:vfarm/models/user_profile_model.dart';
import 'package:vfarm/screens/scheme_application_screen.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SchemeDetailScreen extends StatelessWidget {
  final GovtSchemeModel scheme;
  final bool isEligible;
  final UserProfileModel? userProfile;
  final VoidCallback? onApplicationSubmitted;

  const SchemeDetailScreen({
    super.key,
    required this.scheme,
    required this.isEligible,
    this.userProfile,
    this.onApplicationSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          scheme.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0A9D88),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A9D88), Color(0xFF0C7B68)],
                ),
              ),
              child:
                  scheme.imagePath.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: scheme.imagePath,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          errorWidget: (context, error, stackTrace) {
                            print('Error loading scheme detail image: $error');
                            return const Center(
                              child: Icon(
                                Icons.agriculture_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.agriculture_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
            ),
            const SizedBox(height: 24),

            // Scheme Details
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scheme.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isEligible ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isEligible ? 'Eligible' : 'Check Criteria',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Replace the old Description section with this:
                    SchemeDescriptionWithTranslator(scheme: scheme),
                    const SizedBox(height: 24),

                    // Benefits
                    Text(
                      'Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A9D88).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scheme.benefits['description']?.toString() ??
                            'Financial assistance and comprehensive support',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Eligibility Requirements Section (shown when not eligible)
                    if (!isEligible) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Eligibility Requirements',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Crop Type Requirements
                            if (scheme.eligibleCropTypes.isNotEmpty &&
                                !scheme.eligibleCropTypes.contains('all')) ...[
                              _buildEligibilityItem(
                                icon: Icons.agriculture_rounded,
                                title: 'Required Crops',
                                value: scheme.eligibleCropTypes.join(', '),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Farm Size Requirements
                            if (scheme.eligibilityCriteria['minLandHolding'] !=
                                    null ||
                                scheme.eligibilityCriteria['maxLandHolding'] !=
                                    null) ...[
                              _buildEligibilityItem(
                                icon: Icons.landscape_rounded,
                                title: 'Farm Size',
                                value: _getFarmSizeRequirement(
                                  scheme.eligibilityCriteria,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Age Requirements
                            if (scheme.eligibilityCriteria['minAge'] != null ||
                                scheme.eligibilityCriteria['maxAge'] !=
                                    null) ...[
                              _buildEligibilityItem(
                                icon: Icons.person_outline_rounded,
                                title: 'Age',
                                value: _getAgeRequirement(
                                  scheme.eligibilityCriteria,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Income Requirements
                            if (scheme.eligibilityCriteria['minIncome'] !=
                                    null ||
                                scheme.eligibilityCriteria['maxIncome'] !=
                                    null) ...[
                              _buildEligibilityItem(
                                icon: Icons.attach_money_rounded,
                                title: 'Income',
                                value: _getIncomeRequirement(
                                  scheme.eligibilityCriteria,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Required Documents
                            if (scheme.requiredDocuments.isNotEmpty) ...[
                              _buildEligibilityItem(
                                icon: Icons.description_outlined,
                                title: 'Required Documents',
                                value: scheme.requiredDocuments.join(', '),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Eligible Crops
                    if (scheme.eligibleCropTypes.isNotEmpty) ...[
                      Text(
                        'Eligible Crops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            scheme.eligibleCropTypes.map((crop) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  crop.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            isEligible && userProfile != null
                                ? () {
                                  // Navigate to SchemeApplicationScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SchemeApplicationScreen(
                                            scheme: scheme,
                                            userProfile: userProfile!,
                                            onApplicationSubmitted: () {
                                              Navigator.pop(
                                                context,
                                              ); // Go back to previous screen
                                              if (onApplicationSubmitted !=
                                                  null) {
                                                onApplicationSubmitted!();
                                              }
                                            },
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Apply for this Scheme'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A9D88),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
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
    );
  }

  Widget _buildEligibilityItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFarmSizeRequirement(Map<String, dynamic> criteria) {
    final minLand = criteria['minLandHolding'];
    final maxLand = criteria['maxLandHolding'];

    if (minLand != null && maxLand != null) {
      return '$minLand - $maxLand acres';
    } else if (minLand != null) {
      return 'Minimum $minLand acres';
    } else if (maxLand != null) {
      return 'Maximum $maxLand acres';
    }
    return 'Not specified';
  }

  String _getAgeRequirement(Map<String, dynamic> criteria) {
    final minAge = criteria['minAge'];
    final maxAge = criteria['maxAge'];

    if (minAge != null && maxAge != null) {
      return '$minAge - $maxAge years';
    } else if (minAge != null) {
      return 'Minimum $minAge years';
    } else if (maxAge != null) {
      return 'Maximum $maxAge years';
    }
    return 'Not specified';
  }

  String _getIncomeRequirement(Map<String, dynamic> criteria) {
    final minIncome = criteria['minIncome'];
    final maxIncome = criteria['maxIncome'];

    if (minIncome != null && maxIncome != null) {
      return '₹$minIncome - ₹$maxIncome per annum';
    } else if (minIncome != null) {
      return 'Minimum ₹$minIncome per annum';
    } else if (maxIncome != null) {
      return 'Maximum ₹$maxIncome per annum';
    }
    return 'Not specified';
  }
}

// Google Translator with Voice Widget
class SchemeDescriptionWithTranslator extends StatefulWidget {
  final GovtSchemeModel scheme;

  const SchemeDescriptionWithTranslator({super.key, required this.scheme});

  @override
  State<SchemeDescriptionWithTranslator> createState() =>
      _SchemeDescriptionWithTranslatorState();
}

class _SchemeDescriptionWithTranslatorState
    extends State<SchemeDescriptionWithTranslator> {
  final GoogleTranslator translator = GoogleTranslator();
  FlutterTts? flutterTts;

  bool isTranslating = false;
  bool isPlaying = false;
  bool isLoadingVoice = false;
  String translatedText = '';
  String selectedLanguage = 'en';
  String selectedLanguageName = 'English';
  bool _isDisposed = false;

  // Language options for Google Translator
  final Map<String, Map<String, String>> languages = {
    'en': {'name': 'English', 'tts': 'en-US'},
    'hi': {'name': 'हिंदी (Hindi)', 'tts': 'hi-IN'},
    'te': {'name': 'తెలుగు (Telugu)', 'tts': 'te-IN'},
    'ta': {'name': 'தமிழ் (Tamil)', 'tts': 'ta-IN'},
    'kn': {'name': 'ಕನ್ನಡ (Kannada)', 'tts': 'kn-IN'},
    'ml': {'name': 'മലയാളം (Malayalam)', 'tts': 'ml-IN'},
    'bn': {'name': 'বাংলা (Bengali)', 'tts': 'bn-IN'},
    'gu': {'name': 'ગુજરાતી (Gujarati)', 'tts': 'gu-IN'},
    'mr': {'name': 'मराठी (Marathi)', 'tts': 'mr-IN'},
    'pa': {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'tts': 'pa-IN'},
    'ur': {'name': 'اردو (Urdu)', 'tts': 'ur-IN'},
    'or': {'name': 'ଓଡ଼ିଆ (Odia)', 'tts': 'or-IN'},
  };

  @override
  void initState() {
    super.initState();
    translatedText = widget.scheme.description;
    _initializeTts();
  }

  void _initializeTts() async {
    try {
      flutterTts = FlutterTts();

      if (flutterTts != null && !_isDisposed) {
        await flutterTts!.setLanguage('en-US');
        await flutterTts!.setSpeechRate(0.5);
        await flutterTts!.setVolume(1.0);
        await flutterTts!.setPitch(1.0);

        flutterTts!.setCompletionHandler(() {
          if (!_isDisposed && mounted) {
            setState(() {
              isPlaying = false;
            });
          }
        });

        flutterTts!.setErrorHandler((msg) {
          if (!_isDisposed && mounted) {
            setState(() {
              isPlaying = false;
              isLoadingVoice = false;
            });
            _showErrorSnackBar('Voice error: $msg');
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _translateText(String languageCode) async {
    if (_isDisposed || !mounted) return;

    setState(() {
      isTranslating = true;
    });

    try {
      if (languageCode == 'en') {
        // If English is selected, use original text
        setState(() {
          translatedText = widget.scheme.description;
          selectedLanguage = languageCode;
          selectedLanguageName = languages[languageCode]!['name']!;
          isTranslating = false;
        });
        return;
      }

      // Translate text using Google Translator
      final translation = await translator.translate(
        widget.scheme.description,
        from: 'en',
        to: languageCode,
      );

      if (!_isDisposed && mounted) {
        setState(() {
          translatedText = translation.text;
          selectedLanguage = languageCode;
          selectedLanguageName = languages[languageCode]!['name']!;
          isTranslating = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          isTranslating = false;
        });
        _showErrorSnackBar('Translation failed: ${e.toString()}');
      }
    }
  }

  Future<void> _toggleSpeech() async {
    if (_isDisposed || !mounted) return;

    if (isPlaying) {
      await _stopSpeaking();
      return;
    }

    if (!mounted) return;
    setState(() {
      isLoadingVoice = true;
    });

    try {
      if (flutterTts != null && !_isDisposed && mounted) {
        // Set the appropriate TTS language
        String ttsLanguage = languages[selectedLanguage]!['tts']!;
        await flutterTts!.setLanguage(ttsLanguage);

        if (mounted) {
          setState(() {
            isPlaying = true;
            isLoadingVoice = false;
          });
        }

        await flutterTts!.speak(translatedText);
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          isLoadingVoice = false;
          isPlaying = false;
        });
        _showErrorSnackBar('Voice playback failed');
      }
    }
  }

  Future<void> _stopSpeaking() async {
    if (flutterTts != null && !_isDisposed) {
      await flutterTts!.stop();
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (flutterTts != null) {
      flutterTts!.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Language Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Row(
              children: [
                // Translation Status Indicator
                if (isTranslating)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0A9D88),
                        ),
                      ),
                    ),
                  ),
                // Language Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language, size: 16),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    items:
                        languages.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value['name']!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null &&
                          !_isDisposed &&
                          newValue != selectedLanguage) {
                        _stopSpeaking(); // Stop current speech if playing
                        _translateText(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Current Language Indicator
        if (selectedLanguage != 'en')
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A9D88).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 14, color: Color(0xFF0A9D88)),
                const SizedBox(width: 4),
                Text(
                  'Translated to $selectedLanguageName',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF0A9D88),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Description Container with Voice Controls
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A9D88).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isTranslating
                      ? const Color(0xFF0A9D88).withOpacity(0.5)
                      : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isTranslating ? 'Translating...' : translatedText,
                        key: ValueKey(translatedText),
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isTranslating
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Voice Control Button
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isPlaying ? Colors.red : const Color(0xFF0A9D88),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: (isPlaying
                                      ? Colors.red
                                      : const Color(0xFF0A9D88))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap:
                                (isLoadingVoice || _isDisposed || isTranslating)
                                    ? null
                                    : _toggleSpeech,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child:
                                  isLoadingVoice
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Icon(
                                        isPlaying
                                            ? Icons.stop
                                            : Icons.volume_up,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPlaying ? 'Stop' : 'Listen',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Language-specific voice note
              if (selectedLanguage != 'en' && !isTranslating)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Voice playback in $selectedLanguageName',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
