import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/contact_telemetry.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
import 'package:meshcore_sar_app/services/meshcore_constants.dart';

void main() {
  group('CayenneLppParser - GPS Codec Tests', () {
    test('GPS encoding uses correct 4-byte int32 LE format', () {
      // Test coordinates (Ljubljana, Slovenia)
      const double lat = 46.0569;
      const double lon = 14.5058;
      const double alt = 295.0;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
        altitude: alt,
        channel: 0,
      );

      // Expected format:
      // [0] = channel (0)
      // [1] = type (136 = 0x88 = lppGps)
      // [2-5] = lat as int32 LE
      // [6-9] = lon as int32 LE
      // [10-13] = alt as int32 LE
      expect(encoded.length, equals(14));
      expect(encoded[0], equals(0)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppGps)); // type 0x88

      // Verify little-endian encoding
      final buffer = ByteData.sublistView(encoded);
      final latEncoded = buffer.getInt32(2, Endian.little);
      final lonEncoded = buffer.getInt32(6, Endian.little);
      final altEncoded = buffer.getInt32(10, Endian.little);

      expect(latEncoded, equals(460569)); // 46.0569 * 10000
      expect(lonEncoded, equals(145058)); // 14.5058 * 10000
      expect(altEncoded, equals(29500)); // 295.0 * 100
    });

    test('GPS decoding uses correct divisor (10000, not 1000000)', () {
      // Create raw GPS telemetry packet
      final buffer = ByteData(14);
      buffer.setUint8(0, 0); // channel
      buffer.setUint8(1, MeshCoreConstants.lppGps); // type
      buffer.setInt32(2, 460569, Endian.little); // lat: 46.0569 * 10000
      buffer.setInt32(6, 145058, Endian.little); // lon: 14.5058 * 10000
      buffer.setInt32(10, 29500, Endian.little); // alt: 295.0 * 100

      final telemetry = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(telemetry.gpsLocation!.longitude, closeTo(14.5058, 0.0001));

      // Verify altitude is stored in extra data
      expect(telemetry.extraSensorData, isNotNull);
      expect(
        telemetry.extraSensorData!['altitude_0'],
        closeTo(295.0, 0.01),
      );
    });

    test('GPS round-trip encoding/decoding maintains precision', () {
      // Test various coordinates
      final testCases = [
        LatLng(46.0569, 14.5058), // Ljubljana
        LatLng(37.7749, -122.4194), // San Francisco
        LatLng(-33.8688, 151.2093), // Sydney
        LatLng(0.0, 0.0), // Null Island
        LatLng(89.9999, 179.9999), // Near max
        LatLng(-89.9999, -179.9999), // Near min
      ];

      for (final coords in testCases) {
        final encoded = CayenneLppParser.createGpsData(
          latitude: coords.latitude,
          longitude: coords.longitude,
          altitude: 100.0,
        );

        final decoded = CayenneLppParser.parse(encoded);

        expect(decoded.gpsLocation, isNotNull,
            reason: 'Failed to decode: $coords');
        expect(
          decoded.gpsLocation!.latitude,
          closeTo(coords.latitude, 0.0001),
          reason: 'Latitude mismatch for $coords',
        );
        expect(
          decoded.gpsLocation!.longitude,
          closeTo(coords.longitude, 0.0001),
          reason: 'Longitude mismatch for $coords',
        );
      }
    });

    test('GPS decoding validates coordinate ranges', () {
      // This test documents that coordinates are decoded correctly
      // and any validation warnings are logged (not enforced)

      // Valid coordinates should decode without issue
      final validBuffer = ByteData(14);
      validBuffer.setUint8(0, 0);
      validBuffer.setUint8(1, MeshCoreConstants.lppGps);
      validBuffer.setInt32(2, 450000, Endian.little); // 45.0°
      validBuffer.setInt32(6, 100000, Endian.little); // 10.0°
      validBuffer.setInt32(10, 0, Endian.little);

      final telemetry = CayenneLppParser.parse(
        validBuffer.buffer.asUint8List(),
      );

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, equals(45.0));
      expect(telemetry.gpsLocation!.longitude, equals(10.0));
    });

    test('GPS encoding handles negative coordinates correctly', () {
      const lat = -33.8688;
      const lon = -151.2093;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
      );

      // Verify signed int32 encoding
      final buffer = ByteData.sublistView(encoded);
      final latEncoded = buffer.getInt32(2, Endian.little);
      final lonEncoded = buffer.getInt32(6, Endian.little);

      expect(latEncoded, equals(-338688)); // -33.8688 * 10000
      expect(lonEncoded, equals(-1512093)); // -151.2093 * 10000

      // Verify decoding
      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation!.latitude, closeTo(lat, 0.0001));
      expect(decoded.gpsLocation!.longitude, closeTo(lon, 0.0001));
    });

    test('GPS encoding with altitude uses correct precision', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 0.0,
        longitude: 0.0,
        altitude: 1234.56,
      );

      final buffer = ByteData.sublistView(encoded);
      final altEncoded = buffer.getInt32(10, Endian.little);

      // Altitude precision is 0.01m (divide by 100)
      expect(altEncoded, equals(123456)); // 1234.56 * 100

      final decoded = CayenneLppParser.parse(encoded);
      expect(
        decoded.extraSensorData!['altitude_0'],
        closeTo(1234.56, 0.01),
      );
    });

    test('GPS encoding supports custom channel', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 1.0,
        longitude: 2.0,
        channel: 5,
      );

      expect(encoded[0], equals(5)); // channel

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.extraSensorData!['altitude_5'], isNotNull);
    });

    test('OLD BUG: divisor 1000000 would cause 99% error', () {
      // This test documents the bug that was fixed
      // The old code divided by 1,000,000 instead of 10,000

      final buffer = ByteData(14);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppGps);
      buffer.setInt32(2, 460569, Endian.little); // Should be 46.0569°
      buffer.setInt32(6, 145058, Endian.little); // Should be 14.5058°
      buffer.setInt32(10, 0, Endian.little);

      // With CORRECT divisor (10000):
      final correctLat = 460569 / 10000.0; // 46.0569
      final correctLon = 145058 / 10000.0; // 14.5058

      // With OLD BUGGY divisor (1000000):
      final buggyLat = 460569 / 1000000.0; // 0.460569 (100x too small!)
      final buggyLon = 145058 / 1000000.0; // 0.145058 (100x too small!)

      // Verify the bug would have caused ~99% error
      final errorPercent = ((correctLat - buggyLat) / correctLat) * 100;
      expect(errorPercent, closeTo(99.0, 0.1));

      // Verify current implementation uses correct divisor
      final telemetry = CayenneLppParser.parse(buffer.buffer.asUint8List());
      expect(telemetry.gpsLocation!.latitude, equals(correctLat));
      expect(telemetry.gpsLocation!.latitude, isNot(equals(buggyLat)));
    });
  });

  group('CayenneLppParser - Other Sensor Tests', () {
    test('temperature encoding and decoding', () {
      const tempCelsius = 23.5;

      final encoded = CayenneLppParser.createTemperatureData(
        tempCelsius,
        channel: 1,
      );

      expect(encoded.length, equals(4)); // channel + type + 2 bytes
      expect(encoded[0], equals(1)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppTemperatureSensor));

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('temperature handles negative values', () {
      const tempCelsius = -15.3;

      final encoded = CayenneLppParser.createTemperatureData(tempCelsius);
      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('battery voltage encoding and decoding', () {
      const voltage = 3.85;

      final encoded = CayenneLppParser.createBatteryData(voltage);

      expect(encoded.length, equals(4));
      expect(encoded[1], equals(MeshCoreConstants.lppAnalogInput));

      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
      expect(decoded.batteryPercentage, greaterThan(0));
      expect(decoded.batteryPercentage, lessThanOrEqualTo(100));
    });

    test('battery percentage calculation', () {
      // Test battery curve: 3.0V = 0%, 4.2V = 100%
      final testCases = {
        2.8: 0.0, // Below minimum
        3.0: 0.0, // Minimum
        3.6: 50.0, // Middle
        4.2: 100.0, // Maximum
        4.5: 100.0, // Above maximum
      };

      for (final entry in testCases.entries) {
        final voltage = entry.key;
        final expectedPercent = entry.value;

        final encoded = CayenneLppParser.createBatteryData(voltage);
        final decoded = CayenneLppParser.parse(encoded);

        expect(
          decoded.batteryPercentage,
          closeTo(expectedPercent, 1),
          reason: 'Battery ${voltage}V should be ~${expectedPercent}%',
        );
      }
    });

    test('analog input is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0); // channel 0
      buffer.setUint8(1, MeshCoreConstants.lppAnalogInput);
      buffer.setInt16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('voltage sensor is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppVoltageSensor);
      buffer.setUint16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('humidity sensor decoding', () {
      final buffer = ByteData(3);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppHumiditySensor);
      buffer.setUint8(2, 130); // 65% humidity (130 / 2)

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.humidity, equals(65.0));
    });

    test('barometer sensor decoding', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppBarometer);
      buffer.setUint16(2, 10132, Endian.big); // 1013.2 hPa * 10

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.pressure, closeTo(1013.2, 0.1));
    });

    test('accelerometer sensor stores in extra data', () {
      final buffer = ByteData(8);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppAccelerometer);
      buffer.setInt16(2, 1000, Endian.big); // x: 1.0 g
      buffer.setInt16(4, -500, Endian.big); // y: -0.5 g
      buffer.setInt16(6, 2000, Endian.big); // z: 2.0 g

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.extraSensorData, isNotNull);
      final accel = decoded.extraSensorData!['accelerometer_0'];
      expect(accel['x'], closeTo(1.0, 0.001));
      expect(accel['y'], closeTo(-0.5, 0.001));
      expect(accel['z'], closeTo(2.0, 0.001));
    });

    test('unknown sensor type is skipped gracefully', () {
      final buffer = ByteData(5);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, 255); // Unknown type
      buffer.setUint8(2, 1);
      buffer.setUint8(3, 2);
      buffer.setUint8(4, 3);

      // Should not throw, just skip unknown data
      expect(
        () => CayenneLppParser.parse(buffer.buffer.asUint8List()),
        returnsNormally,
      );
    });

    test('multiple sensors in single packet', () {
      // Create a combined packet with multiple sensors
      final buffer = ByteData(22);
      int offset = 0;

      // GPS (channel 2) - use channel 2 to avoid battery auto-detection
      buffer.setUint8(offset++, 2); // channel
      buffer.setUint8(offset++, MeshCoreConstants.lppGps);
      buffer.setInt32(offset, 460569, Endian.little); // lat
      offset += 4;
      buffer.setInt32(offset, 145058, Endian.little); // lon
      offset += 4;
      buffer.setInt32(offset, 0, Endian.little); // alt
      offset += 4;

      // Temperature (channel 3)
      buffer.setUint8(offset++, 3); // channel
      buffer.setUint8(offset++, MeshCoreConstants.lppTemperatureSensor);
      buffer.setInt16(offset, 235, Endian.big); // 23.5°C * 10
      offset += 2;

      // Battery (channel 0 - required for battery detection)
      buffer.setUint8(offset++, 0); // channel
      buffer.setUint8(offset++, MeshCoreConstants.lppAnalogInput);
      buffer.setInt16(offset, 385, Endian.big); // 3.85V * 100
      offset += 2;

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      // All sensors should be decoded
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(decoded.temperature, closeTo(23.5, 0.1));
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('empty data returns empty telemetry', () {
      final empty = Uint8List(0);
      final decoded = CayenneLppParser.parse(empty);

      expect(decoded.gpsLocation, isNull);
      expect(decoded.batteryPercentage, isNull);
      expect(decoded.temperature, isNull);
      expect(decoded.extraSensorData, isNull);
      expect(decoded.timestamp, isNotNull); // Timestamp is always set
    });

    test('timestamp is set to parse time', () {
      final before = DateTime.now();
      final data = CayenneLppParser.createTemperatureData(20.0);
      final decoded = CayenneLppParser.parse(data);
      final after = DateTime.now();

      expect(
        decoded.timestamp.isAfter(before) ||
            decoded.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        decoded.timestamp.isBefore(after) ||
            decoded.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('CayenneLppParser - ContactTelemetry Properties', () {
    test('isRecent returns true for fresh telemetry', () {
      final data = CayenneLppParser.createTemperatureData(20.0);
      final telemetry = CayenneLppParser.parse(data);

      expect(telemetry.isRecent, isTrue);
    });

    test('battery status helpers work correctly', () {
      final lowBattery = ContactTelemetry(
        batteryPercentage: 15.0,
        timestamp: DateTime.now(),
      );
      expect(lowBattery.isLowBattery, isTrue);
      expect(lowBattery.batteryStatus, equals('low'));

      final criticalBattery = ContactTelemetry(
        batteryPercentage: 5.0,
        timestamp: DateTime.now(),
      );
      expect(criticalBattery.isCriticalBattery, isTrue);

      final goodBattery = ContactTelemetry(
        batteryPercentage: 75.0,
        timestamp: DateTime.now(),
      );
      expect(goodBattery.isLowBattery, isFalse);
      expect(goodBattery.batteryStatus, equals('good'));
    });

    test('copyWith creates modified copy', () {
      final original = ContactTelemetry(
        gpsLocation: LatLng(1, 2),
        batteryPercentage: 50.0,
        temperature: 20.0,
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(temperature: 25.0);

      expect(modified.temperature, equals(25.0));
      expect(modified.batteryPercentage, equals(50.0)); // Unchanged
      expect(modified.gpsLocation, equals(original.gpsLocation)); // Unchanged
    });

    test('toString provides readable output', () {
      final telemetry = ContactTelemetry(
        gpsLocation: LatLng(46.0569, 14.5058),
        batteryPercentage: 75.0,
        temperature: 23.5,
        timestamp: DateTime.now(),
      );

      final str = telemetry.toString();
      expect(str, contains('ContactTelemetry'));
      expect(str, contains('46.0569'));
      expect(str, contains('75'));
      expect(str, contains('23.5'));
    });
  });
}
