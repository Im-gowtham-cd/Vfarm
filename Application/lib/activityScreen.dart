import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vfarm/models/daily_activity_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vfarm/l10n/app_localizations.dart';
import 'package:vfarm/locale_manager.dart';
import 'dart:math' as math;

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  
 
  String _selectedActivityType = '';
  String _selectedActivity = '';
  bool _showActivityDetails = false;
  
  List<ActivityType> _getActivityTypes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ActivityType(
        id: 'crop_management',
        name: l10n.cropManagement,
        icon: '🌱',
        description: l10n.cropManagementDesc,
      ),
      ActivityType(
        id: 'livestock',
        name: l10n.livestockCare,
        icon: '🐄',
        description: l10n.livestockCareDesc,
      ),
      ActivityType(
        id: 'equipment',
        name: l10n.equipmentTools,
        icon: '🚜',
        description: l10n.equipmentToolsDesc,
      ),
      ActivityType(
        id: 'harvest',
        name: l10n.harvesting,
        icon: '🌾',
        description: l10n.harvestingDesc,
      ),
      ActivityType(
        id: 'maintenance',
        name: l10n.farmMaintenance,
        icon: '🔧',
        description: l10n.farmMaintenanceDesc,
      ),
      ActivityType(
        id: 'planning',
        name: l10n.planningAdmin,
        icon: '📋',
        description: l10n.planningAdminDesc,
      ),
    ];
  }
  
  // Voice processing
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isProcessing = false;
  String? _detectedLanguage;
  
  // Activity processing
  bool _isLoading = false;
  Map<String, dynamic>? _processedData;
  bool _needsMoreInfo = false;
  List<String> _missingFields = [];
  String _followUpQuestion = '';
  bool _isFollowUp = false;
  String _previousInput = '';
  String _conversationHistory = '';
  String _originalConversationHistory = ''; // Track original language inputs
  
  // Auto date/time
  late DateTime _activityDateTime;
  
  // Language settings
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _activityDateTime = DateTime.now();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    // Listen to locale changes
    LocaleManager.instance.addListener(_onLocaleChanged);
    
    _initializeServices();
  }
  
  void _onLocaleChanged() {
    // Reload language settings when locale changes
    _loadLanguageSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload language settings when dependencies change (like locale changes)
    // This will be called when user changes language in settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLanguageSettings();
    });
  }

  @override
  void didUpdateWidget(DailyActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload language settings when widget is updated
    _loadLanguageSettings();
  }

  Future<void> _initializeServices() async {
    await _initializeVoiceServices(); // Initialize TTS first
    await _loadLanguageSettings(); // Then load and configure language
    await _loadInitialData();
  }
  
  Future<void> _loadLanguageSettings() async {
    try {
      // Get language from LocaleManager (same as settings page)
      final localeManager = LocaleManager.instance;
      final currentLocale = localeManager.currentLocale;
      final languageCode = currentLocale.languageCode;
      
      print('🌍 Current locale from LocaleManager: $languageCode');
      
      setState(() {
        _selectedLanguage = languageCode;
      });
      print('✅ Loaded language setting: $_selectedLanguage');
      
      // Configure TTS for the selected language
      await _configureTTSLanguage();
    } catch (e) {
      print('❌ Error loading language settings: $e');
      // Default to English if there's an error
      setState(() {
        _selectedLanguage = 'en';
      });
    }
  }
  
  Future<void> _configureTTSLanguage() async {
    try {
      String ttsLanguageCode;
      switch (_selectedLanguage) {
        case 'hi':
          ttsLanguageCode = 'hi-IN';
          break;
        case 'ta':
          ttsLanguageCode = 'ta-IN';
          break;
        case 'ml':
          ttsLanguageCode = 'ml-IN';
          break;
        case 'te':
          ttsLanguageCode = 'te-IN';
          break;
        default:
          ttsLanguageCode = 'en-US';
      }
      
      await _flutterTts.setLanguage(ttsLanguageCode);
      print('✅ TTS language set to: $ttsLanguageCode');
    } catch (e) {
      print('❌ Error setting TTS language: $e');
      await _flutterTts.setLanguage('en-US'); // Fallback
    }
  }

  Future<void> _initializeVoiceServices() async {
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    
    // Request microphone permission
    if (await Permission.microphone.request().isGranted) {
      bool available = await _speechToText.initialize(
        onStatus: (val) {
          print('STT Status: $val');
          if (val == 'notListening' && _isListening) {
            setState(() => _isListening = false);
            _pulseController.stop();
            _waveController.stop();
            // Process the recognized text when listening stops
            if (_recognizedText.isNotEmpty) {
              _processVoiceInput();
            }
          }
        },
        onError: (val) {
          print('STT Error: $val');
          setState(() => _isListening = false);
          _pulseController.stop();
          _waveController.stop();
          _showErrorMessage('Speech recognition error: $val');
        },
      );
      
      setState(() {
        _speechEnabled = available;
      });
    }

    // Configure TTS
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.8);
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      await FarmActivityService.instance.initialize();
      setState(() => _isLoading = false);
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to initialize: ${e.toString()}');
    }
  }

  void _onActivitySelected(String activityType, String activity) {
    setState(() {
      _selectedActivityType = activityType;
      _selectedActivity = activity;
      _showActivityDetails = true;
      _recognizedText = '';
      _needsMoreInfo = false;
      _isFollowUp = false;
      _previousInput = '';
      _conversationHistory = '';
      _originalConversationHistory = '';
      _processedData = null;
    });
    
    // Auto-start voice interaction
    _startVoiceInteraction();
  }

  Future<void> _startVoiceInteraction() async {
    // Speak welcome message using localized strings
    final l10n = AppLocalizations.of(context)!;
    String message = l10n.botGreatSelection(_selectedActivity);
    await _flutterTts.speak(message);
    
    // Auto-start listening after instruction
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && !_isListening && !_isProcessing) {
      _startListening();
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _showErrorMessage(AppLocalizations.of(context)!.speechRecognitionNotAvailable);
      return;
    }
    
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    });
    
    // Configure STT locale based on user's language
    String sttLocale;
    switch (_selectedLanguage) {
      case 'hi':
        sttLocale = 'hi-IN';
        break;
      case 'ta':
        sttLocale = 'ta-IN';
        break;
      case 'ml':
        sttLocale = 'ml-IN';
        break;
      case 'te':
        sttLocale = 'te-IN';
        break;
      default:
        sttLocale = 'en-US';
    }
    
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          // Use the app's selected language instead of trying to detect
          _detectedLanguage = _selectedLanguage;
        });
        
        print('Recognized: $_recognizedText');
        print('Using language: $_detectedLanguage');
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: sttLocale,
    );
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _waveController.stop();
      });
      
      await _speechToText.stop();
      
      if (_recognizedText.isNotEmpty) {
        await _processVoiceInput();
      }
    }
  }


  Future<void> _processVoiceInput() async {
    if (_recognizedText.trim().isEmpty) {
      _showErrorMessage(AppLocalizations.of(context)!.noVoiceInputDetected);
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Build conversation history for AI processing (can be translated)
      String fullInput = _recognizedText;
      if (_isFollowUp && _conversationHistory.isNotEmpty) {
        fullInput = '$_conversationHistory. Additional info: $_recognizedText';
      }
      
      // Track original language conversation separately
      _originalConversationHistory += (_originalConversationHistory.isEmpty ? '' : '. ') + _recognizedText;
      
      print('Processing input: $fullInput');
      print('Original conversation: $_originalConversationHistory');
      
      final result = await FarmActivityService.instance.processVoiceInput(
        userInput: fullInput,
        activityType: _selectedActivityType,
        selectedActivity: _selectedActivity,
        detectedLanguage: _detectedLanguage,
        isFollowUp: _isFollowUp,
      );
      
      print('Processing result: $result');
      
      setState(() {
        _isProcessing = false;
        _processedData = result;
      });

      if (result['success'] == true) {
        if (result['needsMoreInfo'] == true) {
          // Need more information
          await _handleIncompleteData(result);
        } else {
          // Data is complete, save
          await _saveActivity(result);
        }
      } else {
        String errorMessage = result['error']?.toString() ?? 'Unknown error occurred';
        _showErrorMessage('Processing failed: $errorMessage');
      }
    } catch (e) {
      print('Error in _processVoiceInput: $e');
      setState(() => _isProcessing = false);
      _showErrorMessage('Error processing voice input: ${e.toString()}');
    }
  }

  Future<void> _handleIncompleteData(Map<String, dynamic> result) async {
    // Update conversation history
    _conversationHistory += (_conversationHistory.isEmpty ? '' : '. ') + _recognizedText;
    
    setState(() {
      _needsMoreInfo = true;
      _missingFields = List<String>.from(result['missingFields'] ?? []);
      _isFollowUp = true;
      _previousInput = _recognizedText;
    });

    // Generate and speak follow-up question using dynamic system
    try {
      final l10n = AppLocalizations.of(context)!;
      
      // Get the localization key from the service
      String questionKey = await FarmActivityService.instance.generateFollowUpQuestion(
        _selectedActivityType, 
        _missingFields, 
        _selectedLanguage
      );
      
      // Resolve the localization key to actual text
      String question;
      switch (questionKey) {
        case 'botWhatCropHarvested':
          question = l10n.botWhatCropHarvested;
          break;
        case 'botHowMuchQuantity':
          question = l10n.botHowMuchQuantity;
          break;
        case 'botHowMuchArea':
          question = l10n.botHowMuchArea;
          break;
        case 'botApproximateProfit':
          question = l10n.botApproximateProfit;
          break;
        case 'botWhatCropType':
          question = l10n.botWhatCropType;
          break;
        case 'botWhatAnimalType':
          question = l10n.botWhatAnimalType;
          break;
        case 'botHowManyAnimals':
          question = l10n.botHowManyAnimals;
          break;
        case 'botWhichEquipment':
          question = l10n.botWhichEquipment;
          break;
        case 'botWhatWorkType':
          question = l10n.botWhatWorkType;
          break;
        case 'botDescribeActivity':
          question = l10n.botDescribeActivity;
          break;
        default:
          question = l10n.botActivityComplete;
      }
      
      setState(() {
        _followUpQuestion = question;
      });

      await _flutterTts.speak(question);
      
      // Auto-start listening for follow-up
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !_isListening) {
        _startListening();
      }
    } catch (e) {
      print('Error generating follow-up: $e');
      _showErrorMessage('Failed to generate follow-up question: ${e.toString()}');
    }
  }

  Future<void> _saveActivity(Map<String, dynamic> result) async {
    try {
      print('Saving activity with result: $result');
      
      // Update the result with original conversation history
      final updatedResult = Map<String, dynamic>.from(result);
      if (updatedResult['data'] != null) {
        updatedResult['data']['originalInput'] = _originalConversationHistory;
      }
      
      await FarmActivityService.instance.saveVoiceProcessedActivity(
        activityType: _selectedActivityType,
        selectedActivity: _selectedActivity,
        processedData: updatedResult,
        activityDateTime: _activityDateTime,
      );

      // Show success message
      final l10n = AppLocalizations.of(context)!;
      await _flutterTts.speak(l10n.botActivitySaved);
      _showSuccessDialog();
      
    } catch (e) {
      print('Error saving activity: $e');
      _showErrorMessage('Failed to save activity: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        title: Text(AppLocalizations.of(context)!.activitySaved),
        content: Text(AppLocalizations.of(context)!.activityRecordedSuccessfully),
        actions: [
          TextButton(
  onPressed: () {
    Navigator.pushReplacementNamed(context, '/home');
  },
  child: Text(AppLocalizations.of(context)!.continueButton),
),

          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: Text(AppLocalizations.of(context)!.addAnother),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedActivityType = '';
      _selectedActivity = '';
      _showActivityDetails = false;
      _recognizedText = '';
      _needsMoreInfo = false;
      _isFollowUp = false;
      _previousInput = '';
      _conversationHistory = '';
      _originalConversationHistory = '';
      _processedData = null;
      _followUpQuestion = '';
      _missingFields.clear();
      _activityDateTime = DateTime.now();
    });
  }

  void _showErrorMessage(String message) {
    print('Error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.ok,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(l10n.dailyActivity),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add this to your AppBar actions (inside the AppBar's actions list)
if (_showActivityDetails)
  IconButton(
    icon: const Icon(Icons.skip_next),
    onPressed: () {
      Navigator.pushReplacementNamed(context, '/home');
    },
    tooltip: l10n.skipToHome,
  ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _showActivityDetails 
          ? _buildVoiceInteractionView()
          : _buildActivitySelectionView(),
    );
  }

  Widget _buildActivitySelectionView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActivityTypeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF4CAF50),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recordYourFarmActivity,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.selectActivityTypeToStart,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _getActivityTypes(context).length,
      itemBuilder: (context, index) {
        final activityType = _getActivityTypes(context)[index];
        return _buildActivityTypeCard(activityType);
      },
    );
  }

  Widget _buildActivityTypeCard(ActivityType activityType) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onActivitySelected(activityType.id, activityType.name),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activityType.icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                activityType.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activityType.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInteractionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSelectedActivityHeader(),
          const SizedBox(height: 24),
          _buildVoiceRecordingCard(),
          const SizedBox(height: 24),
          if (_recognizedText.isNotEmpty) _buildRecognizedTextCard(),
          if (_needsMoreInfo) _buildFollowUpCard(),
          if (_processedData != null && !_needsMoreInfo) _buildProcessedDataCard(),
        ],
      ),
    );
  }

  Widget _buildSelectedActivityHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mic,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedActivity,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tellMeAboutActivity,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordingCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isListening) ...[
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200 + (index * 100)),
                          height: 20 + (60 * (0.5 + 0.5 * math.sin((_waveAnimation.value * 2 * math.pi) + (index * 0.5)))),
                          width: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              Text(
                AppLocalizations.of(context)!.listening,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _stopListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.stopListening),
              ),
            ] else if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.processingWithAI,
                style: const TextStyle(fontSize: 16),
              ),
            ] else ...[
              GestureDetector(
                onTap: _speechEnabled ? _startListening : null,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _speechEnabled 
                          ? const Color(0xFF4CAF50) 
                          : Colors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: (_speechEnabled ? const Color(0xFF4CAF50) : Colors.grey).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _speechEnabled 
                  ? AppLocalizations.of(context)!.tapToStartRecording
                  : AppLocalizations.of(context)!.microphoneNotAvailable,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecognizedTextCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hearing, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.whatIHeard,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _recognizedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_detectedLanguage != null && _detectedLanguage != 'en')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Detected language: ${_getLanguageName(_detectedLanguage)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard() {
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.needMoreInformation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _followUpQuestion,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.provideMissingInfo,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessedDataCard() {
    if (_processedData == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(



          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.activityProcessedSuccessfully,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_processedData!['data'] != null)
              ..._buildExtractedDataItems(),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _saveActivity(_processedData!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.saveActivity),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExtractedDataItems() {
    final data = _processedData!['data'];
    if (data == null) return [];

    final extractedData = data['extractedData'] as Map<String, dynamic>? ?? {};
    
    return extractedData.entries.where((entry) => 
      entry.value != null && 
      entry.value.toString().isNotEmpty &&
      entry.value.toString().toLowerCase() != 'null'
    ).map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatFieldName(entry.key)}: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(entry.value.toString()),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getLanguageName(String? code) {
    switch (code) {
      case 'ml':
        return 'Malayalam';
      case 'hi':
        return 'Hindi';
      case 'ta':
        return 'Tamil';
      case 'te':
        return 'Telugu';
      case 'kn':
        return 'Kannada';
      default:
        return 'English';
    }
  }

  @override
  void dispose() {
    // Remove locale listener
    LocaleManager.instance.removeListener(_onLocaleChanged);
    
    _fadeController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    if (_speechToText.isAvailable) {
      _speechToText.stop();
    }
    super.dispose();
  }
}

// Supporting classes
class ActivityType {
  final String id;
  final String name;
  final String icon;
  final String description;

  ActivityType({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
