import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vfarm/session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ActivitySuggestion model class
class ActivitySuggestion {
  final String activity;
  final String icon;
  final String description;
  final String priority;
  final String? category;
  final Map<String, dynamic>? metadata;
  ActivitySuggestion({
    required this.activity,
    required this.icon,
    required this.description,
    required this.priority,
    this.category,
    this.metadata,
  });
  factory ActivitySuggestion.fromMap(Map<String, dynamic> map) {
    return ActivitySuggestion(
      activity: map['activity'] ?? '',
      icon: map['icon'] ?? '📋',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      category: map['category'],
      metadata: map['metadata'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'icon': icon,
      'description': description,
      'priority': priority,
      'category': category,
      'metadata': metadata,
    };
  }
}

// Enhanced FarmActivityService class with Gemini integration
class FarmActivityService {
  static final FarmActivityService _instance = FarmActivityService._internal();
  static FarmActivityService get instance => _instance;
  FarmActivityService._internal();

  late FirebaseFirestore _firestore;
  bool _initialized = false;

  // API Configuration - loaded dynamically
  String _geminiApiKey = '';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _firestore = FirebaseFirestore.instance;

      // Load API key from SharedPreferences or .env
      await _loadApiKey();

      _initialized = true;
      print('✅ FarmActivityService initialized');
      print('🔑 API key loaded: ${_geminiApiKey.isNotEmpty ? "Yes" : "No"}');
    } catch (e) {
      print('❌ FarmActivityService initialization failed: $e');
      throw Exception('Failed to initialize FarmActivityService');
    }
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get from SharedPreferences first, otherwise use .env
      String? savedKey = prefs.getString('gemini_api_key');
      String? envKey = dotenv.env['GEMINI_API_KEY'];

      _geminiApiKey = savedKey ?? envKey ?? '';

      // If no key in SharedPreferences but exists in .env, save it
      if ((savedKey == null || savedKey.isEmpty) &&
          envKey != null &&
          envKey.isNotEmpty) {
        await prefs.setString('gemini_api_key', envKey);
      }

      if (_geminiApiKey.isEmpty) {
        print('⚠️ Warning: No Gemini API key found');
      }
    } catch (e) {
      print('❌ Error loading API key: $e');
    }
  }

  // Voice-based activity processing using Gemini
  Future<Map<String, dynamic>> processVoiceInput({
    required String userInput,
    required String activityType,
    required String selectedActivity,
    String? detectedLanguage,
    bool isFollowUp = false,
  }) async {
    try {
      print('🎤 Processing voice input: $userInput');
      print('📝 Activity type: $activityType, Selected: $selectedActivity');
      print('🌐 Detected language: $detectedLanguage');
      print('🔄 Is follow-up: $isFollowUp');
      // Create Gemini prompt based on activity type
      String prompt = _createGeminiPrompt(
        activityType,
        selectedActivity,
        userInput,
        detectedLanguage,
        isFollowUp,
      );
      print(
        '🚀 Sending prompt to Gemini: ${prompt.substring(0, math.min(200, prompt.length))}...',
      );
      // Call Gemini API
      final response = await _callGeminiAPI(prompt);
      print('📥 Gemini API response: $response');
      if (response['success'] == true && response['data'] != null) {
        final parsedData = response['data'];
        print('✅ Gemini processed data: $parsedData');
        // Validate if all required fields are present
        final validationResult = _validateActivityData(
          activityType,
          parsedData,
        );
        print('🔍 Validation result: $validationResult');
        if (validationResult['isValid'] == true) {
          return {
            'success': true,
            'data': {
              ...parsedData,
              'originalInput': userInput,
              'originalLanguage': detectedLanguage ?? 'en',
              'translatedInput': parsedData['translatedInput'] ?? userInput,
            },
            'needsMoreInfo': false,
          };
        } else {
          return {
            'success': true,
            'missingFields': validationResult['missingFields'] ?? [],
            'data': {
              ...parsedData,
              'originalInput': userInput,
              'originalLanguage': detectedLanguage ?? 'en',
              'translatedInput': parsedData['translatedInput'] ?? userInput,
            },
            'needsMoreInfo': true,
          };
        }
      } else {
        throw Exception(
          'Gemini API call failed: ${response['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('❌ Error processing voice input: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Create context-aware prompt for Gemini
  String _createGeminiPrompt(
    String activityType,
    String selectedActivity,
    String userInput,
    String? detectedLanguage,
    bool isFollowUp,
  ) {
    final prompt = '''
You are an AI assistant helping farmers log their daily activities. 
Analyze the user's voice input and extract structured data.

User Input: "$userInput"
Activity Type: $activityType
Selected Activity: $selectedActivity
Detected Language: ${detectedLanguage ?? 'Unknown'}

IMPORTANT: The user input may be in ${detectedLanguage ?? 'English'} language or transliterated form. 
Common transliterations:
- Tamil: "naan" = I, "karumbu" = sugarcane, "padi" = paddy, "aikal" = acres
- Malayalam: "njan" = I, "karumbu" = sugarcane, "nel" = rice
- Hindi: "main" = I, "ganna" = sugarcane, "dhan" = paddy
- Telugu: "nenu" = I, "cheraku" = sugarcane

Extract the following information in JSON format:
{
  "activityType": "$activityType",
  "extractedData": {
    ${_getRequiredFieldsStructure(activityType)}
  },
  "confidence": "high|medium|low",
  "completeness": "complete|partial|incomplete", 
  "language": "${detectedLanguage ?? 'en'}",
  "notes": "any additional observations"
}

CRITICAL REQUIREMENTS for harvesting activities:
- "cropHarvested": What crop was harvested (e.g., "sugarcane", "rice", "wheat")
- "quantity": Amount harvested with units (e.g., "10 tons", "500 kg", "2 acres worth")
- "areaCovered": Area in acres/hectares (e.g., "2 acres", "1 hectare") 
- "profit": Estimated profit/income (e.g., "₹50,000", "good profit", "break-even")

Important: 
- Only extract information that is clearly mentioned
- Mark fields as null if not mentioned
- Be conservative with confidence levels
- Provide completeness assessment
- Use exact field names as specified above
- Extract animal counts, feed types for livestock activities
- Note equipment conditions and maintenance details
- If a field is not mentioned, set it to null
- Ensure JSON is valid and properly formatted
''';
    return prompt;
  }

  String _getRequiredFieldsStructure(String activityType) {
    switch (activityType) {
      case 'harvest':
        return '''
    "cropHarvested": null,
    "quantity": null,
    "areaCovered": null,
    "profit": null,
    "activityDescription": null''';
      case 'crop_management':
        return '''
    "cropType": null,
    "areaCovered": null,
    "activityDescription": null''';
      case 'livestock':
        return '''
    "animalType": null,
    "animalCount": null,
    "activityDescription": null''';
      case 'equipment':
        return '''
    "equipmentName": null,
    "workType": null,
    "duration": null''';
      case 'maintenance':
        return '''
    "maintenanceArea": null,
    "workDone": null,
    "duration": null''';
      case 'planning':
        return '''
    "planningType": null,
    "decisions": null,
    "timeframe": null''';
      default:
        return '"activityDescription": null';
    }
  }

  // Get required fields description based on activity type
  String _getRequiredFieldsForActivity(String activityType) {
    switch (activityType) {
      case 'crop_management':
        return '''
Essential: cropType, areaCovered, activityDescription
Optional: quantity, duration, weather, location, fertilizer, pesticides, tools''';
      case 'livestock':
        return '''
Essential: animalType, animalCount, activityDescription  
Optional: healthStatus, duration, feedType, feedQuantity, location, observations''';
      case 'equipment':
        return '''
Essential: equipmentName, workType, duration
Optional: condition, partsReplaced, cost, location, maintenanceNotes''';
      case 'harvest':
        return '''
Essential: cropHarvested, quantity, location
Optional: quality, duration, marketPrice, storageLocation, harvestMethod''';
      case 'maintenance':
        return '''
Essential: maintenanceArea, workDone, duration
Optional: materials, cost, completion, tools, weather''';
      case 'planning':
        return '''
Essential: planningType, timeframe, decisions
Optional: resources, budget, nextSteps, participants''';
      default:
        return '''Essential: activityDescription, duration
Optional: location, notes, outcome''';
    }
  }

  // Get JSON field structure for each activity type
  String _getFieldStructure(String activityType) {
    switch (activityType) {
      case 'crop_management':
        return '''
    "cropType": null,
    "areaCovered": null,
    "activityDescription": null,
    "quantity": null,
    "duration": null,
    "weather": null,
    "location": null,
    "fertilizer": null,
    "pesticides": null,
    "tools": null''';
      case 'livestock':
        return '''
    "animalType": null,
    "animalCount": null,
    "activityDescription": null,
    "healthStatus": null,
    "duration": null,
    "feedType": null,
    "feedQuantity": null,
    "location": null,
    "observations": null''';
      case 'equipment':
        return '''
    "equipmentName": null,
    "workType": null,
    "duration": null,
    "condition": null,
    "partsReplaced": null,
    "cost": null,
    "location": null,
    "maintenanceNotes": null''';
      case 'harvest':
        return '''
    "cropHarvested": null,
    "quantity": null,
    "location": null,
    "quality": null,
    "duration": null,
    "marketPrice": null,
    "storageLocation": null,
    "harvestMethod": null''';
      case 'maintenance':
        return '''
    "maintenanceArea": null,
    "workDone": null,
    "duration": null,
    "materials": null,
    "cost": null,
    "completion": null,
    "tools": null,
    "weather": null''';
      case 'planning':
        return '''
    "planningType": null,
    "timeframe": null,
    "decisions": null,
    "resources": null,
    "budget": null,
    "nextSteps": null,
    "participants": null''';
      default:
        return '''
    "activityDescription": null,
    "duration": null,
    "location": null,
    "notes": null,
    "outcome": null''';
    }
  }

  // Call Gemini API with enhanced error handling
  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': _geminiApiKey,
      };
      final body = json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
          'topP': 0.8,
          'topK': 40,
        },
      });
      print('🚀 Calling Gemini API...');
      final response = await http
          .post(Uri.parse(_geminiApiUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 45));
      print('📡 HTTP Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📥 Raw Gemini response: $responseData');
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          final generatedText =
              responseData['candidates'][0]['content']['parts'][0]['text'];
          print('📝 Generated text: $generatedText');
          // Clean and extract JSON from response
          String cleanedText =
              generatedText
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
          // Find JSON object in the response
          int startIndex = cleanedText.indexOf('{');
          int endIndex = cleanedText.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            final jsonString = cleanedText.substring(startIndex, endIndex + 1);
            print('🔍 Extracted JSON: $jsonString');
            try {
              final parsedData = json.decode(jsonString);
              print('✅ Successfully parsed JSON: $parsedData');
              return {'success': true, 'data': parsedData};
            } catch (jsonError) {
              print('❌ JSON parsing error: $jsonError');
              print('❌ Failed JSON string: $jsonString');
              // Try to fix common JSON issues
              String fixedJson = _attemptJsonFix(jsonString);
              try {
                final parsedData = json.decode(fixedJson);
                print('✅ Fixed and parsed JSON: $parsedData');
                return {'success': true, 'data': parsedData};
              } catch (e) {
                print('❌ Still failed after fix attempt: $e');
                return {
                  'success': false,
                  'error': 'Invalid JSON format in Gemini response: $jsonError',
                };
              }
            }
          } else {
            print('❌ No valid JSON structure found');
            return {
              'success': false,
              'error': 'No valid JSON structure found in response',
            };
          }
        } else {
          print('❌ Empty or malformed response structure');
          return {
            'success': false,
            'error': 'Empty or invalid response from Gemini',
          };
        }
      } else {
        final errorBody = response.body;
        print('❌ Gemini API Error: ${response.statusCode} - $errorBody');
        // Parse error details if available
        try {
          final errorData = json.decode(errorBody);
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown API error';
          return {
            'success': false,
            'error': 'Gemini API error (${response.statusCode}): $errorMessage',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Gemini API error: ${response.statusCode} - $errorBody',
          };
        }
      }
    } catch (e) {
      print('❌ Gemini API call failed: $e');
      return {
        'success': false,
        'error': 'Network error calling Gemini API: $e',
      };
    }
  }

  // Attempt to fix common JSON formatting issues
  String _attemptJsonFix(String jsonString) {
    String fixed = jsonString;
    // Remove any trailing commas before closing braces/brackets
    fixed = fixed.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1)!,
    );
    // Ensure proper quotes around field names
    fixed = fixed.replaceAllMapped(
      RegExp(r'(\w+):'),
      (match) => '"${match.group(1)}":',
    );
    // Fix null values that might be unquoted
    fixed = fixed.replaceAll(RegExp(r':\s*null\s*([,}])'), ': null\$1');
    return fixed;
  }

  // Validate extracted data completeness
  Map<String, dynamic> _validateActivityData(
    String activityType,
    Map<String, dynamic> extractedData,
  ) {
    List<String> requiredFields = _getRequiredFieldsList(activityType);
    List<String> missingFields = [];
    final data = extractedData['extractedData'] as Map<String, dynamic>? ?? {};
    for (String field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty ||
          data[field].toString().toLowerCase() == 'null') {
        missingFields.add(field);
      }
    }
    // Check completeness level
    String completeness =
        extractedData['completeness']?.toString() ?? 'partial';
    bool isComplete =
        missingFields.isEmpty &&
        (completeness == 'complete' || missingFields.length <= 1);
    print(
      '🔍 Validation - Required: $requiredFields, Missing: $missingFields, Complete: $isComplete',
    );
    return {
      'isValid': isComplete,
      'missingFields': missingFields,
      'completeness': completeness,
    };
  }

  // Get essential required fields list for validation - Updated with proper keys
  List<String> _getRequiredFieldsList(String activityType) {
    switch (activityType) {
      case 'crop_management':
        return ['cropType', 'areaCovered', 'activityDescription'];
      case 'livestock':
        return ['animalType', 'animalCount', 'activityDescription'];
      case 'equipment':
        return ['equipmentName', 'workType', 'duration'];
      case 'harvest':
        return [
          'cropHarvested',
          'quantity',
          'areaCovered',
          'profit',
        ]; // Updated for harvesting
      case 'maintenance':
        return ['maintenanceArea', 'workDone', 'duration'];
      case 'planning':
        return ['planningType', 'decisions', 'timeframe'];
      default:
        return ['activityDescription'];
    }
  }

  // Get dynamic questions based on missing keys
  String getDynamicQuestion(
    String fieldName,
    String activityType,
    String language,
  ) {
    // Map field names to localized question keys
    final questionMap = {
      'cropHarvested': 'botWhatCropHarvested',
      'quantity': 'botHowMuchQuantity',
      'areaCovered': 'botHowMuchArea',
      'profit': 'botApproximateProfit',
      'cropType': 'botWhatCropType',
      'animalType': 'botWhatAnimalType',
      'animalCount': 'botHowManyAnimals',
      'equipmentName': 'botWhichEquipment',
      'workType': 'botWhatWorkType',
      'activityDescription': 'botDescribeActivity',
    };

    // Return the localization key - will be resolved in the UI layer
    return questionMap[fieldName] ?? 'botDescribeActivity';
  }

  // Generate intelligent follow-up questions using dynamic system
  Future<String> generateFollowUpQuestion(
    String activityType,
    List<String> missingFields,
    String language,
  ) async {
    if (missingFields.isEmpty) {
      return _getCompletionMessage(language);
    }

    // Get the most important missing field (required fields first)
    String targetField = missingFields.first;

    // Get the localization key for this field
    String questionKey = getDynamicQuestion(
      targetField,
      activityType,
      language,
    );

    print(
      '✅ Generated dynamic question key: $questionKey for field: $targetField',
    );
    return questionKey; // Return the key to be resolved in the UI layer
  }

  String _getCompletionMessage(String language) {
    // Return localization key instead of hardcoded text
    return 'botActivityComplete';
  }

  // Save processed activity data to Firestore
  Future<void> saveVoiceProcessedActivity({
    required String activityType,
    required String selectedActivity,
    required Map<String, dynamic> processedData,
    required DateTime activityDateTime,
  }) async {
    try {
      print('💾 Starting to save activity...');
      print('📊 Processed data: $processedData');
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      final docRef =
          _firestore
              .collection('users')
              .doc(userId)
              .collection('activities')
              .doc();
      // Extract the data safely with proper type handling
      final dataMap = Map<String, dynamic>.from(processedData['data'] ?? {});
      final extractedData = Map<String, dynamic>.from(
        dataMap['extractedData'] ?? {},
      );
      // Prepare comprehensive activity data
      final data = {
        'id': docRef.id,
        'userId': userId,
        'activityType': activityType,
        'activity': selectedActivity,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('yyyy-MM-dd').format(activityDateTime),
        'activityDateTime': activityDateTime.toIso8601String(),
        'isCompleted': true,
        // Voice processing metadata - preserve original language
        'originalInput':
            dataMap['originalInput']?.toString() ??
            processedData['originalInput']?.toString() ??
            '',
        'translatedInput': dataMap['translatedInput']?.toString() ?? '',
        'originalLanguage': dataMap['originalLanguage']?.toString() ?? 'en',
        'confidence': dataMap['confidence']?.toString() ?? 'medium',
        'completeness': dataMap['completeness']?.toString() ?? 'partial',
        // Extracted structured data - clean null values
        'extractedData': _cleanExtractedData(extractedData),
        'notes': dataMap['notes']?.toString() ?? '',
        // System metadata
        'processingMethod': 'voice_gemini',
        'apiVersion': 'gemini-pro',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Analytics data
        'processingTime': DateTime.now().millisecondsSinceEpoch,
        'version': '2.1',
      };
      print('💾 Saving data to Firestore: $data');
      await docRef.set(data);
      await markDailyPromptCompleted();
      print(
        '✅ Voice-processed activity saved successfully with ID: ${docRef.id}',
      );
    } catch (e) {
      print('❌ Error saving voice-processed activity: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Failed to save activity: $e');
    }
  }

  // Clean extracted data to remove null/empty values
  Map<String, dynamic> _cleanExtractedData(Map<String, dynamic> extractedData) {
    Map<String, dynamic> cleaned = {};
    extractedData.forEach((key, value) {
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != 'null') {
        cleaned[key] = value;
      }
    });
    return cleaned;
  }

  // Additional service methods...
  Future<bool> shouldShowDailyPrompt() async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) return false;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('dailyPrompts')
              .doc(today)
              .get();
      if (!doc.exists) return true;
      final data = doc.data()!;
      final completed = data['completed'] ?? false;
      final skipped = data['skipped'] ?? false;
      return !(completed || skipped);
    } catch (e) {
      print('❌ Error checking daily prompt status: $e');
      return false;
    }
  }

  Future<List<ActivitySuggestion>> getSuggestionsByType(
    String activityType,
  ) async {
    try {
      switch (activityType) {
        case 'crop_management':
          return [
            ActivitySuggestion(
              activity: 'Health checkup',
              icon: '🩺',
              description:
                  'Monitor animal health, check for symptoms, and record vitals',
              priority: 'High',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Vaccination',
              icon: '💉',
              description:
                  'Administer scheduled vaccines and record batch numbers',
              priority: 'High',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Clean shelter',
              icon: '🧹',
              description:
                  'Clean housing, replenish bedding, and disinfect where needed',
              priority: 'Medium',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Record births/deaths',
              icon: '📋',
              description:
                  'Log any births, deaths or major events for herd records',
              priority: 'High',
              category: 'livestock',
            ),
          ];
        case 'equipment':
          return [
            ActivitySuggestion(
              activity: 'Routine lubrication',
              icon: '🛠️',
              description: 'Lubricate moving parts and check oil levels',
              priority: 'Medium',
              category: 'equipment',
            ),
            ActivitySuggestion(
              activity: 'Calibration check',
              icon: '⚙️',
              description:
                  'Verify calibration of sprayers/seeders/measurement tools',
              priority: 'Medium',
              category: 'equipment',
            ),
            ActivitySuggestion(
              activity: 'Replace worn parts',
              icon: '🔩',
              description:
                  'Inspect and replace belts, blades, and filters as needed',
              priority: 'High',
              category: 'equipment',
            ),
            ActivitySuggestion(
              activity: 'Safety inspection',
              icon: '✅',
              description:
                  'Check guards, brakes and safety equipment before use',
              priority: 'High',
              category: 'equipment',
            ),
          ];
        case 'harvest':
          return [
            ActivitySuggestion(
              activity: 'Harvest collection',
              icon: '🌾',
              description: 'Collect mature crops and move to temporary storage',
              priority: 'High',
              category: 'harvest',
            ),
            ActivitySuggestion(
              activity: 'Quality grading',
              icon: '📊',
              description: 'Sort harvest by quality and note any defects',
              priority: 'Medium',
              category: 'harvest',
            ),
            ActivitySuggestion(
              activity: 'Weigh & record',
              icon: '⚖️',
              description: 'Weigh produce and record quantities for inventory',
              priority: 'High',
              category: 'harvest',
            ),
            ActivitySuggestion(
              activity: 'Transport to market/storage',
              icon: '🚚',
              description: 'Arrange transport and verify storage conditions',
              priority: 'High',
              category: 'harvest',
            ),
          ];
        case 'maintenance':
          return [
            ActivitySuggestion(
              activity: 'Fence repair',
              icon: '🔧',
              description:
                  'Repair broken fences and gates to secure fields/animals',
              priority: 'Medium',
              category: 'maintenance',
            ),
            ActivitySuggestion(
              activity: 'Irrigation check',
              icon: '💦',
              description:
                  'Inspect drip lines, sprinklers and pumps for leaks/blockages',
              priority: 'High',
              category: 'maintenance',
            ),
            ActivitySuggestion(
              activity: 'Drainage clearing',
              icon: '🪣',
              description: 'Clear drains and ditches to prevent waterlogging',
              priority: 'Medium',
              category: 'maintenance',
            ),
            ActivitySuggestion(
              activity: 'Tool inventory',
              icon: '📦',
              description: 'Check tools, repair or replace broken items',
              priority: 'Low',
              category: 'maintenance',
            ),
          ];
        case 'planning':
          return [
            ActivitySuggestion(
              activity: 'Crop rotation plan',
              icon: '🗓️',
              description:
                  'Plan next season\'s crop rotation and field assignments',
              priority: 'Medium',
              category: 'planning',
            ),
            ActivitySuggestion(
              activity: 'Budget review',
              icon: '💰',
              description:
                  'Review available funds, expected costs and allocations',
              priority: 'High',
              category: 'planning',
            ),
            ActivitySuggestion(
              activity: 'Supplier coordination',
              icon: '📞',
              description:
                  'Contact suppliers for seeds, fertilizers, and equipment',
              priority: 'Medium',
              category: 'planning',
            ),
            ActivitySuggestion(
              activity: 'Training session',
              icon: '🎓',
              description:
                  'Plan training for workers on new practices or tools',
              priority: 'Low',
              category: 'planning',
            ),
          ];
        case 'livestock':
          return [
            ActivitySuggestion(
              activity: 'Animal feeding',
              icon: '🥬',
              description: 'Provide food and water to animals',
              priority: 'High',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Health checkup',
              icon: '🩺',
              description:
                  'Monitor animal health, check for symptoms, and record vitals',
              priority: 'High',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Vaccination',
              icon: '💉',
              description:
                  'Administer scheduled vaccines and record batch numbers',
              priority: 'High',
              category: 'livestock',
            ),
            ActivitySuggestion(
              activity: 'Clean shelter',
              icon: '🧹',
              description:
                  'Clean housing, replenish bedding, and disinfect where needed',
              priority: 'Medium',
              category: 'livestock',
            ),
          ];
        default:
          return [
            ActivitySuggestion(
              activity: 'Log general activity',
              icon: '✍️',
              description:
                  'Describe the task performed (what, where, how long)',
              priority: 'Medium',
              category: 'general',
            ),
            ActivitySuggestion(
              activity: 'Take field notes',
              icon: '📝',
              description: 'Record observations about soil, pests, or weather',
              priority: 'Low',
              category: 'general',
            ),
          ];
      }
    } catch (e) {
      print('❌ Error fetching suggestions for $activityType: $e');
      return [];
    }
  }

  // Mark today's daily prompt as completed
  Future<void> markDailyPromptCompleted() async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        print('❌ Cannot mark daily prompt completed: user not logged in');
        return;
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPrompts')
          .doc(today);
      await docRef.set({
        'completed': true,
        'skipped': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ Marked daily prompt completed for $userId on $today');
    } catch (e) {
      print('❌ Error marking daily prompt completed: $e');
    }
  }

  // Mark today's daily prompt as skipped
  Future<void> markDailyPromptSkipped() async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        print('❌ Cannot mark daily prompt skipped: user not logged in');
        return;
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPrompts')
          .doc(today);
      await docRef.set({
        'completed': false,
        'skipped': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ Marked daily prompt skipped for $userId on $today');
    } catch (e) {
      print('❌ Error marking daily prompt skipped: $e');
    }
  }

  // Get recent activities for analytics
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 10,
    String? activityType,
  }) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true);
      if (activityType != null) {
        query = query.where('activityType', isEqualTo: activityType);
      }
      query = query.limit(limit);
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error fetching recent activities: $e');
      return [];
    }
  }

  // Get activity statistics
  Future<Map<String, dynamic>> getActivityStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end);
      final snapshot = await query.get();
      final activities =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
      Map<String, int> typeCount = {};
      Map<String, int> languageCount = {};
      int voiceProcessed = 0;
      double totalConfidence = 0;
      int confidenceCount = 0;
      for (final activity in activities) {
        // Count by activity type
        final type = activity['activityType']?.toString() ?? 'unknown';
        typeCount[type] = (typeCount[type] ?? 0) + 1;
        // Count by language
        final language = activity['originalLanguage']?.toString() ?? 'en';
        languageCount[language] = (languageCount[language] ?? 0) + 1;
        // Count voice processed activities
        if (activity['processingMethod'] == 'voice_gemini') {
          voiceProcessed++;
        }
        // Calculate average confidence
        final confidenceStr = activity['confidence']?.toString();
        if (confidenceStr != null) {
          double confidence = 0.5; // default medium confidence
          switch (confidenceStr) {
            case 'high':
              confidence = 0.9;
              break;
            case 'medium':
              confidence = 0.6;
              break;
            case 'low':
              confidence = 0.3;
              break;
          }
          totalConfidence += confidence;
          confidenceCount++;
        }
      }
      return {
        'totalActivities': activities.length,
        'voiceProcessedActivities': voiceProcessed,
        'averageConfidence':
            confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0,
        'activityTypeBreakdown': typeCount,
        'languageBreakdown': languageCount,
        'dateRange': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ Error fetching activity statistics: $e');
      return {
        'totalActivities': 0,
        'voiceProcessedActivities': 0,
        'averageConfidence': 0.0,
        'activityTypeBreakdown': {},
        'languageBreakdown': {},
        'error': e.toString(),
      };
    }
  }

  // Update activity data
  Future<void> updateActivity({
    required String activityId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityId);
      await docRef.update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Activity updated successfully: $activityId');
    } catch (e) {
      print('❌ Error updating activity: $e');
      throw Exception('Failed to update activity: $e');
    }
  }

  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .delete();
      print('✅ Activity deleted successfully: $activityId');
    } catch (e) {
      print('❌ Error deleting activity: $e');
      throw Exception('Failed to delete activity: $e');
    }
  }

  // Search activities
  Future<List<Map<String, dynamic>>> searchActivities({
    required String searchTerm,
    String? activityType,
    int limit = 50,
  }) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true);
      if (activityType != null) {
        query = query.where('activityType', isEqualTo: activityType);
      }
      query = query.limit(limit);
      final snapshot = await query.get();
      final activities =
          snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();
      // Filter by search term (client-side filtering since Firestore has limited text search)
      final filtered =
          activities.where((activity) {
            final searchLower = searchTerm.toLowerCase();
            final originalInput =
                (activity['originalInput']?.toString() ?? '').toLowerCase();
            final translatedInput =
                (activity['translatedInput']?.toString() ?? '').toLowerCase();
            final notes = (activity['notes']?.toString() ?? '').toLowerCase();
            final activityName =
                (activity['activity']?.toString() ?? '').toLowerCase();
            return originalInput.contains(searchLower) ||
                translatedInput.contains(searchLower) ||
                notes.contains(searchLower) ||
                activityName.contains(searchLower);
          }).toList();
      return filtered;
    } catch (e) {
      print('❌ Error searching activities: $e');
      return [];
    }
  }

  // Export activities to CSV format
  Future<String> exportActivitiesToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? activityType,
  }) async {
    try {
      final userId = SessionManager.instance.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (activityType != null) {
        query = query.where('activityType', isEqualTo: activityType);
      }

      final snapshot = await query.get();
      final activities =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      // Create CSV header
      String csv =
          'Date,Activity Type,Activity,Original Input,Translated Input,Language,Confidence,Completeness,Notes\n';

      // Add data rows
      for (final activity in activities) {
        final date = activity['date']?.toString() ?? '';
        final actType = activity['activityType']?.toString() ?? '';
        final activityName = activity['activity']?.toString() ?? '';

        final originalInput = (activity['originalInput']?.toString() ?? '')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ');

        final translatedInput = (activity['translatedInput']?.toString() ?? '')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ');

        final language = activity['originalLanguage']?.toString() ?? '';
        final confidence = activity['confidence']?.toString() ?? '';
        final completeness = activity['completeness']?.toString() ?? '';

        final notes = (activity['notes']?.toString() ?? '')
            .replaceAll(',', ';')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ');

        csv +=
            '$date,$actType,$activityName,$originalInput,$translatedInput,$language,$confidence,$completeness,$notes\n';
      }

      return csv;
    } catch (e) {
      print('❌ Error exporting activities to CSV: $e');
      throw Exception('Failed to export activities: $e');
    }
  }

  // Dispose resources
  void dispose() {
    // Clean up any resources if needed
    _initialized = false;
  }

  Future<List<Map<String, dynamic>>> getUserActivities({
    required String userId,
    int limit = 50,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
