import 'dart:convert';
import '../models/map_drawing.dart';

/// Parser for drawing messages transmitted over mesh network
class DrawingMessageParser {
  /// Drawing message prefix
  static const String prefix = 'D:';

  /// Check if message is a drawing message
  static bool isDrawingMessage(String text) {
    return text.startsWith(prefix);
  }

  /// Parse drawing message text into MapDrawing object
  /// senderName and messageId should be extracted from packet metadata
  /// Returns null if parsing fails
  static MapDrawing? parseDrawingMessage(
    String text, {
    String? senderName,
    String? messageId,
  }) {
    if (!isDrawingMessage(text)) {
      return null;
    }

    try {
      // Remove prefix
      final jsonStr = text.substring(prefix.length);

      // Parse JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Use ultra-compact network format parser
      // Sender name and message ID come from packet metadata, not JSON
      return MapDrawing.fromNetworkJson(
        json,
        senderName: senderName,
        messageId: messageId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create drawing message text from MapDrawing object
  /// Sender will be determined from packet metadata on receiving end
  static String createDrawingMessage(MapDrawing drawing) {
    final json = drawing.toNetworkJson();
    final jsonStr = jsonEncode(json);
    return '$prefix$jsonStr';
  }
}
