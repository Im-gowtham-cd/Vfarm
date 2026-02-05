import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'dart:async';

class LocaleManager extends ChangeNotifier {
  static LocaleManager? _instance;
  static LocaleManager get instance => _instance ??= LocaleManager._();

  LocaleManager._();

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  static const String _localeKey = 'selected_locale';
  static const String _firstLaunchKey = 'is_first_launch';

  // Initialize locale from saved preferences or auto-detect from geolocation
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch) {
      // First launch - detect language from geolocation
      final detectedLocale = await _detectLocaleFromGeolocation();
      if (detectedLocale != null) {
        _currentLocale = detectedLocale;
        await prefs.setString(_localeKey, detectedLocale.languageCode);
      } else {
        // Fallback to system locale or English
        final systemLocale = _getSystemLocale();
        final localeCode =
            _isSupportedLocale(systemLocale) ? systemLocale : 'en';
        _currentLocale = Locale(localeCode);
        await prefs.setString(_localeKey, localeCode);
      }
      await prefs.setBool(_firstLaunchKey, false);
    } else {
      // Not first launch - use saved preference
      final localeCode = prefs.getString(_localeKey) ?? 'en';
      _currentLocale = Locale(localeCode);
    }
    notifyListeners();
  }

  // Change locale and save to preferences
  Future<void> changeLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  // Get available locales
  List<Locale> get supportedLocales => const [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('es'), // Spanish
    Locale('ta'), // Tamil
    Locale('te'), // Telugu
    Locale('mr'), // Marathi
    Locale('ml'), // Malayalam
    Locale('gu'), // Gujarati
  ];

  // Get locale display names
  Map<String, String> get localeDisplayNames => {
    'en': 'English',
    'hi': 'हिंदी',
    'es': 'Español',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'mr': 'मराठी',
    'ml': 'മലയാളം',
    'gu': 'ગુજરાતી',
  };

  String getLocaleDisplayName(String languageCode) {
    return localeDisplayNames[languageCode] ?? languageCode;
  }

  // Get system locale
  String _getSystemLocale() {
    try {
      final locale = Platform.localeName;
      return locale.split(
        '_',
      )[0]; // Get language code (e.g., 'en' from 'en_US')
    } catch (e) {
      return 'en';
    }
  }

  // Check if locale is supported
  bool _isSupportedLocale(String languageCode) {
    return supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
  }

  // Detect locale from geolocation
  Future<Locale?> _detectLocaleFromGeolocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      // Determine language based on coordinates
      return _getLocaleFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error detecting locale from geolocation: $e');
      return null;
    }
  }

  // Map coordinates to language (focusing on Indian regional languages)
  Locale? _getLocaleFromCoordinates(double lat, double lng) {
    // India bounds approximately: 8°N to 37°N, 68°E to 97°E
    if (lat >= 8 && lat <= 37 && lng >= 68 && lng <= 97) {
      // Regional language detection for Indian states

      // Tamil Nadu: 8°N to 13.5°N, 76.5°E to 80.3°E
      if (lat >= 8 && lat <= 13.5 && lng >= 76.5 && lng <= 80.3) {
        return const Locale('ta'); // Tamil
      }

      // Kerala: 8.2°N to 12.8°N, 74.8°E to 77.4°E
      if (lat >= 8.2 && lat <= 12.8 && lng >= 74.8 && lng <= 77.4) {
        return const Locale('ml'); // Malayalam
      }

      // Andhra Pradesh & Telangana: 12.6°N to 19.9°N, 76.8°E to 84.8°E
      if (lat >= 12.6 && lat <= 19.9 && lng >= 76.8 && lng <= 84.8) {
        return const Locale('te'); // Telugu
      }

      // Maharashtra: 15.6°N to 22°N, 72.6°E to 80.9°E
      if (lat >= 15.6 && lat <= 22 && lng >= 72.6 && lng <= 80.9) {
        return const Locale('mr'); // Marathi
      }

      // Gujarat: 20.1°N to 24.7°N, 68.2°E to 74.5°E
      if (lat >= 20.1 && lat <= 24.7 && lng >= 68.2 && lng <= 74.5) {
        return const Locale('gu'); // Gujarati
      }

      // Hindi belt (UP, MP, Rajasthan, Bihar, Jharkhand, Chhattisgarh, Uttarakhand, Himachal, Haryana, Delhi)
      // Roughly: 21°N to 31°N, 74°E to 88°E (excluding other specific regions)
      if (lat >= 21 && lat <= 31 && lng >= 74 && lng <= 88) {
        return const Locale('hi'); // Hindi
      }

      // Default to Hindi for other parts of India
      return const Locale('hi');
    }

    // Spain: 36°N to 43.8°N, -9.3°W to 3.3°E
    if (lat >= 36 && lat <= 43.8 && lng >= -9.3 && lng <= 3.3) {
      return const Locale('es'); // Spanish
    }

    // Latin America (rough approximation)
    // Mexico to Argentina: -55°S to 32°N, -117°W to -34°W
    if (lat >= -55 && lat <= 32 && lng >= -117 && lng <= -34) {
      return const Locale('es'); // Spanish
    }

    // Default to English for other locations
    return const Locale('en');
  }

  // Reset to first launch state (useful for testing)
  Future<void> resetFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchKey);
  }
}
