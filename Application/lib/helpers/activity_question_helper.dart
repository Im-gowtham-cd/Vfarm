// ActivityQuestionHelper - manages dynamic questions for different activities
class ActivityQuestionHelper {
  static final ActivityQuestionHelper _instance = ActivityQuestionHelper._internal();
  static ActivityQuestionHelper get instance => _instance;
  ActivityQuestionHelper._internal();
  
  
  Map<String, ActivityQuestion> getQuestionsForActivity(String activityType) {
    switch (activityType) {
      case 'harvest':
        return _getHarvestQuestions();
      case 'crop_management':
        return _getCropManagementQuestions();
      case 'livestock':
        return _getLivestockQuestions();
      case 'equipment':
        return _getEquipmentQuestions();
      case 'maintenance':
        return _getMaintenanceQuestions();
      case 'planning':
        return _getPlanningQuestions();
      default:
        return _getGeneralQuestions();
    }
  }
  
  // Get the next missing question for an activity
  ActivityQuestion? getNextMissingQuestion(String activityType, Map<String, dynamic> currentData) {
    final questions = getQuestionsForActivity(activityType);
    
    for (final question in questions.values) {
      if (question.isRequired && !_hasValidValue(currentData, question.fieldName)) {
        return question;
      }
    }
    
    // If all required fields are filled, check optional ones
    for (final question in questions.values) {
      if (!question.isRequired && !_hasValidValue(currentData, question.fieldName)) {
        return question;
      }
    }
    
    return null;
  }
  
  // Check if activity data is complete
  bool isActivityComplete(String activityType, Map<String, dynamic> currentData) {
    final questions = getQuestionsForActivity(activityType);
    
    for (final question in questions.values) {
      if (question.isRequired && !_hasValidValue(currentData, question.fieldName)) {
        return false;
      }
    }
    
    return true;
  }
  
  // Get missing required fields
  List<String> getMissingRequiredFields(String activityType, Map<String, dynamic> currentData) {
    final questions = getQuestionsForActivity(activityType);
    final missing = <String>[];
    
    for (final question in questions.values) {
      if (question.isRequired && !_hasValidValue(currentData, question.fieldName)) {
        missing.add(question.fieldName);
      }
    }
    
    return missing;
  }
  
  // Get localized question text
  String getLocalizedQuestion(ActivityQuestion question, String languageCode) {
    return question.getLocalizedText(languageCode);
  }
  
  bool _hasValidValue(Map<String, dynamic> data, String fieldName) {
    final value = data[fieldName];
    return value != null && 
           value.toString().trim().isNotEmpty && 
           value.toString().toLowerCase() != 'null';
  }
  
  Map<String, ActivityQuestion> _getHarvestQuestions() {
    return {
      'cropHarvested': ActivityQuestion(
        fieldName: 'cropHarvested',
        isRequired: true,
        questionTexts: {
          'en': 'What crop did you harvest?',
          'hi': 'आपने कौन सी फसल की कटाई की?',
          'ta': 'நீங்கள் எந்த பயிரை அறுவடை செய்தீர்கள்?',
          'ml': 'നിങ്ങൾ ഏത് വിള വിളവെടുത്തു?',
          'te': 'మీరు ఏ పంటను కోశారు?',
        },
      ),
      'quantity': ActivityQuestion(
        fieldName: 'quantity',
        isRequired: true,
        questionTexts: {
          'en': 'How much quantity did you harvest? Please specify the amount and unit.',
          'hi': 'आपने कितनी मात्रा में फसल काटी? कृपया मात्रा और इकाई बताएं।',
          'ta': 'எவ்வளவு அளவு அறுவடை செய்தீர்கள்? தயவுசெய்து அளவு மற்றும் அலகு குறிப்பிடுங்கள்.',
          'ml': 'എത്ര അളവ് വിളവെടുത്തു? അളവും യൂണിറ്റും വ്യക്തമാക്കുക.',
          'te': 'మీరు ఎంత పరిమాణంలో కోశారు? దయచేసి మొత్తం మరియు యూనిట్‌ను పేర్కొనండి.',
        },
      ),
      'profit': ActivityQuestion(
        fieldName: 'profit',
        isRequired: false,
        questionTexts: {
          'en': 'What is the approximate profit from this harvest?',
          'hi': 'इस फसल से अनुमानित लाभ क्या है?',
          'ta': 'இந்த அறுவடையிலிருந்து தோராயமான லாபம் என்ன?',
          'ml': 'ഈ വിളവെടുപ്പിൽ നിന്നുള്ള ഏകദേശ ലാഭം എന്താണ്?',
          'te': 'ఈ పంట నుండి సుమారు లాభం ఎంత?',
        },
      ),
      'usage': ActivityQuestion(
        fieldName: 'usage',
        isRequired: false,
        questionTexts: {
          'en': 'What did you do with the harvested crop?',
          'hi': 'कटी हुई फसल का आपने क्या किया?',
          'ta': 'அறுவடை செய்த பயிருடன் நீங்கள் என்ன செய்தீர்கள்?',
          'ml': 'വിളവെടുത്ത വിളകൊണ്ട് നിങ്ങൾ എന്താണ് ചെയ്തത്?',
          'te': 'కోసిన పంటతో మీరు ఏమి చేశారు?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getCropManagementQuestions() {
    return {
      'cropType': ActivityQuestion(
        fieldName: 'cropType',
        isRequired: true,
        questionTexts: {
          'en': 'What type of crop were you working with?',
          'hi': 'आप किस प्रकार की फसल पर काम कर रहे थे?',
          'ta': 'நீங்கள் எந்த வகையான பயிருடன் வேலை செய்து கொண்டிருந்தீர்கள்?',
          'ml': 'നിങ്ങൾ ഏത് തരം വിളയിൽ പ്രവർത്തിച്ചു?',
          'te': 'మీరు ఏ రకమైన పంటతో పని చేస్తున్నారు?',
        },
      ),
      'areaCovered': ActivityQuestion(
        fieldName: 'areaCovered',
        isRequired: false,
        questionTexts: {
          'en': 'How much area did you cover? Please mention in acres or square feet.',
          'hi': 'आपने कितना क्षेत्र कवर किया? कृपया एकड़ या वर्ग फुट में बताएं।',
          'ta': 'நீங்கள் எவ்வளவு பகுதியை மூடினீர்கள்? ஏக்கர் அல்லது சதுர அடியில் குறிப்பிடுங்கள்.',
          'ml': 'എത്ര സ്ഥലം കവർ ചെയ്തു? ഏക്കറിലോ ചതുരശ്ര അടിയിലോ പറയുക.',
          'te': 'మీరు ఎంత ప్రాంతాన్ని కవర్ చేశారు? దయచేసి ఎకరాలు లేదా చదరపు అడుగులలో పేర్కొనండి.',
        },
      ),
      'seedType': ActivityQuestion(
        fieldName: 'seedType',
        isRequired: false,
        questionTexts: {
          'en': 'What type of seeds did you use?',
          'hi': 'आपने किस प्रकार के बीज का उपयोग किया?',
          'ta': 'நீங்கள் எந்த வகையான விதைகளைப் பயன்படுத்தினீர்கள்?',
          'ml': 'നിങ്ങൾ ഏത് തരം വിത്തുകൾ ഉപയോഗിച്ചു?',
          'te': 'మీరు ఏ రకమైన విత్తనాలను ఉపయోగించారు?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getLivestockQuestions() {
    return {
      'animalType': ActivityQuestion(
        fieldName: 'animalType',
        isRequired: true,
        questionTexts: {
          'en': 'What type of animals were you caring for?',
          'hi': 'आप किस प्रकार के जानवरों की देखभाल कर रहे थे?',
          'ta': 'நீங்கள் எந்த வகையான விலங்குகளைப் பராமரித்துக் கொண்டிருந்தீர்கள்?',
          'ml': 'നിങ്ങൾ ഏത് തരം മൃഗങ്ങളെ പരിപാലിച്ചു?',
          'te': 'మీరు ఏ రకమైన జంతువులను చూసుకుంటున్నారు?',
        },
      ),
      'animalCount': ActivityQuestion(
        fieldName: 'animalCount',
        isRequired: false,
        questionTexts: {
          'en': 'How many animals were involved?',
          'hi': 'कितने जानवर शामिल थे?',
          'ta': 'எத்தனை விலங்குகள் ஈடுபட்டன?',
          'ml': 'എത്ര മൃഗങ്ങൾ ഉൾപ്പെട്ടിരുന്നു?',
          'te': 'ఎన్ని జంతువులు పాల్గొన్నాయి?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getEquipmentQuestions() {
    return {
      'equipmentName': ActivityQuestion(
        fieldName: 'equipmentName',
        isRequired: true,
        questionTexts: {
          'en': 'Which equipment or tool did you use?',
          'hi': 'आपने कौन सा उपकरण या टूल इस्तेमाल किया?',
          'ta': 'நீங்கள் எந்த உபகரணம் அல்லது கருவியைப் பயன்படுத்தினீர்கள்?',
          'ml': 'ഏത് ഉപകരണമോ ടൂളോ ഉപയോഗിച്ചു?',
          'te': 'మీరు ఏ పరికరం లేదా సాధనాన్ని ఉపయోగించారు?',
        },
      ),
      'workType': ActivityQuestion(
        fieldName: 'workType',
        isRequired: true,
        questionTexts: {
          'en': 'What kind of work or maintenance did you do?',
          'hi': 'आपने किस प्रकार का काम या रखरखाव किया?',
          'ta': 'நீங்கள் எந்த வகையான வேலை அல்லது பராமரிப்பு செய்தீர்கள்?',
          'ml': 'ഏത് തരം ജോലിയോ അറ്റകുറ്റപ്പണിയോ ചെയ്തു?',
          'te': 'మీరు ఏ రకమైన పని లేదా నిర్వహణ చేశారు?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getMaintenanceQuestions() {
    return {
      'maintenanceArea': ActivityQuestion(
        fieldName: 'maintenanceArea',
        isRequired: true,
        questionTexts: {
          'en': 'Which area or structure did you maintain?',
          'hi': 'आपने किस क्षेत्र या संरचना का रखरखाव किया?',
          'ta': 'நீங்கள் எந்த பகுதி அல்லது கட்டமைப்பைப் பராமரித்தீர்கள்?',
          'ml': 'ഏത് പ്രദേശമോ ഘടനയോ പരിപാലിച്ചു?',
          'te': 'మీరు ఏ ప్రాంతం లేదా నిర్మాణాన్ని నిర్వహించారు?',
        },
      ),
      'workDone': ActivityQuestion(
        fieldName: 'workDone',
        isRequired: true,
        questionTexts: {
          'en': 'What specific work did you do?',
          'hi': 'आपने कौन सा विशिष्ट काम किया?',
          'ta': 'நீங்கள் என்ன குறிப்பிட்ட வேலை செய்தீர்கள்?',
          'ml': 'നിങ്ങൾ എന്ത് പ്രത്യേക ജോലി ചെയ്തു?',
          'te': 'మీరు ఏ నిర్దిష్ట పని చేశారు?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getPlanningQuestions() {
    return {
      'planningType': ActivityQuestion(
        fieldName: 'planningType',
        isRequired: true,
        questionTexts: {
          'en': 'What kind of planning did you do?',
          'hi': 'आपने किस प्रकार की योजना बनाई?',
          'ta': 'நீங்கள் என்ன வகையான திட்டமிடல் செய்தீர்கள்?',
          'ml': 'നിങ്ങൾ ഏത് തരത്തിലുള്ള ആസൂത്രണം ചെയ്തു?',
          'te': 'మీరు ఏ రకమైన ప్రణాళిక చేశారు?',
        },
      ),
      'decisions': ActivityQuestion(
        fieldName: 'decisions',
        isRequired: true,
        questionTexts: {
          'en': 'What decisions did you make?',
          'hi': 'आपने कौन से निर्णय लिए?',
          'ta': 'நீங்கள் என்ன முடிவுகளை எடுத்தீர்கள்?',
          'ml': 'നിങ്ങൾ എന്ത് തീരുമാനങ്ങൾ എടുത്തു?',
          'te': 'మీరు ఏ నిర్ణయాలు తీసుకున్నారు?',
        },
      ),
    };
  }
  
  Map<String, ActivityQuestion> _getGeneralQuestions() {
    return {
      'activityDescription': ActivityQuestion(
        fieldName: 'activityDescription',
        isRequired: true,
        questionTexts: {
          'en': 'Can you describe what you did in more detail?',
          'hi': 'आप जो काम किया उसे और विस्तार से बता सकते हैं?',
          'ta': 'நீங்கள் செய்ததை இன்னும் விரிவாக விவரிக்க முடியுமா?',
          'ml': 'നിങ്ങൾ ചെയ്ത കാര്യം കൂടുതൽ വിശദമായി പറയാമോ?',
          'te': 'మీరు చేసిన పనిని మరింత వివరంగా వర్ణించగలరా?',
        },
      ),
    };
  }
}

// ActivityQuestion model for storing question data
class ActivityQuestion {
  final String fieldName;
  final bool isRequired;
  final Map<String, String> questionTexts;
  
  ActivityQuestion({
    required this.fieldName,
    required this.isRequired,
    required this.questionTexts,
  });
  
  String getLocalizedText(String languageCode) {
    return questionTexts[languageCode] ?? questionTexts['en'] ?? 'Please provide more information about $fieldName';
  }
}

// Translation helper for dynamic questions
class TranslationHelper {
  static final TranslationHelper _instance = TranslationHelper._internal();
  static TranslationHelper get instance => _instance;
  TranslationHelper._internal();
  
  // Get localized follow-up question
  String getLocalizedFollowUpQuestion(String fieldName, String activityType, String languageCode) {
    final questions = ActivityQuestionHelper.instance.getQuestionsForActivity(activityType);
    final question = questions[fieldName];
    
    if (question != null) {
      return question.getLocalizedText(languageCode);
    }
    
    // Fallback questions
    return _getFallbackQuestion(fieldName, languageCode);
  }
  
  String _getFallbackQuestion(String fieldName, String languageCode) {
    final fallbackQuestions = {
      'en': {
        'cropType': 'What type of crop were you working with?',
        'quantity': 'How much quantity was involved? Please specify the amount and unit.',
        'animalType': 'What type of animals were you caring for?',
        'equipmentName': 'Which equipment or tool did you use?',
        'duration': 'How much time did you spend on this activity?',
        'location': 'Which field or area were you working in?',
      },
      'hi': {
        'cropType': 'आप किस प्रकार की फसल पर काम कर रहे थे?',
        'quantity': 'कितनी मात्रा शामिल थी? कृपया मात्रा और इकाई स्पष्ट करें।',
        'animalType': 'आप किस प्रकार के जानवरों की देखभाल कर रहे थे?',
        'equipmentName': 'आपने कौन सा उपकरण या टूल इस्तेमाल किया?',
        'duration': 'इस गतिविधि में आपने कितना समय बिताया?',
        'location': 'आप किस खेत या क्षेत्र में काम कर रहे थे?',
      },
      'ta': {
        'cropType': 'நீங்கள் எந்த வகையான பயிருடன் வேலை செய்து கொண்டிருந்தீர்கள்?',
        'quantity': 'எவ்வளவு அளவு ஈடுபட்டது? தயவுசெய்து அளவு மற்றும் அலகு குறிப்பிடுங்கள்.',
        'animalType': 'நீங்கள் எந்த வகையான விலங்குகளைப் பராமரித்துக் கொண்டிருந்தீர்கள்?',
        'equipmentName': 'நீங்கள் எந்த உபகரணம் அல்லது கருவியைப் பயன்படுத்தினீர்கள்?',
        'duration': 'இந்த செயல்பாட்டில் நீங்கள் எவ்வளவு நேரம் செலவிட்டீர்கள்?',
        'location': 'நீங்கள் எந்த வயல் அல்லது பகுதியில் வேலை செய்து கொண்டிருந்தீர்கள்?',
      },
      'ml': {
        'cropType': 'നിങ്ങൾ ഏത് തരം വിളയിൽ പ്രവർത്തിച്ചു?',
        'quantity': 'എത്ര അളവ് ഉൾപ്പെട്ടിരുന്നു? അളവും യൂണിറ്റും വ്യക്തമാക്കുക.',
        'animalType': 'നിങ്ങൾ ഏത് തരം മൃഗങ്ങളെ പരിപാലിച്ചു?',
        'equipmentName': 'ഏത് ഉപകരണമോ ടൂളോ ഉപയോഗിച്ചു?',
        'duration': 'ഈ പ്രവർത്തനത്തിന് എത്ര സമയം ചിലവാക്കി?',
        'location': 'ഏത് വയലിലോ സ്ഥലത്തോ പ്രവർത്തിച്ചു?',
      },
      'te': {
        'cropType': 'మీరు ఏ రకమైన పంటతో పని చేస్తున్నారు?',
        'quantity': 'ఎంత పరిమాణం పాల్గొంది? దయచేసి మొత్తం మరియు యూనిట్‌ను పేర్కొనండి.',
        'animalType': 'మీరు ఏ రకమైన జంతువులను చూసుకుంటున్నారు?',
        'equipmentName': 'మీరు ఏ పరికరం లేదా సాధనాన్ని ఉపయోగించారు?',
        'duration': 'ఈ కార్యకలాపంలో మీరు ఎంత సమయం గడిపారు?',
        'location': 'మీరు ఏ పొలం లేదా ప్రాంతంలో పని చేస్తున్నారు?',
      },
    };
    
    final lang = ['hi', 'ta', 'ml', 'te'].contains(languageCode) ? languageCode : 'en';
    return fallbackQuestions[lang]?[fieldName] ?? 
           fallbackQuestions['en']?[fieldName] ?? 
           'Can you provide more details about $fieldName?';
  }
}
