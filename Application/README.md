# VFarm Mobile Application

A comprehensive farming assistance mobile application built with Flutter, designed to empower farmers in Kerala, India with modern tools for farm management, government scheme access, and AI-powered farming recommendations.

## Features

### 🌍 Multi-language Support
- 8 Indian languages: English, Hindi, Tamil, Telugu, Marathi, Malayalam, Gujarati, Spanish
- Easy language switching from settings
- Fully localized UI and content

### 🏛️ Government Schemes
- Browse available agricultural schemes
- Search and filter by eligibility
- Apply for schemes with document upload
- Track application status in real-time
- Receive notifications on status updates

### 🤖 Smart Farming Assistant
- AI-powered activity recommendations
- Voice-based interaction with TTS/STT
- Seasonal and crop-specific suggestions
- Daily activity tracking and reminders
- Historical activity logs

### 🌤️ Weather Integration
- Real-time weather updates
- 7-day forecast
- Location-based weather data
- Weather alerts and warnings

### 💬 Community Features
- Connect with other farmers
- Share experiences and photos
- Like, comment, and engage
- Expert Q&A sessions

### 🗂️ Document Vault
- Secure cloud storage for farming documents
- Organize by categories
- View PDFs, images, and DOCX files
- Easy sharing and downloading

### 📊 Market Information
- Current crop prices
- Market trends and analysis
- Nearby market locations
- Price alerts

## Quick Start

### Prerequisites
- Flutter SDK 3.7.2+
- Android Studio / Xcode
- Firebase account

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd VFarm-VIT/vfarm
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure Firebase:**
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Run the app:**
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── home.dart                 # Home screen
├── login_screen.dart         # Authentication
├── govtSchemes.dart          # Government schemes
├── smart-Farming.dart        # AI assistant
├── weather_stats.dart        # Weather integration
├── models/                   # Data models
├── l10n/                     # Localization files
└── services/                 # Business logic
```

## Key Dependencies

- **firebase_core** - Firebase integration
- **cloud_firestore** - Database
- **firebase_auth** - Authentication
- **google_maps_flutter** - Maps and location
- **fl_chart** - Data visualization
- **flutter_tts** - Text-to-speech
- **speech_to_text** - Voice input

## Documentation

For detailed documentation, see:
- [📖 Project Overview](../Docs/PROJECT_OVERVIEW.md)
- [🛠️ Setup Guide](../Docs/SETUP_GUIDE.md)
- [📱 Flutter App Documentation](../Docs/FLUTTER_APP.md)
- [🔌 API Reference](../Docs/API_REFERENCE.md)
- [🚀 Deployment Guide](../Docs/DEPLOYMENT.md)

## Localization

The app supports 8 languages with full localization. See [LOCALIZATION_README.md](LOCALIZATION_README.md) for details on:
- Adding new languages
- Adding new translations
- Language switching implementation

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

See [Deployment Guide](../Docs/DEPLOYMENT.md) for detailed instructions.

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](../Docs/CONTRIBUTING.md).

## License

This project is part of the VFarm initiative to support farmers through technology.

---

**VFarm Mobile** - *Farming at Your Fingertips*

