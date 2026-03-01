import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessagesProvider voice detection', () {
    test('marks VE1 envelope messages as voice', () {
      final provider = MessagesProvider();
      final envelope = VoiceEnvelope(
        sessionId: 'deafbead',
        mode: VoicePacketMode.mode1200,
        total: 3,
        durationMs: 2400,
        senderKey6: 'aabbccddeeff',
        timestampSec: 1700000000,
      );

      final message = Message(
        id: 'm1',
        messageType: MessageType.channel,
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: envelope.encodeText(),
        receivedAt: DateTime.now(),
        senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        deliveryStatus: MessageDeliveryStatus.sent,
      );

      provider.addMessage(message);
      final stored = provider.messages.single;
      expect(stored.isVoice, isTrue);
      expect(stored.voiceId, equals('deafbead'));
    });

    test('marks legacy V text packets as voice', () {
      final provider = MessagesProvider();
      final packet = VoicePacket(
        sessionId: '00112233',
        mode: VoicePacketMode.mode700c,
        index: 0,
        total: 1,
        codec2Data: Uint8List.fromList([1, 2, 3]),
      );
      final message = Message(
        id: 'm2',
        messageType: MessageType.channel,
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000001,
        text: packet.encodeText(),
        receivedAt: DateTime.now(),
        senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        deliveryStatus: MessageDeliveryStatus.sent,
      );

      provider.addMessage(message);
      final stored = provider.messages.single;
      expect(stored.isVoice, isTrue);
      expect(stored.voiceId, equals('00112233'));
    });
  });
}
