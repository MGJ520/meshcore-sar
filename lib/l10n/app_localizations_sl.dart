// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Sporočila';

  @override
  String get contacts => 'Stiki';

  @override
  String get map => 'Zemljevid';

  @override
  String get settings => 'Nastavitve';

  @override
  String get connect => 'Poveži';

  @override
  String get disconnect => 'Prekini';

  @override
  String get scanningForDevices => 'Iskanje naprav...';

  @override
  String get noDevicesFound => 'Ni najdenih naprav';

  @override
  String get scanAgain => 'Ponovi iskanje';

  @override
  String get tapToConnect => 'Tapnite za povezavo';

  @override
  String get deviceNotConnected => 'Naprava ni povezana';

  @override
  String get locationPermissionDenied => 'Dovoljenje za lokacijo zavrnjeno';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Dovoljenje za lokacijo trajno zavrnjeno. Prosimo, omogočite v Nastavitvah.';

  @override
  String get locationServicesDisabled =>
      'Lokacijske storitve so onemogočene. Prosimo, omogočite jih v Nastavitvah.';

  @override
  String get failedToGetGpsLocation => 'Pridobitev GPS lokacije ni uspela';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Objavljeno na $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Objava ni uspela: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Ponovno povezovanje... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Prekliči ponovno povezovanje';

  @override
  String get mapManagement => 'Upravljanje zemljevida';

  @override
  String get general => 'Splošno';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Izberite temo';

  @override
  String get light => 'Svetla';

  @override
  String get dark => 'Temna';

  @override
  String get blueLightTheme => 'Modra svetla tema';

  @override
  String get blueDarkTheme => 'Modra temna tema';

  @override
  String get sarRed => 'SAR rdeča';

  @override
  String get alertEmergencyMode => 'Način opozorila/nujni primer';

  @override
  String get sarGreen => 'SAR zelena';

  @override
  String get safeAllClearMode => 'Način varno/vse jasno';

  @override
  String get autoSystem => 'Samodejno (Sistem)';

  @override
  String get followSystemTheme => 'Sledi sistemski temi';

  @override
  String get showRxTxIndicators => 'Prikaži RX/TX kazalnike';

  @override
  String get displayPacketActivity =>
      'Prikaži kazalnike aktivnosti paketov v zgornji vrstici';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Izberite jezik';

  @override
  String get english => 'Angleščina';

  @override
  String get slovenian => 'Slovenščina';

  @override
  String get croatian => 'Hrvaščina';

  @override
  String get locationBroadcasting => 'Oddajanje lokacije';

  @override
  String get autoLocationTracking => 'Samodejno sledenje lokaciji';

  @override
  String get automaticallyBroadcastPosition =>
      'Samodejno oddajaj posodobitve položaja';

  @override
  String get configureTracking => 'Konfiguriraj sledenje';

  @override
  String get distanceAndTimeThresholds => 'Pragovi razdalje in časa';

  @override
  String get locationTrackingConfiguration => 'Konfiguracija sledenja lokaciji';

  @override
  String get configureWhenLocationBroadcasts =>
      'Konfigurirajte, kdaj se oddajanja lokacije pošiljajo v omrežje mesh';

  @override
  String get minimumDistance => 'Minimalna razdalja';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Oddajaj šele po premiku $distance metrov';
  }

  @override
  String get maximumDistance => 'Maksimalna razdalja';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Vedno oddajaj po premiku $distance metrov';
  }

  @override
  String get minimumTimeInterval => 'Minimalni časovni interval';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Vedno oddajaj vsakih $duration';
  }

  @override
  String get save => 'Shrani';

  @override
  String get cancel => 'Prekliči';

  @override
  String get close => 'Zapri';

  @override
  String get about => 'O aplikaciji';

  @override
  String get appVersion => 'Različica aplikacije';

  @override
  String get appName => 'Ime aplikacije';

  @override
  String get aboutMeshCoreSar => 'O MeshCore SAR';

  @override
  String get aboutDescription =>
      'Aplikacija za iskanje in reševanje, zasnovana za ekipe za odzivanje v nujnih primerih. Funkcije vključujejo:\n\n• BLE mesh omrežje za komunikacijo naprava-naprava\n• Brez povezave delujejo zemljevidi z več sloji\n• Sledenje članov ekipe v realnem času\n• SAR taktični označevalci (najdena oseba, ogenj, zbirališče)\n• Upravljanje stikov in sporočanje\n• GPS sledenje s kompasno smerjo\n• Predpomnenje ploščic zemljevida za uporabo brez povezave';

  @override
  String get technologiesUsed => 'Uporabljene tehnologije:';

  @override
  String get technologiesList =>
      '• Flutter za večplatformni razvoj\n• BLE (Bluetooth Low Energy) za mesh omrežje\n• OpenStreetMap za kartografijo\n• Provider za upravljanje stanja\n• SharedPreferences za lokalno shranjevanje';

  @override
  String get developer => 'Razvijalec';

  @override
  String get packageName => 'Ime paketa';

  @override
  String get sampleData => 'Vzorčni podatki';

  @override
  String get sampleDataDescription =>
      'Naložite ali počistite vzorčne stike, sporočila kanalov in SAR označevalce za testiranje';

  @override
  String get loadSampleData => 'Naloži vzorčne podatke';

  @override
  String get clearAllData => 'Počisti vse podatke';

  @override
  String get clearAllDataConfirmTitle => 'Počisti vse podatke';

  @override
  String get clearAllDataConfirmMessage =>
      'To bo počistilo vse stike in SAR označevalce. Ste prepričani?';

  @override
  String get clear => 'Počisti';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Naloženih $teamCount članov ekipe, $channelCount kanalov, $sarCount SAR označevalcev, $messageCount sporočil';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Nalaganje vzorčnih podatkov ni uspelo: $error';
  }

  @override
  String get allDataCleared => 'Vsi podatki počiščeni';

  @override
  String get failedToStartBackgroundTracking =>
      'Zagon sledenja v ozadju ni uspel. Preverite dovoljenja in BLE povezavo.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Oddajanje lokacije: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Privzeta PIN koda za naprave brez zaslona je 123456. Težave s seznanitvijo? Pozabite napravo bluetooth v sistemskih nastavitvah.';
}
