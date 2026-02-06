import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('gu'),
    Locale('hi'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'VFarm'**
  String get appTitle;

  /// The application subtitle
  ///
  /// In en, this message translates to:
  /// **'Smart Farming Solutions'**
  String get appSubtitle;

  /// Main home screen title
  ///
  /// In en, this message translates to:
  /// **'We Farm, We Evolve'**
  String get weAreYourFarmingPartner;

  /// Dashboard menu item
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Government schemes menu item
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// Book service menu item
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// Markets menu item
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get markets;

  /// Ask expert menu item
  ///
  /// In en, this message translates to:
  /// **'Ask Expert'**
  String get askExpert;

  /// My vault menu item
  ///
  /// In en, this message translates to:
  /// **'My Vault'**
  String get myVault;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Search schemes page title
  ///
  /// In en, this message translates to:
  /// **'Search Schemes'**
  String get searchSchemes;

  /// Session expired message
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Smart farming service title
  ///
  /// In en, this message translates to:
  /// **'Smart Farming'**
  String get smartFarming;

  /// Smart farming subtitle
  ///
  /// In en, this message translates to:
  /// **'AI-powered crop management'**
  String get aiPoweredCropManagement;

  /// Smart farming description
  ///
  /// In en, this message translates to:
  /// **'Monitor soil, weather, and crop health'**
  String get monitorSoilWeatherCrop;

  /// Government schemes subtitle
  ///
  /// In en, this message translates to:
  /// **'Financial support & subsidies'**
  String get financialSupportSubsidies;

  /// Government schemes description
  ///
  /// In en, this message translates to:
  /// **'Access schemes with easy application'**
  String get accessSchemesEasyApplication;

  /// Expert consultation title
  ///
  /// In en, this message translates to:
  /// **'Expert Consultation'**
  String get expertConsultation;

  /// Expert consultation subtitle
  ///
  /// In en, this message translates to:
  /// **'Professional farming advice 24/7'**
  String get professionalFarmingAdvice;

  /// Expert consultation description
  ///
  /// In en, this message translates to:
  /// **'Connect with verified experts'**
  String get connectWithVerifiedExperts;

  /// My vault subtitle
  ///
  /// In en, this message translates to:
  /// **'Secure digital farming records'**
  String get secureDigitalFarmingRecords;

  /// My vault description
  ///
  /// In en, this message translates to:
  /// **'Store documents & data safely'**
  String get storeDocumentsDataSafely;

  /// Explore now button text
  ///
  /// In en, this message translates to:
  /// **'Explore Now'**
  String get exploreNow;

  /// Farmers count label
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmers;

  /// Experts count label
  ///
  /// In en, this message translates to:
  /// **'Experts'**
  String get experts;

  /// Money saved label
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Quick services section title
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quickServices;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Smart Farming Solutions'**
  String get smartFarmingSolutions;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Government Schemes Available'**
  String get governmentSchemesAvailable;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Expert Consultation Ready'**
  String get expertConsultationReady;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Market Intelligence Here'**
  String get marketIntelligenceHere;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Crop Management Tools'**
  String get cropManagementTools;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast Updates'**
  String get weatherForecastUpdates;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Insights'**
  String get aiPoweredInsights;

  /// Animated typing text
  ///
  /// In en, this message translates to:
  /// **'Modern Equipment Access'**
  String get modernEquipmentAccess;

  /// Service availability status
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// 24/7 live service status
  ///
  /// In en, this message translates to:
  /// **'24/7 Live'**
  String get live24x7;

  /// Security status
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// Active schemes count
  ///
  /// In en, this message translates to:
  /// **'50+ Active'**
  String get activeSchemes;

  /// Trending section title
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// See all button text
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Instant services section title
  ///
  /// In en, this message translates to:
  /// **'Instant Services'**
  String get instantServices;

  /// Training service title
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// Training service subtitle
  ///
  /// In en, this message translates to:
  /// **'Free Workshops'**
  String get freeWorkshops;

  /// Fertilizer service title
  ///
  /// In en, this message translates to:
  /// **'Quality\nFertilizer'**
  String get qualityFertilizer;

  /// Fertilizer service discount
  ///
  /// In en, this message translates to:
  /// **'20% off today'**
  String get offToday;

  /// Soil testing service title
  ///
  /// In en, this message translates to:
  /// **'Soil\nTesting'**
  String get soilTesting;

  /// Soil testing service subtitle
  ///
  /// In en, this message translates to:
  /// **'Results in 2hrs'**
  String get resultsIn2hrs;

  /// Farm workers service title
  ///
  /// In en, this message translates to:
  /// **'Farm\nWorkers'**
  String get farmWorkers;

  /// Farm workers service subtitle
  ///
  /// In en, this message translates to:
  /// **'Verified & skilled'**
  String get verifiedSkilled;

  /// Community posts section title
  ///
  /// In en, this message translates to:
  /// **'Community Posts'**
  String get communityPosts;

  /// Create post button text
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// Empty posts message
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// Empty posts description
  ///
  /// In en, this message translates to:
  /// **'Be the first to share something with the community!'**
  String get beFirstToShare;

  /// Empty posts instruction
  ///
  /// In en, this message translates to:
  /// **'Tap the \"Create Post\" button above to get started'**
  String get tapCreatePostButton;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Connection error title
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get checkInternetConnection;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Like button text
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// Comment button text
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Time ago - just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Time ago - minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String mAgo(int minutes);

  /// Time ago - hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hAgo(int hours);

  /// Time ago - days
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String dAgo(int days);

  /// Login required message for creating post
  ///
  /// In en, this message translates to:
  /// **'Please login to create a post'**
  String get pleaseLoginToCreatePost;

  /// Failed to update like error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update like'**
  String failedToUpdateLike(String error);

  /// Notification type - crop health alert
  ///
  /// In en, this message translates to:
  /// **'Crop Health Alert'**
  String get cropHealthAlert;

  /// Crop health alert notification message
  ///
  /// In en, this message translates to:
  /// **'Your tomato crop shows signs of early blight. Immediate action recommended.'**
  String get cropHealthAlertMessage;

  /// Notification type - weather update
  ///
  /// In en, this message translates to:
  /// **'Weather Update'**
  String get weatherUpdate;

  /// Weather update notification message
  ///
  /// In en, this message translates to:
  /// **'Heavy rainfall expected in next 24 hours. Protect your crops.'**
  String get weatherUpdateMessage;

  /// Notification type - harvest reminder
  ///
  /// In en, this message translates to:
  /// **'Harvest Reminder'**
  String get harvestReminder;

  /// Harvest reminder notification message
  ///
  /// In en, this message translates to:
  /// **'Your wheat crop is ready for harvesting.'**
  String get harvestReminderMessage;

  /// Notification type - market price update
  ///
  /// In en, this message translates to:
  /// **'Market Price Update'**
  String get marketPriceUpdate;

  /// Market price update notification message
  ///
  /// In en, this message translates to:
  /// **'Tomato prices increased by 15% in your area.'**
  String get marketPriceUpdateMessage;

  /// Empty notifications message
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// Mark all notifications as read button
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Search input hint text
  ///
  /// In en, this message translates to:
  /// **'Search for schemes, services...'**
  String get searchHint;

  /// No description provided for @governmentSchemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemesTitle;

  /// No description provided for @myApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get myApplications;

  /// No description provided for @trackApplications.
  ///
  /// In en, this message translates to:
  /// **'Track your scheme applications'**
  String get trackApplications;

  /// No description provided for @allSchemes.
  ///
  /// In en, this message translates to:
  /// **'All Schemes'**
  String get allSchemes;

  /// No description provided for @searchSchemesByName.
  ///
  /// In en, this message translates to:
  /// **'Search schemes by name or description...'**
  String get searchSchemesByName;

  /// No description provided for @refreshSchemes.
  ///
  /// In en, this message translates to:
  /// **'Refresh Schemes'**
  String get refreshSchemes;

  /// No description provided for @noSchemesMatch.
  ///
  /// In en, this message translates to:
  /// **'No schemes match your filters'**
  String get noSchemesMatch;

  /// No description provided for @noSchemesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Schemes Available'**
  String get noSchemesAvailable;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search criteria or filters'**
  String get tryAdjustingFilters;

  /// No description provided for @newSchemesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'New schemes will appear here when available'**
  String get newSchemesWillAppear;

  /// No description provided for @eligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get eligible;

  /// No description provided for @notEligible.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible'**
  String get notEligible;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @subsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get subsidy;

  /// No description provided for @loan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loan;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @appliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied on'**
  String get appliedOn;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @downloadDocument.
  ///
  /// In en, this message translates to:
  /// **'Download Document'**
  String get downloadDocument;

  /// No description provided for @noApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No Applications Yet'**
  String get noApplicationsYet;

  /// No description provided for @startApplyingMessage.
  ///
  /// In en, this message translates to:
  /// **'Start applying for schemes to see them here'**
  String get startApplyingMessage;

  /// No description provided for @browseSchemes.
  ///
  /// In en, this message translates to:
  /// **'Browse Schemes'**
  String get browseSchemes;

  /// No description provided for @completeProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first to apply for schemes'**
  String get completeProfileFirst;

  /// No description provided for @applicationDocument.
  ///
  /// In en, this message translates to:
  /// **'Application Document'**
  String get applicationDocument;

  /// No description provided for @scheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get scheme;

  /// No description provided for @applicationId.
  ///
  /// In en, this message translates to:
  /// **'Application ID'**
  String get applicationId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @downloadPending.
  ///
  /// In en, this message translates to:
  /// **'Document generation is in progress. Please check back later.'**
  String get downloadPending;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @documentDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Document will be downloaded shortly'**
  String get documentDownloaded;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @documentsPending.
  ///
  /// In en, this message translates to:
  /// **'Documents Pending'**
  String get documentsPending;

  /// No description provided for @currentStep.
  ///
  /// In en, this message translates to:
  /// **'Current Step'**
  String get currentStep;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @eligibilityInfo.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Information'**
  String get eligibilityInfo;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @schemeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetails;

  /// No description provided for @agriculturalSchemes.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Schemes'**
  String get agriculturalSchemes;

  /// No description provided for @availableSchemes.
  ///
  /// In en, this message translates to:
  /// **'Available Schemes'**
  String get availableSchemes;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @cropAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Your tomato crop shows signs of early blight. Immediate action recommended.'**
  String get cropAlertMessage;

  /// No description provided for @marketPriceMessage.
  ///
  /// In en, this message translates to:
  /// **'Tomato prices increased by 15% in your area.'**
  String get marketPriceMessage;

  /// No description provided for @vfarm.
  ///
  /// In en, this message translates to:
  /// **'VFarm'**
  String get vfarm;

  /// No description provided for @bookAService.
  ///
  /// In en, this message translates to:
  /// **'Book a Service'**
  String get bookAService;

  /// No description provided for @liveSupport.
  ///
  /// In en, this message translates to:
  /// **'24/7 Live'**
  String get liveSupport;

  /// No description provided for @discountToday.
  ///
  /// In en, this message translates to:
  /// **'20% off today'**
  String get discountToday;

  /// No description provided for @resultsInHours.
  ///
  /// In en, this message translates to:
  /// **'Results in 2hrs'**
  String get resultsInHours;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @tapCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"Create Post\" button above to get started'**
  String get tapCreatePost;

  /// No description provided for @myVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'My Vault'**
  String get myVaultTitle;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchDocuments;

  /// No description provided for @cropHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop History'**
  String get cropHistory;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @landDocuments.
  ///
  /// In en, this message translates to:
  /// **'Land Documents'**
  String get landDocuments;

  /// No description provided for @agriLoanRecords.
  ///
  /// In en, this message translates to:
  /// **'Agri-Loan Records'**
  String get agriLoanRecords;

  /// No description provided for @pleaseLoginToViewDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please login to view documents'**
  String get pleaseLoginToViewDocuments;

  /// No description provided for @userIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'User ID not found'**
  String get userIdNotFound;

  /// No description provided for @errorLoadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error loading documents'**
  String get errorLoadingDocuments;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No Documents Found'**
  String get noDocumentsFound;

  /// No description provided for @uploadFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload your first document to get started'**
  String get uploadFirstDocument;

  /// No description provided for @noDocumentsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No documents in {category} category'**
  String noDocumentsInCategory(Object category);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(Object days);

  /// No description provided for @updateProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Picture'**
  String get updateProfilePicture;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @uploadingProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile image...'**
  String get uploadingProfileImage;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated successfully'**
  String get profileImageUpdated;

  /// Image upload error message
  ///
  /// In en, this message translates to:
  /// **'Error uploading image'**
  String get errorUploadingImage;

  /// No description provided for @pleaseLoginToUpload.
  ///
  /// In en, this message translates to:
  /// **'Please login to upload documents'**
  String get pleaseLoginToUpload;

  /// No description provided for @documentName.
  ///
  /// In en, this message translates to:
  /// **'Document Name'**
  String get documentName;

  /// No description provided for @enterDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your document'**
  String get enterDocumentName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @tagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get tagsOptional;

  /// No description provided for @enterTagsSeparated.
  ///
  /// In en, this message translates to:
  /// **'Enter tags separated by commas'**
  String get enterTagsSeparated;

  /// No description provided for @tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select file'**
  String get tapToSelectFile;

  /// No description provided for @pdfImagesDocuments.
  ///
  /// In en, this message translates to:
  /// **'PDF, Images, or Documents'**
  String get pdfImagesDocuments;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File Selected'**
  String get fileSelected;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @errorSelectingFile.
  ///
  /// In en, this message translates to:
  /// **'Error selecting file'**
  String get errorSelectingFile;

  /// No description provided for @pleaseSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a file first'**
  String get pleaseSelectFile;

  /// No description provided for @pleaseEnterDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a document name'**
  String get pleaseEnterDocumentName;

  /// No description provided for @errorUploadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error uploading document'**
  String get errorUploadingDocument;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully'**
  String get documentUploaded;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String areYouSureDelete(Object fileName);

  /// No description provided for @deletingDocument.
  ///
  /// In en, this message translates to:
  /// **'Deleting document...'**
  String get deletingDocument;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted successfully'**
  String get documentDeleted;

  /// No description provided for @errorDeletingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error deleting document'**
  String get errorDeletingDocument;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load user profile'**
  String get couldNotLoadProfile;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get loadingSettings;

  /// No description provided for @failedToLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings. Please try again.'**
  String get failedToLoadSettings;

  /// No description provided for @userProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile not found'**
  String get userProfileNotFound;

  /// No description provided for @noUserSessionFound.
  ///
  /// In en, this message translates to:
  /// **'No user session found. Please log in again.'**
  String get noUserSessionFound;

  /// No description provided for @errorLoadingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data'**
  String get errorLoadingUserData;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Farm location field label
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get farmLocation;

  /// Farm size field label
  ///
  /// In en, this message translates to:
  /// **'Farm Size (acres)'**
  String get farmSizeAcres;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @profileImageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated successfully'**
  String get profileImageUpdatedSuccessfully;

  /// Profile save success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @howToAddCrops.
  ///
  /// In en, this message translates to:
  /// **'How to add crops?'**
  String get howToAddCrops;

  /// No description provided for @howToAddCropsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the crops section and tap the + button to add new crops to your farm.'**
  String get howToAddCropsAnswer;

  /// No description provided for @howToTrackWeather.
  ///
  /// In en, this message translates to:
  /// **'How to track weather?'**
  String get howToTrackWeather;

  /// No description provided for @howToTrackWeatherAnswer.
  ///
  /// In en, this message translates to:
  /// **'Weather information is automatically updated based on your farm location.'**
  String get howToTrackWeatherAnswer;

  /// No description provided for @howToManageIrrigation.
  ///
  /// In en, this message translates to:
  /// **'How to manage irrigation?'**
  String get howToManageIrrigation;

  /// No description provided for @howToManageIrrigationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Use the irrigation scheduler to set up automated watering for your crops.'**
  String get howToManageIrrigationAnswer;

  /// No description provided for @howToViewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'How to view analytics?'**
  String get howToViewAnalytics;

  /// No description provided for @howToViewAnalyticsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Analytics can be found in the dashboard showing your farm performance metrics.'**
  String get howToViewAnalyticsAnswer;

  /// No description provided for @accountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account verification'**
  String get accountVerification;

  /// No description provided for @accountVerificationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Upload required documents in profile settings to get your account verified.'**
  String get accountVerificationAnswer;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @contactSupportAnswer.
  ///
  /// In en, this message translates to:
  /// **'Use the contact support option below to reach our team directly.'**
  String get contactSupportAnswer;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// No description provided for @supportRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted successfully'**
  String get supportRequestSubmittedSuccessfully;

  /// No description provided for @errorSubmittingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error submitting request'**
  String get errorSubmittingRequest;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @areYouSureYouWantToSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureYouWantToSignOut;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// No description provided for @privacySettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings coming soon'**
  String get privacySettingsComingSoon;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @paymentMethodsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment methods coming soon'**
  String get paymentMethodsComingSoon;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @verifiedMember.
  ///
  /// In en, this message translates to:
  /// **'Verified Member'**
  String get verifiedMember;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @botWhatCropHarvested.
  ///
  /// In en, this message translates to:
  /// **'What crop did you harvest?'**
  String get botWhatCropHarvested;

  /// No description provided for @botHowMuchQuantity.
  ///
  /// In en, this message translates to:
  /// **'How much quantity did you harvest? Please specify the amount and unit.'**
  String get botHowMuchQuantity;

  /// No description provided for @botApproximateProfit.
  ///
  /// In en, this message translates to:
  /// **'What is the approximate profit from this harvest?'**
  String get botApproximateProfit;

  /// No description provided for @botWhatDidWithCrop.
  ///
  /// In en, this message translates to:
  /// **'What did you do with the harvested crop?'**
  String get botWhatDidWithCrop;

  /// No description provided for @botWhatCropType.
  ///
  /// In en, this message translates to:
  /// **'What type of crop were you working with?'**
  String get botWhatCropType;

  /// No description provided for @botHowMuchArea.
  ///
  /// In en, this message translates to:
  /// **'How much area did you cover? Please mention in acres or square feet.'**
  String get botHowMuchArea;

  /// No description provided for @botWhatSeedType.
  ///
  /// In en, this message translates to:
  /// **'What type of seeds did you use?'**
  String get botWhatSeedType;

  /// No description provided for @botWhatAnimalType.
  ///
  /// In en, this message translates to:
  /// **'What type of animals were you caring for?'**
  String get botWhatAnimalType;

  /// No description provided for @botHowManyAnimals.
  ///
  /// In en, this message translates to:
  /// **'How many animals were involved?'**
  String get botHowManyAnimals;

  /// No description provided for @botWhichEquipment.
  ///
  /// In en, this message translates to:
  /// **'Which equipment or tool did you use?'**
  String get botWhichEquipment;

  /// No description provided for @botWhatWorkType.
  ///
  /// In en, this message translates to:
  /// **'What kind of work or maintenance did you do?'**
  String get botWhatWorkType;

  /// No description provided for @botWhichArea.
  ///
  /// In en, this message translates to:
  /// **'Which area or structure did you maintain?'**
  String get botWhichArea;

  /// No description provided for @botWhatWorkDone.
  ///
  /// In en, this message translates to:
  /// **'What specific work did you do?'**
  String get botWhatWorkDone;

  /// No description provided for @botWhatPlanning.
  ///
  /// In en, this message translates to:
  /// **'What kind of planning did you do?'**
  String get botWhatPlanning;

  /// No description provided for @botWhatDecisions.
  ///
  /// In en, this message translates to:
  /// **'What decisions did you make?'**
  String get botWhatDecisions;

  /// No description provided for @botDescribeActivity.
  ///
  /// In en, this message translates to:
  /// **'Can you describe what you did in more detail?'**
  String get botDescribeActivity;

  /// No description provided for @botActivityComplete.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your activity information is complete.'**
  String get botActivityComplete;

  /// No description provided for @botGreatSelection.
  ///
  /// In en, this message translates to:
  /// **'Great! You\'ve selected {activity}. Please tell me about your activity. I\'m listening...'**
  String botGreatSelection(String activity);

  /// No description provided for @botActivitySaved.
  ///
  /// In en, this message translates to:
  /// **'Activity saved successfully! Great work!'**
  String get botActivitySaved;

  /// No description provided for @dailyActivity.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get dailyActivity;

  /// No description provided for @addActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get addActivity;

  /// No description provided for @recordFarmActivity.
  ///
  /// In en, this message translates to:
  /// **'Record Farm Activity'**
  String get recordFarmActivity;

  /// No description provided for @cropManagement.
  ///
  /// In en, this message translates to:
  /// **'Crop Management'**
  String get cropManagement;

  /// No description provided for @cropManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Planting, watering, fertilizing, pest control'**
  String get cropManagementDesc;

  /// No description provided for @livestockCare.
  ///
  /// In en, this message translates to:
  /// **'Livestock Care'**
  String get livestockCare;

  /// No description provided for @livestockCareDesc.
  ///
  /// In en, this message translates to:
  /// **'Animal feeding, health checks, milking'**
  String get livestockCareDesc;

  /// No description provided for @equipmentTools.
  ///
  /// In en, this message translates to:
  /// **'Equipment & Tools'**
  String get equipmentTools;

  /// No description provided for @equipmentToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Maintenance, repairs, equipment operation'**
  String get equipmentToolsDesc;

  /// No description provided for @harvesting.
  ///
  /// In en, this message translates to:
  /// **'Harvesting'**
  String get harvesting;

  /// No description provided for @harvestingDesc.
  ///
  /// In en, this message translates to:
  /// **'Crop collection, processing, storage'**
  String get harvestingDesc;

  /// No description provided for @farmMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Farm Maintenance'**
  String get farmMaintenance;

  /// No description provided for @farmMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure, fencing, building repairs'**
  String get farmMaintenanceDesc;

  /// No description provided for @planningAdmin.
  ///
  /// In en, this message translates to:
  /// **'Planning & Admin'**
  String get planningAdmin;

  /// No description provided for @planningAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Record keeping, planning, financial management'**
  String get planningAdminDesc;

  /// No description provided for @recordYourFarmActivity.
  ///
  /// In en, this message translates to:
  /// **'Record Your Farm Activity'**
  String get recordYourFarmActivity;

  /// No description provided for @selectActivityTypeToStart.
  ///
  /// In en, this message translates to:
  /// **'Select an activity type to get started with voice recording'**
  String get selectActivityTypeToStart;

  /// No description provided for @tellMeAboutActivity.
  ///
  /// In en, this message translates to:
  /// **'Tell me about your activity in any language'**
  String get tellMeAboutActivity;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stopListening;

  /// No description provided for @processingWithAI.
  ///
  /// In en, this message translates to:
  /// **'Processing with AI...'**
  String get processingWithAI;

  /// No description provided for @tapToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get tapToStartRecording;

  /// No description provided for @microphoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone not available'**
  String get microphoneNotAvailable;

  /// No description provided for @whatIHeard.
  ///
  /// In en, this message translates to:
  /// **'What I heard:'**
  String get whatIHeard;

  /// No description provided for @detectedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Detected language: {language}'**
  String detectedLanguage(String language);

  /// No description provided for @needMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Need more information:'**
  String get needMoreInformation;

  /// No description provided for @provideMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Please provide the missing information by speaking again.'**
  String get provideMissingInfo;

  /// No description provided for @activityProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Activity Processed Successfully!'**
  String get activityProcessedSuccessfully;

  /// No description provided for @saveActivity.
  ///
  /// In en, this message translates to:
  /// **'Save Activity'**
  String get saveActivity;

  /// No description provided for @activitySaved.
  ///
  /// In en, this message translates to:
  /// **'Activity Saved!'**
  String get activitySaved;

  /// No description provided for @activityRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your farm activity has been recorded successfully.'**
  String get activityRecordedSuccessfully;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another'**
  String get addAnother;

  /// No description provided for @skipToHome.
  ///
  /// In en, this message translates to:
  /// **'Skip to Home'**
  String get skipToHome;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @speechRecognitionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechRecognitionNotAvailable;

  /// No description provided for @noVoiceInputDetected.
  ///
  /// In en, this message translates to:
  /// **'No voice input detected'**
  String get noVoiceInputDetected;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed: {error}'**
  String processingFailed(String error);

  /// No description provided for @errorProcessingVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Error processing voice input: {error}'**
  String errorProcessingVoiceInput(String error);

  /// No description provided for @failedToInitialize.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize: {error}'**
  String failedToInitialize(String error);

  /// No description provided for @failedToSaveActivity.
  ///
  /// In en, this message translates to:
  /// **'Failed to save activity: {error}'**
  String failedToSaveActivity(String error);

  /// No description provided for @speechRecognitionError.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition error: {error}'**
  String speechRecognitionError(String error);

  /// Tutorial step 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to VFarm! 🌱'**
  String get tutorialWelcomeTitle;

  /// Tutorial step 1 description
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started with a quick tour. Tap \"Next\" to open the sidebar.'**
  String get tutorialWelcomeDescription;

  /// Tutorial step 2 title
  ///
  /// In en, this message translates to:
  /// **'Open My Vault 🗂️'**
  String get tutorialVaultTitle;

  /// Tutorial step 2 description
  ///
  /// In en, this message translates to:
  /// **'Great! Now tap \"Next\" to go to My Vault - your personal storage and profile.'**
  String get tutorialVaultDescription;

  /// Tutorial step 3 title
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile 👤'**
  String get tutorialProfileTitle;

  /// Tutorial step 3 description
  ///
  /// In en, this message translates to:
  /// **'Perfect! Tap \"Next\" to edit your profile. Fill in your details to personalize your experience!'**
  String get tutorialProfileDescription;

  /// Tutorial skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// Tutorial next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// Tutorial completion button
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get tutorialGotIt;

  /// Complete profile title
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// Edit profile title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Profile completion dialog message
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to continue using VFarm. This information helps us provide you with better farming recommendations.'**
  String get profileCompletionMessage;

  /// Continue editing profile button
  ///
  /// In en, this message translates to:
  /// **'Continue Editing'**
  String get continueEditing;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Profile picture instruction
  ///
  /// In en, this message translates to:
  /// **'Tap to change profile picture'**
  String get tapToChangeProfilePicture;

  /// Name validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Phone validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// Farm location validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your farm location'**
  String get pleaseEnterYourFarmLocation;

  /// Farm size validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your farm size'**
  String get pleaseEnterYourFarmSize;

  /// Crop types section label
  ///
  /// In en, this message translates to:
  /// **'Crop Types'**
  String get cropTypes;

  /// Save profile button text
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// Profile save error message
  ///
  /// In en, this message translates to:
  /// **'Error saving profile'**
  String get errorSavingProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'gu',
    'hi',
    'ml',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
