import 'package:flutter/material.dart';

/// SAR Template - Customizable template for SAR (Cursor on Target) messages
class SarTemplate {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final String colorHex;
  final bool isDefault;

  SarTemplate({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.colorHex,
    this.isDefault = false,
  });

  /// Get color from hex string
  Color get color {
    final hexCode = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Create from JSON
  factory SarTemplate.fromJson(Map<String, dynamic> json) {
    return SarTemplate(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      colorHex: json['colorHex'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'isDefault': isDefault,
    };
  }

  /// Create from SAR message format (S:emoji:0,0:description)
  /// Example: S:🧑:0,0:Person found
  factory SarTemplate.fromSarMessage(String message) {
    final trimmed = message.trim();
    if (!trimmed.startsWith('S:')) {
      throw FormatException('SAR message must start with "S:"');
    }

    // Parse format: S:emoji:lat,lon:description
    final parts = trimmed.split(':');
    if (parts.length < 3) {
      throw FormatException('Invalid SAR message format');
    }

    final emoji = parts[1].trim();
    if (emoji.isEmpty) {
      throw FormatException('Emoji cannot be empty');
    }

    // Extract description (everything after the third colon)
    String description = '';
    if (parts.length > 3) {
      description = parts.sublist(3).join(':').trim();
    }

    // Generate ID from emoji + description
    final id = '${emoji}_${DateTime.now().millisecondsSinceEpoch}';

    // Auto-assign color based on emoji
    String colorHex = _getColorForEmoji(emoji);

    return SarTemplate(
      id: id,
      emoji: emoji,
      name: description.isNotEmpty ? description : emoji,
      description: description,
      colorHex: colorHex,
      isDefault: false,
    );
  }

  /// Convert to SAR message format with placeholder coordinates
  /// Example: S:🧑:0,0:Person found
  String toSarMessage() {
    if (description.isNotEmpty) {
      return 'S:$emoji:0,0:$description';
    }
    return 'S:$emoji:0,0';
  }

  /// Auto-assign color based on emoji
  static String _getColorForEmoji(String emoji) {
    // Default emoji to color mapping
    final colorMap = {
      '🧑': '#4CAF50', // Green - Person
      '👤': '#4CAF50', // Green - Person
      '🔥': '#F44336', // Red - Fire
      '🏕️': '#FF9800', // Orange - Staging
      '⛺': '#FF9800', // Orange - Staging
      '📦': '#9C27B0', // Purple - Object
      '🚁': '#2196F3', // Blue - Helicopter
      '🚒': '#F44336', // Red - Fire truck
      '🚑': '#F44336', // Red - Ambulance
      '⚠️': '#FFC107', // Yellow - Warning
      '❌': '#F44336', // Red - Hazard
      '✅': '#4CAF50', // Green - Safe
      '🏥': '#F44336', // Red - Medical
      '💧': '#2196F3', // Blue - Water
      '🌲': '#4CAF50', // Green - Forest
      '⛰️': '#795548', // Brown - Mountain
    };

    return colorMap[emoji] ?? '#9E9E9E'; // Default gray
  }

  /// Copy with modifications
  SarTemplate copyWith({
    String? id,
    String? emoji,
    String? name,
    String? description,
    String? colorHex,
    bool? isDefault,
  }) {
    return SarTemplate(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'SarTemplate(id: $id, emoji: $emoji, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SarTemplate && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Default templates (matches existing SarMarkerType)
  static List<SarTemplate> get defaults {
    return [
      SarTemplate(
        id: 'default_found_person',
        emoji: '🧑',
        name: 'Found Person',
        description: '',
        colorHex: '#4CAF50',
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_fire',
        emoji: '🔥',
        name: 'Fire',
        description: '',
        colorHex: '#F44336',
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_staging_area',
        emoji: '🏕️',
        name: 'Staging Area',
        description: '',
        colorHex: '#FF9800',
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_object',
        emoji: '📦',
        name: 'Object',
        description: '',
        colorHex: '#9C27B0',
        isDefault: true,
      ),
    ];
  }
}
