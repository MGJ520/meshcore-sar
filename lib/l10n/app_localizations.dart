import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_sl.dart';

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
    Locale('hr'),
    Locale('sl'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'MeshCore SAR'**
  String get appTitle;

  /// Messages tab label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Contacts tab label
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Map tab label
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Connect button label
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Disconnect button label
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Text shown when scanning for BLE devices
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get scanningForDevices;

  /// Text shown when no BLE devices are found
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// Button to restart BLE scanning
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// Subtitle text for device in scan list
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get tapToConnect;

  /// Error message when device is not connected
  ///
  /// In en, this message translates to:
  /// **'Device not connected'**
  String get deviceNotConnected;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Error when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable in Settings.'**
  String get locationPermissionPermanentlyDenied;

  /// Error when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in Settings.'**
  String get locationServicesDisabled;

  /// Error when GPS location cannot be obtained
  ///
  /// In en, this message translates to:
  /// **'Failed to get GPS location'**
  String get failedToGetGpsLocation;

  /// Success message showing advertised location
  ///
  /// In en, this message translates to:
  /// **'Advertised at {latitude}, {longitude}'**
  String advertisedAtLocation(String latitude, String longitude);

  /// Error message for failed advertisement
  ///
  /// In en, this message translates to:
  /// **'Failed to advertise: {error}'**
  String failedToAdvertise(String error);

  /// Text shown during reconnection attempts
  ///
  /// In en, this message translates to:
  /// **'Reconnecting... ({attempt}/{max})'**
  String reconnecting(int attempt, int max);

  /// Tooltip for cancel reconnection button
  ///
  /// In en, this message translates to:
  /// **'Cancel reconnection'**
  String get cancelReconnection;

  /// Menu item for map management
  ///
  /// In en, this message translates to:
  /// **'Map Management'**
  String get mapManagement;

  /// General settings section header
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Description for blue light theme
  ///
  /// In en, this message translates to:
  /// **'Blue light theme'**
  String get blueLightTheme;

  /// Description for blue dark theme
  ///
  /// In en, this message translates to:
  /// **'Blue dark theme'**
  String get blueDarkTheme;

  /// SAR Red theme option
  ///
  /// In en, this message translates to:
  /// **'SAR Red'**
  String get sarRed;

  /// Description for SAR Red theme
  ///
  /// In en, this message translates to:
  /// **'Alert/Emergency mode'**
  String get alertEmergencyMode;

  /// SAR Green theme option
  ///
  /// In en, this message translates to:
  /// **'SAR Green'**
  String get sarGreen;

  /// Description for SAR Green theme
  ///
  /// In en, this message translates to:
  /// **'Safe/All Clear mode'**
  String get safeAllClearMode;

  /// Auto/System theme option
  ///
  /// In en, this message translates to:
  /// **'Auto (System)'**
  String get autoSystem;

  /// Description for system theme
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get followSystemTheme;

  /// Setting to show RX/TX indicators
  ///
  /// In en, this message translates to:
  /// **'Show RX/TX Indicators'**
  String get showRxTxIndicators;

  /// Description for RX/TX indicators setting
  ///
  /// In en, this message translates to:
  /// **'Display packet activity indicators in top bar'**
  String get displayPacketActivity;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Slovenian language option
  ///
  /// In en, this message translates to:
  /// **'Slovenian'**
  String get slovenian;

  /// Croatian language option
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get croatian;

  /// Location settings section header
  ///
  /// In en, this message translates to:
  /// **'Location Broadcasting'**
  String get locationBroadcasting;

  /// Auto location tracking setting
  ///
  /// In en, this message translates to:
  /// **'Auto Location Tracking'**
  String get autoLocationTracking;

  /// Description for auto location tracking
  ///
  /// In en, this message translates to:
  /// **'Automatically broadcast position updates'**
  String get automaticallyBroadcastPosition;

  /// Configure tracking button label
  ///
  /// In en, this message translates to:
  /// **'Configure Tracking'**
  String get configureTracking;

  /// Description for tracking configuration
  ///
  /// In en, this message translates to:
  /// **'Distance and time thresholds'**
  String get distanceAndTimeThresholds;

  /// Tracking configuration dialog title
  ///
  /// In en, this message translates to:
  /// **'Location Tracking Configuration'**
  String get locationTrackingConfiguration;

  /// Description for tracking configuration dialog
  ///
  /// In en, this message translates to:
  /// **'Configure when location broadcasts are sent to the mesh network'**
  String get configureWhenLocationBroadcasts;

  /// Minimum distance setting label
  ///
  /// In en, this message translates to:
  /// **'Minimum Distance'**
  String get minimumDistance;

  /// Description for minimum distance
  ///
  /// In en, this message translates to:
  /// **'Broadcast only after moving {distance} meters'**
  String broadcastAfterMoving(String distance);

  /// Maximum distance setting label
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get maximumDistance;

  /// Description for maximum distance
  ///
  /// In en, this message translates to:
  /// **'Always broadcast after moving {distance} meters'**
  String alwaysBroadcastAfterMoving(String distance);

  /// Minimum time interval setting label
  ///
  /// In en, this message translates to:
  /// **'Minimum Time Interval'**
  String get minimumTimeInterval;

  /// Description for time interval
  ///
  /// In en, this message translates to:
  /// **'Always broadcast every {duration}'**
  String alwaysBroadcastEvery(String duration);

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// About section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// App name label
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// About dialog title
  ///
  /// In en, this message translates to:
  /// **'About MeshCore SAR'**
  String get aboutMeshCoreSar;

  /// About dialog description
  ///
  /// In en, this message translates to:
  /// **'A Search & Rescue application designed for emergency response teams. Features include:\n\n• BLE mesh networking for device-to-device communication\n• Offline maps with multiple layer options\n• Real-time team member tracking\n• SAR tactical markers (found person, fire, staging)\n• Contact management and messaging\n• GPS tracking with compass heading\n• Map tile caching for offline use'**
  String get aboutDescription;

  /// Technologies used section title
  ///
  /// In en, this message translates to:
  /// **'Technologies Used:'**
  String get technologiesUsed;

  /// List of technologies used
  ///
  /// In en, this message translates to:
  /// **'• Flutter for cross-platform development\n• BLE (Bluetooth Low Energy) for mesh networking\n• OpenStreetMap for mapping\n• Provider for state management\n• SharedPreferences for local storage'**
  String get technologiesList;

  /// Developer section header
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Package name label
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get packageName;

  /// Sample data section header
  ///
  /// In en, this message translates to:
  /// **'Sample Data'**
  String get sampleData;

  /// Sample data section description
  ///
  /// In en, this message translates to:
  /// **'Load or clear sample contacts, channel messages, and SAR markers for testing'**
  String get sampleDataDescription;

  /// Load sample data button
  ///
  /// In en, this message translates to:
  /// **'Load Sample Data'**
  String get loadSampleData;

  /// Clear all data button
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// Clear data confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllDataConfirmTitle;

  /// Clear data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will clear all contacts and SAR markers. Are you sure?'**
  String get clearAllDataConfirmMessage;

  /// Clear button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Success message after loading sample data
  ///
  /// In en, this message translates to:
  /// **'Loaded {teamCount} team members, {channelCount} channels, {sarCount} SAR markers, {messageCount} messages'**
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  );

  /// Error message when sample data fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load sample data: {error}'**
  String failedToLoadSampleData(String error);

  /// Success message after clearing all data
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// Error message when background tracking fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start background tracking. Check permissions and BLE connection.'**
  String get failedToStartBackgroundTracking;

  /// Success message for location broadcast
  ///
  /// In en, this message translates to:
  /// **'Location broadcast: {latitude}, {longitude}'**
  String locationBroadcast(String latitude, String longitude);

  /// Information about default PIN for pairing
  ///
  /// In en, this message translates to:
  /// **'The default pin for devices without a screen is 123456. Trouble pairing? Forget the bluetooth device in system settings.'**
  String get defaultPinInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr', 'sl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
    case 'sl':
      return AppLocalizationsSl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
