import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_info.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/meshcore_ble_service.dart';
import '../services/cayenne_lpp_parser.dart';
import '../utils/sar_message_parser.dart';

/// Connection Provider - manages MeshCore BLE connection
class ConnectionProvider with ChangeNotifier {
  final MeshCoreBleService _bleService = MeshCoreBleService();

  /// Expose BLE service for background location tracking
  MeshCoreBleService get bleService => _bleService;

  DeviceInfo _deviceInfo = DeviceInfo();
  DeviceInfo get deviceInfo => _deviceInfo;

  List<BluetoothDevice> _scannedDevices = [];
  List<BluetoothDevice> get scannedDevices => _scannedDevices;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String? _error;
  String? get error => _error;

  // Callbacks for other providers
  Function(Contact)? onContactReceived;
  Function(List<Contact>)? onContactsComplete;
  Function(Message)? onMessageReceived;
  Function(Uint8List publicKey, Uint8List lppData)? onTelemetryReceived;

  ConnectionProvider() {
    _initializeBleService();
  }

  void _initializeBleService() {
    _bleService.onConnectionStateChanged = (isConnected) {
      print('🔔 [Provider] Connection state callback fired: $isConnected');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: isConnected
            ? ConnectionState.connected
            : ConnectionState.disconnected,
        lastUpdate: DateTime.now(),
      );
      print('  Updated deviceInfo.connectionState: ${_deviceInfo.connectionState}');
      print('  Updated deviceInfo.isConnected: ${_deviceInfo.isConnected}');
      notifyListeners();
      print('  Notified listeners');
    };

    _bleService.onError = (error) {
      print('⚠️ [Provider] BLE error received: $error');
      print('  Current connection state: ${_deviceInfo.connectionState}');

      _error = error;

      // Only set connection state to error if we're not already connected
      // Data parsing errors after connection shouldn't disconnect us
      if (_deviceInfo.connectionState != ConnectionState.connected) {
        print('  Setting connection state to error');
        _deviceInfo = _deviceInfo.copyWith(
          connectionState: ConnectionState.error,
        );
      } else {
        print('  Keeping connection state as connected (ignoring data parsing error)');
      }

      notifyListeners();
    };

    _bleService.onContactReceived = (contact) {
      onContactReceived?.call(contact);
    };

    _bleService.onContactsComplete = (contacts) {
      onContactsComplete?.call(contacts);
    };

    _bleService.onMessageReceived = (message) {
      // Parse SAR markers
      final enhancedMessage = SarMessageParser.enhanceMessage(message);
      onMessageReceived?.call(enhancedMessage);
    };

    _bleService.onTelemetryReceived = (publicKey, lppData) {
      onTelemetryReceived?.call(publicKey, lppData);
    };
  }

  /// Start scanning for MeshCore devices
  Future<void> startScan() async {
    print('🔍 [Provider] startScan() called');
    _isScanning = true;
    _scannedDevices.clear();
    _error = null;
    notifyListeners();
    print('✅ [Provider] Scan state initialized, notifying listeners');

    try {
      await for (final device
          in _bleService.scanForDevices(timeout: const Duration(seconds: 10))) {
        print('📱 [Provider] Device received from scan stream');
        if (!_scannedDevices.any((d) => d.remoteId == device.remoteId)) {
          _scannedDevices.add(device);
          print('✅ [Provider] Added device to list: ${device.platformName}, total: ${_scannedDevices.length}');
          notifyListeners();
        } else {
          print('  ⏭️ [Provider] Device already in list, skipping');
        }
      }
    } catch (e) {
      print('❌ [Provider] Scan error: $e');
      _error = 'Scan error: $e';
    } finally {
      print('🏁 [Provider] Scan completed');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a device
  Future<bool> connect(BluetoothDevice device) async {
    print('🔵 [Provider] connect() called for device: ${device.platformName}');

    _deviceInfo = _deviceInfo.copyWith(
      deviceId: device.remoteId.toString(),
      deviceName: device.platformName.isNotEmpty ? device.platformName : 'Unknown',
      connectionState: ConnectionState.connecting,
    );
    _error = null;
    print('✅ [Provider] Device info updated to connecting state');
    notifyListeners();

    print('🔵 [Provider] Calling BLE service connect()...');
    final success = await _bleService.connect(device);

    if (success) {
      print('✅ [Provider] BLE service connect() returned success');
    } else {
      print('❌ [Provider] BLE service connect() returned failure');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: ConnectionState.error,
      );
      notifyListeners();
    }
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _deviceInfo = _deviceInfo.copyWith(
      connectionState: ConnectionState.disconnecting,
    );
    notifyListeners();

    await _bleService.disconnect();

    _deviceInfo = DeviceInfo(
      connectionState: ConnectionState.disconnected,
    );
    notifyListeners();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.getContacts();
    } catch (e) {
      _error = 'Failed to get contacts: $e';
      notifyListeners();
    }
  }

  /// Send text message to contact
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
      );
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  /// Send channel message
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.sendChannelMessage(
        channelIdx: channelIdx,
        text: text,
      );
    } catch (e) {
      _error = 'Failed to send channel message: $e';
      notifyListeners();
    }
  }

  /// Request telemetry from contact
  Future<void> requestTelemetry(Uint8List contactPublicKey) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.requestTelemetry(contactPublicKey);
    } catch (e) {
      _error = 'Failed to request telemetry: $e';
      notifyListeners();
    }
  }

  /// Set device time to current time
  Future<void> syncDeviceTime() async {
    if (!_bleService.isConnected) return;

    try {
      await _bleService.setDeviceTime();
    } catch (e) {
      _error = 'Failed to sync time: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
