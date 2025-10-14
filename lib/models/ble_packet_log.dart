import 'dart:typed_data';
import '../services/meshcore_opcode_names.dart';

/// Represents a logged BLE packet with timestamp and metadata
class BlePacketLog {
  final DateTime timestamp;
  final Uint8List rawData;
  final PacketDirection direction;
  final int? responseCode;
  final String? description;

  BlePacketLog({
    required this.timestamp,
    required this.rawData,
    required this.direction,
    this.responseCode,
    this.description,
  });

  /// Convert raw data to hex string for display
  String get hexData {
    return rawData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  /// Get opcode name for this packet
  String get opcodeName {
    if (responseCode == null) return 'N/A';
    return MeshCoreOpcodeNames.getOpcodeName(
      responseCode!,
      isTx: direction == PacketDirection.tx,
    );
  }

  /// Get full opcode description (name + hex code)
  String get opcodeDescription {
    if (responseCode == null) return 'N/A';
    return MeshCoreOpcodeNames.getOpcodeDescription(
      responseCode!,
      isTx: direction == PacketDirection.tx,
    );
  }

  /// Get short summary of the packet
  String get summary {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? '0x${responseCode!.toRadixString(16).padLeft(2, '0')}' : 'N/A';
    final name = responseCode != null ? opcodeName : '';
    return '[$dir] $name Code: $code, Size: ${rawData.length} bytes';
  }

  /// Convert to CSV format for export
  String toCsvRow() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode?.toString() ?? '';
    final name = responseCode != null ? opcodeName : '';
    final hex = hexData;
    final desc = description ?? '';
    return '${timestamp.toIso8601String()},$dir,${rawData.length},$name,$code,"$hex","$desc"';
  }

  /// Convert to human-readable log format
  String toLogString() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? ' [$opcodeDescription]' : '';
    final desc = description != null ? ' - $description' : '';
    return '${timestamp.toIso8601String()} [$dir]$code ${rawData.length} bytes: $hexData$desc';
  }
}

enum PacketDirection {
  rx, // Received from device
  tx, // Sent to device
}
