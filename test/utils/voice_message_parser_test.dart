import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';

void main() {
  group('VoiceEnvelope', () {
    test('encodes and parses valid envelope', () {
      final env = VoiceEnvelope(
        sessionId: 'deadbeef',
        mode: VoicePacketMode.mode1200,
        total: 4,
        durationMs: 3200,
        senderKey6: 'aabbccddeeff',
        timestampSec: 1700000000,
      );

      final text = env.encodeText();
      expect(VoiceEnvelope.isVoiceEnvelopeText(text), isTrue);

      final parsed = VoiceEnvelope.tryParseText(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('deadbeef'));
      expect(parsed.mode, equals(VoicePacketMode.mode1200));
      expect(parsed.total, equals(4));
      expect(parsed.durationMs, equals(3200));
      expect(parsed.senderKey6, equals('aabbccddeeff'));
      expect(parsed.version, equals(1));
    });

    test('rejects invalid envelope payload', () {
      final text = 'VE1:nothex:1:2:1000:aabbccddeeff:1700000000:1';
      expect(VoiceEnvelope.tryParseText(text), isNull);
    });
  });

  group('VoiceFetchRequest', () {
    test('encodes and parses valid request', () {
      final req = VoiceFetchRequest(
        sessionId: '00112233',
        requesterKey6: 'ffeeddccbbaa',
        timestampSec: 1700000001,
      );
      final text = req.encodeText();
      expect(VoiceFetchRequest.isVoiceFetchRequestText(text), isTrue);

      final parsed = VoiceFetchRequest.tryParseText(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('00112233'));
      expect(parsed.want, equals('all'));
      expect(parsed.requesterKey6, equals('ffeeddccbbaa'));
      expect(parsed.version, equals(1));
    });

    test('rejects invalid request payload', () {
      expect(
        VoiceFetchRequest.tryParseText(
          'VR1:00112233:chunk:ffeeddccbbaa:1700000001:1',
        ),
        isNull,
      );
    });
  });

  group('VoicePacket backward compatibility', () {
    test('parses legacy V: text format', () {
      final pkt = VoicePacket(
        sessionId: 'a1b2c3d4',
        mode: VoicePacketMode.mode700c,
        index: 0,
        total: 1,
        codec2Data: Uint8List.fromList([1, 2, 3, 4]),
      );
      final encoded = pkt.encodeText();
      final parsed = VoicePacket.tryParseText(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('a1b2c3d4'));
      expect(parsed.total, equals(1));
      expect(parsed.codec2Data, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('constructs binary datagram from actual packet data', () {
      final actualCodec2 = Uint8List.fromList([
        0xD3,
        0x19,
        0x7A,
        0x00,
        0xFE,
        0x44,
        0xC1,
        0x2B,
        0x88,
      ]);

      final pkt = VoicePacket(
        sessionId: '01020304',
        mode: VoicePacketMode.mode1300,
        index: 2,
        total: 5,
        codec2Data: actualCodec2,
      );

      final datagram = pkt.encodeBinary();
      expect(datagram[0], equals(0x56)); // magic 'V'
      expect(datagram.sublist(1, 5), equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(datagram[5], equals(VoicePacketMode.mode1300.id));
      expect(datagram[6], equals(2));
      expect(datagram[7], equals(5));
      expect(datagram.sublist(8), equals(actualCodec2));

      final parsed = VoicePacket.tryParseBinary(datagram);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.mode, equals(VoicePacketMode.mode1300));
      expect(parsed.index, equals(2));
      expect(parsed.total, equals(5));
      expect(parsed.codec2Data, equals(actualCodec2));
    });
  });

  group('VoiceWaveform', () {
    test('builds bars from packet bytes', () {
      final packet = VoicePacket(
        sessionId: '1234abcd',
        mode: VoicePacketMode.mode1200,
        index: 0,
        total: 1,
        codec2Data: Uint8List.fromList([
          0,
          255,
          10,
          245,
          120,
          130,
          64,
          192,
          32,
          224,
        ]),
      );

      final bars = VoiceWaveform.buildBarsFromPackets([packet], bars: 8);
      expect(bars.length, equals(8));
      expect(bars.every((v) => v >= 0.0 && v <= 1.0), isTrue);
      expect(bars.any((v) => v > 0.2), isTrue);
    });

    test('returns zeros for missing packet data', () {
      final bars = VoiceWaveform.buildBarsFromPackets(const [], bars: 6);
      expect(bars, equals(List<double>.filled(6, 0.0)));
    });
  });
}
