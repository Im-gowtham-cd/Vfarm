import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  static TranslationService get instance => _instance;
  TranslationService._internal();

  
  static const String _apiKey = 'AIzaSyBxMR_UiyPHgeAZ99FUMUvj2IEd5dGK30M';
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  // Auto-detect and translate user input to English for processing
  Future<Map<String, dynamic>> translateToEnglish(String text) async {
    if (_isEnglish(text)) {
      return {
        'translatedText': text,
        'detectedLanguage': 'en',
        'originalText': text,
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'target': 'en',
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation = data['data']['translations'][0];
        
        return {
          'translatedText': translation['translatedText'],
          'detectedLanguage': translation['detectedSourceLanguage'],
          'originalText': text,
        };
      } else {
        throw Exception('Translation API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Translation error: $e');
      // Fallback to original text if translation fails
      return {
        'translatedText': text,
        'detectedLanguage': _detectLanguageCode(text),
        'originalText': text,
      };
    }
  }

  // Translate text from English to target language
  Future<String> translateFromEnglish(String text, String targetLanguage) async {
    if (targetLanguage == 'en') {
      return text;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': 'en',
          'target': targetLanguage,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['translations'][0]['translatedText'];
      } else {
        throw Exception('Translation API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Translation error: $e');
      return text; // Fallback to original text
    }
  }

  // Simple language detection based on Unicode ranges
  String _detectLanguageCode(String text) {
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) return 'ml'; // Malayalam
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'hi'; // Hindi
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'ta'; // Tamil
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)) return 'te'; // Telugu
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) return 'kn'; // Kannada
    return 'en'; // Default to English
  }

  // Check if text is primarily English
  bool _isEnglish(String text) {
    // Simple heuristic: if most characters are ASCII, assume English
    int asciiCount = 0;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) < 128) {
        asciiCount++;
      }
    }
    return asciiCount / text.length > 0.7;
  }

  // Get language name from code
  String getLanguageName(String code) {
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
      case 'en':
      default:
        return 'English';
    }
  }

  // Offline translation for common farming terms
  Map<String, Map<String, String>> _offlineTranslations = {
    'en': {
      'crop': 'crop',
      'harvest': 'harvest',
      'plant': 'plant',
      'water': 'water',
      'fertilizer': 'fertilizer',
      'seed': 'seed',
      'field': 'field',
      'farm': 'farm',
      'animal': 'animal',
      'cow': 'cow',
      'goat': 'goat',
      'chicken': 'chicken',
    },
    'hi': {
      'crop': 'फसल',
      'harvest': 'कटाई',
      'plant': 'पौधा',
      'water': 'पानी',
      'fertilizer': 'उर्वरक',
      'seed': 'बीज',
      'field': 'खेत',
      'farm': 'खेत',
      'animal': 'जानवर',
      'cow': 'गाय',
      'goat': 'बकरी',
      'chicken': 'मुर्गी',
    },
    'ta': {
      'crop': 'பயிர்',
      'harvest': 'அறுவடை',
      'plant': 'தாவரம்',
      'water': 'தண்ணீர்',
      'fertilizer': 'உரம்',
      'seed': 'விதை',
      'field': 'வயல்',
      'farm': 'பண்ணை',
      'animal': 'விலங்கு',
      'cow': 'பசு',
      'goat': 'ஆடு',
      'chicken': 'கோழி',
    },
    'ml': {
      'crop': 'വിള',
      'harvest': 'വിളവെടുപ്പ്',
      'plant': 'ചെടി',
      'water': 'വെള്ളം',
      'fertilizer': 'വളം',
      'seed': 'വിത്ത്',
      'field': 'വയൽ',
      'farm': 'കൃഷിയിടം',
      'animal': 'മൃഗം',
      'cow': 'പശു',
      'goat': 'ആട്',
      'chicken': 'കോഴി',
    },
    'te': {
      'crop': 'పంట',
      'harvest': 'కోత',
      'plant': 'మొక్క',
      'water': 'నీరు',
      'fertilizer': 'ఎరువు',
      'seed': 'విత్తనం',
      'field': 'పొలం',
      'farm': 'వ్యవసాయం',
      'animal': 'జంతువు',
      'cow': 'ఆవు',
      'goat': 'మేక',
      'chicken': 'కోడి',
    },
  };

  // Get offline translation for common terms
  String getOfflineTranslation(String term, String targetLanguage) {
    final translations = _offlineTranslations[targetLanguage];
    return translations?[term.toLowerCase()] ?? term;
  }
}
