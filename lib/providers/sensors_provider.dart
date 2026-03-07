import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';

enum SensorRefreshState { idle, refreshing, success, timeout, unavailable }

enum SensorMetric {
  lastSeen,
  voltage,
  battery,
  temperature,
  humidity,
  pressure,
  gps,
  updated,
}

class SensorsProvider with ChangeNotifier {
  static const String _watchedSensorsKey = 'watched_sensor_keys';
  static const String _visibleSensorMetricsKey = 'visible_sensor_metrics';
  static const Set<SensorMetric> _defaultVisibleMetrics = <SensorMetric>{
    SensorMetric.lastSeen,
    SensorMetric.voltage,
    SensorMetric.battery,
    SensorMetric.temperature,
    SensorMetric.humidity,
    SensorMetric.pressure,
    SensorMetric.gps,
    SensorMetric.updated,
  };

  final List<String> _watchedSensorKeys = <String>[];
  final Map<String, SensorRefreshState> _refreshStates =
      <String, SensorRefreshState>{};
  final Map<String, Set<SensorMetric>> _visibleMetricsBySensor =
      <String, Set<SensorMetric>>{};
  bool _isLoaded = false;
  bool _isRefreshingAll = false;

  SensorsProvider() {
    unawaited(_loadWatchedSensors());
  }

  List<String> get watchedSensorKeys => List.unmodifiable(_watchedSensorKeys);
  bool get isLoaded => _isLoaded;
  bool get isRefreshingAll => _isRefreshingAll;

  SensorRefreshState stateFor(String publicKeyHex) =>
      _refreshStates[publicKeyHex] ?? SensorRefreshState.idle;

  Future<void> _loadWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_watchedSensorsKey) ?? <String>[];
      final storedMetricsJson = prefs.getString(_visibleSensorMetricsKey);
      _watchedSensorKeys
        ..clear()
        ..addAll(stored);
      _visibleMetricsBySensor.clear();
      if (storedMetricsJson != null && storedMetricsJson.isNotEmpty) {
        final decoded = jsonDecode(storedMetricsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final metricNames = (entry.value as List<dynamic>).cast<String>();
          _visibleMetricsBySensor[entry.key] = metricNames
              .map(_metricFromName)
              .whereType<SensorMetric>()
              .toSet();
        }
      }
      for (final key in _watchedSensorKeys) {
        _visibleMetricsBySensor.putIfAbsent(
          key,
          () => Set<SensorMetric>.from(_defaultVisibleMetrics),
        );
      }
    } catch (e) {
      debugPrint('Error loading watched sensors: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchedSensorsKey, _watchedSensorKeys);
    } catch (e) {
      debugPrint('Error saving watched sensors: $e');
    }
  }

  Future<void> _persistVisibleMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, List<String>>{};
      for (final entry in _visibleMetricsBySensor.entries) {
        encoded[entry.key] = entry.value.map((metric) => metric.name).toList();
      }
      await prefs.setString(_visibleSensorMetricsKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving visible sensor metrics: $e');
    }
  }

  Set<SensorMetric> visibleMetricsFor(String publicKeyHex) =>
      Set<SensorMetric>.unmodifiable(
        _visibleMetricsBySensor[publicKeyHex] ?? _defaultVisibleMetrics,
      );

  bool showsMetric(String publicKeyHex, SensorMetric metric) =>
      visibleMetricsFor(publicKeyHex).contains(metric);

  Future<void> toggleMetric(
    String publicKeyHex,
    SensorMetric metric,
    bool visible,
  ) async {
    final visibleMetrics = _visibleMetricsBySensor.putIfAbsent(
      publicKeyHex,
      () => Set<SensorMetric>.from(_defaultVisibleMetrics),
    );
    if (visible) {
      visibleMetrics.add(metric);
    } else {
      if (visibleMetrics.length == 1 && visibleMetrics.contains(metric)) {
        return;
      }
      visibleMetrics.remove(metric);
    }
    await _persistVisibleMetrics();
    notifyListeners();
  }

  bool isWatched(String publicKeyHex) =>
      _watchedSensorKeys.contains(publicKeyHex);

  Future<void> addSensor(Contact contact) async {
    if (!contact.isChat && !contact.isRepeater) {
      return;
    }
    if (_watchedSensorKeys.contains(contact.publicKeyHex)) {
      return;
    }

    _watchedSensorKeys.add(contact.publicKeyHex);
    await _persistWatchedSensors();
    _visibleMetricsBySensor[contact.publicKeyHex] = Set<SensorMetric>.from(
      _defaultVisibleMetrics,
    );
    await _persistVisibleMetrics();
    notifyListeners();
  }

  Future<void> removeSensor(String publicKeyHex) async {
    _watchedSensorKeys.remove(publicKeyHex);
    _refreshStates.remove(publicKeyHex);
    _visibleMetricsBySensor.remove(publicKeyHex);
    await _persistWatchedSensors();
    await _persistVisibleMetrics();
    notifyListeners();
  }

  List<Contact> availableCandidates(ContactsProvider contactsProvider) {
    final candidates = <Contact>[
      ...contactsProvider.chatContacts,
      ...contactsProvider.repeaters,
    ];
    candidates.removeWhere((contact) => isWatched(contact.publicKeyHex));
    candidates.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return candidates;
  }

  Future<void> refreshAll({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) async {
    if (_isRefreshingAll || _watchedSensorKeys.isEmpty) {
      return;
    }

    _isRefreshingAll = true;
    notifyListeners();

    try {
      for (final key in _watchedSensorKeys) {
        Contact? contact;
        for (final entry in contactsProvider.contacts) {
          if (entry.publicKeyHex == key) {
            contact = entry;
            break;
          }
        }
        if (contact == null) {
          _refreshStates[key] = SensorRefreshState.unavailable;
          notifyListeners();
          continue;
        }

        _refreshStates[key] = SensorRefreshState.refreshing;
        notifyListeners();

        final result = await connectionProvider.smartPing(
          contactPublicKey: contact.publicKey,
          hasPath: contact.hasPath,
        );

        _refreshStates[key] = result.success
            ? SensorRefreshState.success
            : SensorRefreshState.timeout;
        notifyListeners();
      }
    } finally {
      _isRefreshingAll = false;
      notifyListeners();
    }
  }

  SensorMetric? _metricFromName(String name) {
    for (final metric in SensorMetric.values) {
      if (metric.name == name) {
        return metric;
      }
    }
    return null;
  }
}
