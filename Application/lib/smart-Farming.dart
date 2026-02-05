import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with TickerProviderStateMixin {
  // Core services
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _buttonController;

  // State variables
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _currentTranscript = '';
  String _selectedLanguage = 'en-US';
  String _initializationStatus = 'Initializing...';
  String _currentChatId = '';

  // Chat management
  List<ChatSession> _chatSessions = [];
  List<ChatMessage> _chatHistory = [];

  // API Configuration
  String _apiKey = '';
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  // VFARM theme colors - Updated color scheme
  static const Color primaryGreen = Color(0xFF0A9D88);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color gradientStart = Color(0xFF0A9D88);
  static const Color gradientEnd = Color(0xFF059669);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);

  // Supported languages with native names and language codes
  final Map<String, Map<String, String>> _supportedLanguages = {
    'en-US': {
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'ttsCode': 'en-US',
      'geminiPrompt': 'Respond in English',
    },
    'hi-IN': {
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'flag': '🇮🇳',
      'ttsCode': 'hi-IN',
      'geminiPrompt': 'Respond in Hindi (हिन्दी में जवाब दें)',
    },
    'ta-IN': {
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
      'flag': '🇮🇳',
      'ttsCode': 'ta-IN',
      'geminiPrompt': 'Respond in Tamil (தமிழில் பதில் அளிக்கவும்)',
    },
    'ml-IN': {
      'name': 'Malayalam',
      'nativeName': 'മലയാളം',
      'flag': '🇮🇳',
      'ttsCode': 'ml-IN',
      'geminiPrompt': 'Respond in Malayalam (മലയാളത്തിൽ ഉത്തരം നൽകുക)',
    },
    'kn-IN': {
      'name': 'Kannada',
      'nativeName': 'ಕನ್ನಡ',
      'flag': '🇮🇳',
      'ttsCode': 'kn-IN',
      'geminiPrompt': 'Respond in Kannada (ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ)',
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Wave animation for visual effects
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  Future<void> _initializeApp() async {
    setState(() {
      _initializationStatus = 'Loading preferences...';
    });

    await _loadSettings();

    setState(() {
      _initializationStatus = 'Initializing speech services...';
    });

    await _initializeServices();

    setState(() {
      _initializationStatus = 'Loading chat sessions...';
    });

    await _loadChatSessions();

    setState(() {
      _initializationStatus = 'Ready to chat!';
    });

    // Hide status after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _initializationStatus = '';
        });
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Speech-to-Text
      bool available = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          _showError('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) => _handleSpeechStatus(status),
      );

      setState(() {
        _speechInitialized = available;
      });

      if (!available) {
        _showError('Speech recognition not available on this device');
        return;
      }

      // Initialize Text-to-Speech with error handling
      try {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.awaitSpeakCompletion(true);

        _flutterTts.setStartHandler(() {
          if (mounted) {
            setState(() => _isSpeaking = true);
          }
        });

        _flutterTts.setCompletionHandler(() {
          if (mounted) {
            setState(() => _isSpeaking = false);
          }
        });

        _flutterTts.setErrorHandler((msg) {
          print('TTS Error: $msg');
          if (mounted) {
            setState(() => _isSpeaking = false);
            _showError('Text-to-speech error: $msg');
          }
        });

        // Set initial TTS settings based on selected language
        await _updateTTSLanguage();
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(0.9);
        await _flutterTts.setPitch(1.0);
      } catch (e) {
        print('TTS initialization error: $e');
        _showError('Failed to initialize text-to-speech');
      }
    } catch (e) {
      print('Error initializing services: $e');
      _showError('Failed to initialize services: $e');
      setState(() {
        _speechInitialized = false;
      });
    }
  }

  Future<void> _updateTTSLanguage() async {
    try {
      final ttsCode =
          _supportedLanguages[_selectedLanguage]?['ttsCode'] ?? 'en-US';
      final result = await _flutterTts.setLanguage(ttsCode);
      if (result == 1) {
        print('TTS language set to: $ttsCode');
      } else {
        print('Failed to set TTS language to: $ttsCode');
        // Fallback to English if language not supported
        await _flutterTts.setLanguage('en-US');
      }
    } catch (e) {
      print('Error setting TTS language: $e');
      // Fallback to English
      await _flutterTts.setLanguage('en-US');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get from SharedPreferences first, otherwise use .env
      String? savedKey = prefs.getString('gemini_api_key');
      String? envKey = dotenv.env['GEMINI_API_KEY'];

      setState(() {
        _apiKey = savedKey ?? envKey ?? '';
        _selectedLanguage = prefs.getString('selected_language') ?? 'en-US';
        _currentChatId = prefs.getString('current_chat_id') ?? '';
      });

      // If no key in SharedPreferences but exists in .env, save it
      if ((savedKey == null || savedKey.isEmpty) &&
          envKey != null &&
          envKey.isNotEmpty) {
        await prefs.setString('gemini_api_key', envKey);
      }

      if (_apiKey.isEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _apiKey.isEmpty) {
            _showApiKeyDialog();
          }
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      _showError('Failed to load settings');
    }
  }

  Future<void> _loadChatSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('chat_sessions') ?? '[]';
      final List<dynamic> sessionsList = json.decode(sessionsJson);

      setState(() {
        _chatSessions =
            sessionsList.map((item) => ChatSession.fromJson(item)).toList();
      });

      // Load current chat history if exists
      if (_currentChatId.isNotEmpty) {
        await _loadChatHistory(_currentChatId);
      } else if (_chatSessions.isNotEmpty) {
        // Load the most recent chat
        _currentChatId = _chatSessions.first.id;
        await _loadChatHistory(_currentChatId);
      } else {
        // Create first chat session
        await _createNewChat();
      }
    } catch (e) {
      print('Error loading chat sessions: $e');
      setState(() {
        _chatSessions = [];
      });
      await _createNewChat();
    }
  }

  Future<void> _loadChatHistory(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('chat_history_$chatId') ?? '[]';
      final List<dynamic> historyList = json.decode(historyJson);

      setState(() {
        _chatHistory =
            historyList.map((item) => ChatMessage.fromJson(item)).toList();
        _currentChatId = chatId;
      });
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _chatHistory = [];
      });
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _chatHistory.map((msg) => msg.toJson()).toList(),
      );
      await prefs.setString('chat_history_$_currentChatId', historyJson);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<void> _saveChatSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = json.encode(
        _chatSessions.map((session) => session.toJson()).toList(),
      );
      await prefs.setString('chat_sessions', sessionsJson);
      await prefs.setString('current_chat_id', _currentChatId);
    } catch (e) {
      print('Error saving chat sessions: $e');
    }
  }

  Future<void> _createNewChat() async {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      lastMessage: '',
      timestamp: DateTime.now(),
      language: _selectedLanguage,
    );

    setState(() {
      _chatSessions.insert(0, newSession);
      _currentChatId = newSession.id;
      _chatHistory.clear();
    });

    await _saveChatSessions();
    _showMessage('New chat created', isError: false);
  }

  void _handleSpeechStatus(String status) {
    print('STT Status: $status');
    if (status == 'listening') {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else if (status == 'notListening') {
      _pulseController.stop();
      _waveController.stop();
    } else if (status == 'done') {
      print('Speech recognition completed. Transcript: $_currentTranscript');
    }
  }

  void _startListening() async {
    if (!_speechInitialized) {
      _showError(
        'Speech recognition is not available. Please check your device settings.',
      );
      return;
    }

    if (_isProcessing || _isSpeaking) {
      _showError('Please wait for the current operation to complete.');
      return;
    }

    try {
      await _flutterTts.stop(); // Stop any ongoing speech

      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: _selectedLanguage,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      print('Error starting listening: $e');
      _showError('Failed to start listening: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });

      // Wait a moment for final result to be processed
      await Future.delayed(const Duration(milliseconds: 500));

      print('Final transcript: $_currentTranscript');

      if (_currentTranscript.trim().isNotEmpty) {
        final transcript = _currentTranscript;
        setState(() {
          _currentTranscript = '';
        });
        _processUserInput(transcript);
      } else {
        _showError('No speech detected. Please try again.');
      }
    } catch (e) {
      print('Error stopping listening: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(result) {
    print(
      'Speech result - Final: ${result.finalResult}, Words: ${result.recognizedWords}',
    );
    setState(() {
      _currentTranscript = result.recognizedWords;
    });

    // If this is the final result and we're not listening anymore, process it
    if (result.finalResult &&
        !_isListening &&
        _currentTranscript.trim().isNotEmpty) {
      final transcript = _currentTranscript;
      setState(() {
        _currentTranscript = '';
      });
      _processUserInput(transcript);
    }
  }

  void _setLanguage(String languageCode) async {
    if (_selectedLanguage != languageCode) {
      setState(() {
        _selectedLanguage = languageCode;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', languageCode);

        // Update TTS language
        await _updateTTSLanguage();

        _showMessage(
          'Language changed to ${_supportedLanguages[languageCode]?['name']}',
          isError: false,
        );
      } catch (e) {
        print('Error setting language: $e');
        _showError('Failed to change language');
      }
    }
  }

  Future<void> _processUserInput(String input) async {
    if (input.trim().isEmpty) return;

    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Add user message to history
    final userMessage = ChatMessage(
      content: input,
      isUser: true,
      timestamp: DateTime.now(),
      language: _selectedLanguage,
    );

    setState(() {
      _chatHistory.add(userMessage);
    });

    try {
      final response = await _sendToGemini(input);

      // Add AI response to history
      final aiMessage = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        language: _selectedLanguage,
      );

      setState(() {
        _chatHistory.add(aiMessage);
      });

      // Update chat session
      _updateCurrentChatSession(input);

      // Save chat history and sessions
      await _saveChatHistory();
      await _saveChatSessions();

      // Speak the response
      await _speakResponse(response);
    } catch (e) {
      print('Error processing input: $e');
      _showError('Failed to get response: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _updateCurrentChatSession(String lastMessage) {
    final sessionIndex = _chatSessions.indexWhere(
      (s) => s.id == _currentChatId,
    );
    if (sessionIndex != -1) {
      final session = _chatSessions[sessionIndex];
      final updatedSession = ChatSession(
        id: session.id,
        title:
            session.title == 'New Chat'
                ? _generateChatTitle(lastMessage)
                : session.title,
        lastMessage:
            lastMessage.length > 50
                ? '${lastMessage.substring(0, 50)}...'
                : lastMessage,
        timestamp: DateTime.now(),
        language: _selectedLanguage,
      );

      setState(() {
        _chatSessions[sessionIndex] = updatedSession;
        // Move current chat to top
        _chatSessions.removeAt(sessionIndex);
        _chatSessions.insert(0, updatedSession);
      });
    }
  }

  String _generateChatTitle(String firstMessage) {
    if (firstMessage.length <= 30) return firstMessage;
    return '${firstMessage.substring(0, 30)}...';
  }

  Future<String> _sendToGemini(String message) async {
    final headers = {'Content-Type': 'application/json'};

    // Build conversation context
    String conversationContext = '';

    // Get last 8 conversations for context
    final recentHistory =
        _chatHistory.length > 16 ? _chatHistory.takeLast(16) : _chatHistory;

    for (var msg in recentHistory) {
      conversationContext +=
          '${msg.isUser ? "User" : "Assistant"}: ${msg.content}\n';
    }

    // Get language-specific prompt
    final languagePrompt =
        _supportedLanguages[_selectedLanguage]?['geminiPrompt'] ??
        'Respond in English';

    final prompt =
        '''You are VFARM AI, a helpful farming and agricultural assistant. $languagePrompt. Keep responses natural, conversational, and concise for voice playback (maximum 2-3 sentences). Focus on farming, agriculture, crops, livestock, and rural development topics.

Previous conversation:
$conversationContext

Current user message: $message

Please respond appropriately in the specified language.''';

    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.9,
        'topK': 0,
        'maxOutputTokens': 2048,
        'stopSequences': [],
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });

    final response = await http
        .post(Uri.parse('$_apiUrl?key=$_apiKey'), headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['candidates'] != null &&
          data['candidates'].isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          data['candidates'][0]['content']['parts'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        throw Exception('Invalid response format from Gemini API');
      }
    } else if (response.statusCode == 400) {
      final data = json.decode(response.body);
      throw Exception(
        'Bad Request: ${data['error']['message'] ?? 'Invalid request'}',
      );
    } else if (response.statusCode == 403) {
      throw Exception(
        'Invalid API key or quota exceeded. Please check your Gemini API key.',
      );
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please wait and try again.');
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;

    try {
      // Update TTS language before speaking
      await _updateTTSLanguage();
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.9);
      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking response: $e');
      _showError('Failed to speak response');
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.key, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'API Key Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To use VFARM AI assistant, please provide your Google Gemini API key.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIza...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryGreen, width: 2),
                      ),
                      prefixIcon: Icon(Icons.vpn_key, color: primaryGreen),
                      filled: true,
                      fillColor: lightGray,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryGreen.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Get your API key:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '1. Visit: https://aistudio.google.com/app/apikey\n'
                          '2. Sign in with Google\n'
                          '3. Create API key\n'
                          '4. Copy and paste here',
                          style: TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 14)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final key = controller.text.trim();
                  if (key.isNotEmpty && key.startsWith('AIza')) {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('gemini_api_key', key);
                      setState(() {
                        _apiKey = key;
                      });
                      Navigator.of(context).pop();
                      _showMessage(
                        'API key saved successfully!',
                        isError: false,
                      );
                    } catch (e) {
                      _showError('Failed to save API key');
                    }
                  } else {
                    _showError(
                      'Please enter a valid API key starting with "AIza"',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    _showMessage(message, isError: true);
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: isError ? errorRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 3 : 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showChatSessions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Chat Sessions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _createNewChat,
                        icon: Icon(Icons.add, size: 18),
                        label: Text('New', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _chatSessions.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No chat sessions yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first chat to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _chatSessions.length,
                            itemBuilder: (context, index) {
                              final session = _chatSessions[index];
                              final isActive = session.id == _currentChatId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient:
                                          isActive
                                              ? LinearGradient(
                                                colors: [
                                                  primaryGreen,
                                                  secondaryGreen,
                                                ],
                                              )
                                              : LinearGradient(
                                                colors: [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400,
                                                ],
                                              ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat,
                                      color:
                                          isActive
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    session.title,
                                    style: TextStyle(
                                      fontWeight:
                                          isActive
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      color:
                                          isActive
                                              ? primaryGreen
                                              : Colors.black87,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (session.lastMessage.isNotEmpty)
                                        Text(
                                          session.lastMessage,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _supportedLanguages[session
                                                    .language]?['flag'] ??
                                                '🌍',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTime(session.timestamp),
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing:
                                      isActive
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: successGreen,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Active',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                          : PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey.shade600,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'delete') {
                                                _deleteChat(session.id);
                                              }
                                            },
                                            itemBuilder:
                                                (context) => [
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          color: errorRed,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          isActive
                                              ? primaryGreen.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.2),
                                      width: isActive ? 2 : 1,
                                    ),
                                  ),
                                  tileColor:
                                      isActive
                                          ? primaryGreen.withOpacity(0.05)
                                          : null,
                                  onTap: () async {
                                    if (!isActive) {
                                      await _loadChatHistory(session.id);
                                      Navigator.pop(context);
                                      _showMessage(
                                        'Switched to ${session.title}',
                                        isError: false,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: errorRed, size: 24),
                const SizedBox(width: 8),
                const Text('Delete Chat', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete this chat? This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Remove from sessions list
                  setState(() {
                    _chatSessions.removeWhere((s) => s.id == chatId);
                  });

                  // Delete chat history
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('chat_history_$chatId');

                  // If this was the current chat, switch to another or create new
                  if (_currentChatId == chatId) {
                    if (_chatSessions.isNotEmpty) {
                      await _loadChatHistory(_chatSessions.first.id);
                    } else {
                      await _createNewChat();
                    }
                  }

                  await _saveChatSessions();
                  Navigator.pop(context);
                  Navigator.pop(context); // Close the chat sessions dialog
                  _showMessage('Chat deleted', isError: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _clearCurrentHistory() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.clear_all, color: warningOrange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Clear Chat History',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to clear this chat history? This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _chatHistory.clear();
                  });
                  await _saveChatHistory();
                  Navigator.pop(context);
                  _showMessage('Chat history cleared', isError: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: warningOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _buttonController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildProfessionalHeader(),
          // Keep initialization status - important for user feedback
          if (_initializationStatus.isNotEmpty) _buildInitializationStatus(),
          // REMOVE this line - this is causing the top listening areaR
          // _buildCurrentStatus(), // <- REMOVE THIS LINE
          Expanded(child: _buildExpandedChatArea()), // Now takes full space
          _buildModernInputArea(), // This already contains the listening status
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    final currentLang = _supportedLanguages[_selectedLanguage] ?? {};
    final currentSession = _chatSessions.firstWhere(
      (s) => s.id == _currentChatId,
      orElse:
          () => ChatSession(
            id: '',
            title: 'VFARM AI',
            lastMessage: '',
            timestamp: DateTime.now(),
            language: _selectedLanguage,
          ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Clean back icon without box
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/finallogo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.agriculture,
                                color: Colors.white,
                                size: 20,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'VFARM AI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentLang['flag'] ?? '🌍',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${currentLang['nativeName']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean chat icon without box
                  GestureDetector(
                    onTap: _showChatSessions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Clean menu icon without box
                  GestureDetector(
                    onTap: () => _showOptionsMenu(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitializationStatus() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _initializationStatus,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedChatArea() {
    if (_chatHistory.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/finallogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.agriculture,
                        color: primaryGreen,
                        size: 32,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to VFARM AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your intelligent farming companion is ready to help!\nPress the microphone button to start asking questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (!_speechInitialized)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: warningOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: warningOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Speech recognition unavailable',
                          style: TextStyle(
                            color: warningOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Chat Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                  ),
                ),
                Spacer(),
                Text(
                  '${_chatHistory.length} messages',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Messages area - Now much larger
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                return _buildProfessionalChatBubble(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI profile - smaller and cleaner
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryGreen, accentTeal]),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/finallogo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.smart_toy, color: Colors.white, size: 16);
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? primaryGreen : Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (!isUser && !_isSpeaking)
                        GestureDetector(
                          onTap: () => _speakResponse(message.content),
                          child: Icon(
                            Icons.volume_up,
                            size: 16,
                            color: primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            // User profile - smaller and cleaner
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(Icons.person, size: 16, color: primaryGreen),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    String statusText = '';
    IconData statusIcon = Icons.mic_none;
    Color statusColor = Colors.white;
    Color backgroundColor = Colors.white.withOpacity(0.15);

    if (!_speechInitialized) {
      statusText = 'Speech recognition unavailable';
      statusIcon = Icons.mic_off;
      statusColor = warningOrange;
      backgroundColor = warningOrange.withOpacity(0.1);
    } else if (_isListening) {
      statusText =
          _currentTranscript.isEmpty
              ? 'Listening... Speak now!'
              : _currentTranscript;
      statusIcon = Icons.mic;
      statusColor = errorRed;
      backgroundColor = errorRed.withOpacity(0.1);
    } else if (_isProcessing) {
      statusText = 'Processing your request...';
      statusIcon = Icons.psychology;
      statusColor = accentTeal;
      backgroundColor = accentTeal.withOpacity(0.1);
    } else if (_isSpeaking) {
      statusText = 'Speaking response...';
      statusIcon = Icons.volume_up;
      statusColor = successGreen;
      backgroundColor = successGreen.withOpacity(0.1);
    } else {
      statusText =
          _speechInitialized
              ? 'Ready to listen - Press and hold microphone'
              : 'Speech recognition not available';
      statusIcon = _speechInitialized ? Icons.mic_none : Icons.mic_off;
      statusColor = Colors.white;
      backgroundColor = Colors.white.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (_isListening || _isProcessing) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          if (_isListening || _isProcessing || _isSpeaking)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor().withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Voice controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stop button
              _buildCleanControlButton(
                icon: Icons.stop_circle,
                label: 'Stop',
                isActive: _isSpeaking,
                onPressed: _isSpeaking ? () => _flutterTts.stop() : null,
                color: errorRed,
              ),
              // Main microphone button
              GestureDetector(
                onTapDown:
                    _speechInitialized && !_isProcessing && !_isSpeaking
                        ? (_) => _startListening()
                        : null,
                onTapUp:
                    _speechInitialized && _isListening
                        ? (_) => _stopListening()
                        : null,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient:
                        _isListening
                            ? LinearGradient(
                              colors: [errorRed, Colors.red.shade400],
                            )
                            : LinearGradient(
                              colors: [primaryGreen, secondaryGreen],
                            ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? errorRed : primaryGreen)
                            .withValues(alpha: 0.3),
                        spreadRadius: _isListening ? 4 : 2,
                        blurRadius: _isListening ? 20 : 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Language button
              _buildCleanControlButton(
                icon: Icons.language,
                label: 'Language',
                isActive: false,
                onPressed: _showLanguageSelector,
                color: accentTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: isActive ? Colors.white : color, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.clear_all, color: warningOrange),
                        title: Text('Clear History'),
                        onTap: () {
                          Navigator.pop(context);
                          _clearCurrentHistory();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.settings, color: primaryGreen),
                        title: Text('API Settings'),
                        onTap: () {
                          Navigator.pop(context);
                          _showApiKeyDialog();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.language, color: accentTeal),
                        title: Text('Language'),
                        onTap: () {
                          Navigator.pop(context);
                          _showLanguageSelector();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Color _getStatusColor() {
    if (_isListening) return errorRed;
    if (_isProcessing) return warningOrange;
    if (_isSpeaking) return successGreen;
    return primaryGreen;
  }

  IconData _getStatusIcon() {
    if (_isListening) return Icons.mic;
    if (_isProcessing) return Icons.psychology;
    if (_isSpeaking) return Icons.volume_up;
    return Icons.mic_none;
  }

  String _getStatusText() {
    if (_isListening)
      return _currentTranscript.isEmpty
          ? 'Listening... Speak now!'
          : _currentTranscript;
    if (_isProcessing) return 'Processing your request...';
    if (_isSpeaking) return 'Speaking response...';
    return 'Ready to listen';
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.language,
                              color: primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Select Language',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...(_supportedLanguages.entries.map((entry) {
                        final langData = entry.value;
                        final isSelected = _selectedLanguage == entry.key;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          colors: [
                                            primaryGreen,
                                            secondaryGreen,
                                          ],
                                        )
                                        : LinearGradient(
                                          colors: [
                                            Colors.grey.shade200,
                                            Colors.grey.shade300,
                                          ],
                                        ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected
                                            ? primaryGreen
                                            : Colors.grey)
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  langData['flag'] ?? '🌍',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            title: Text(
                              langData['nativeName'] ?? '',
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                color:
                                    isSelected ? primaryGreen : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              langData['name'] ?? '',
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? primaryGreen.withOpacity(0.7)
                                        : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: successGreen,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                    : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? primaryGreen.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            tileColor:
                                isSelected
                                    ? primaryGreen.withOpacity(0.05)
                                    : null,
                            onTap: () {
                              _setLanguage(entry.key);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      })),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Extension method for list operations
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}

// Chat Session model
class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final String language;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastMessage': lastMessage,
    'timestamp': timestamp.toIso8601String(),
    'language': language,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] ?? '',
    title: json['title'] ?? 'Untitled Chat',
    lastMessage: json['lastMessage'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    language: json['language'] ?? 'en-US',
  );
}

// Chat Message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'language': language,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    language: json['language'] ?? 'en-US',
  );
}
