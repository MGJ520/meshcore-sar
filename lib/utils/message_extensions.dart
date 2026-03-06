import 'package:flutter/widgets.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';

/// Extension for Message to provide localized delivery status
extension MessageLocalization on Message {
  /// Get localized delivery status text
  String getLocalizedDeliveryStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // For channel messages, show echo count instead of delivery status
    if (isChannelMessage && deliveryStatus == MessageDeliveryStatus.sent) {
      final latestMeta = _formatEchoMeta(context);
      if (echoCount == 0) {
        return l10n.broadcast; // "Broadcast (no echoes yet)"
      } else if (echoCount == 1) {
        return latestMeta == null ? '1 node' : '1 node • $latestMeta';
      } else {
        return latestMeta == null
            ? '$echoCount nodes'
            : '$echoCount nodes • $latestMeta';
      }
    }

    switch (deliveryStatus) {
      case MessageDeliveryStatus.sending:
        if (isContactMessage) {
          return l10n.pending;
        }
        return l10n.sending;
      case MessageDeliveryStatus.sent:
        return l10n.sent;
      case MessageDeliveryStatus.delivered:
        if (roundTripTimeMs != null) {
          return l10n.deliveredWithTime(roundTripTimeMs!);
        }
        return l10n.delivered;
      case MessageDeliveryStatus.failed:
        return l10n.failed;
      case MessageDeliveryStatus.received:
        return '';
    }
  }

  /// Get localized time ago string
  String getLocalizedTimeAgo(BuildContext context) {
    final diff = DateTime.now().difference(sentAt);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  String? _formatEchoMeta(BuildContext context) {
    if (lastEchoSnrRaw == null &&
        lastEchoRssiDbm == null &&
        lastEchoAt == null) {
      return null;
    }

    final parts = <String>[];
    if (lastEchoRssiDbm != null) {
      parts.add('R ${_barsForRssi(lastEchoRssiDbm!)} $lastEchoRssiDbm dBm');
    }
    if (lastEchoSnrRaw != null) {
      final snrDb = lastEchoSnrRaw!.toSigned(8) / 4.0;
      parts.add('S ${_barsForSnr(snrDb)} ${snrDb.toStringAsFixed(1)} dB');
    }
    if (lastEchoAt != null) {
      final diff = DateTime.now().difference(lastEchoAt!);
      final l10n = AppLocalizations.of(context)!;
      if (diff.inMinutes < 1) {
        parts.add(l10n.justNow);
      } else if (diff.inMinutes < 60) {
        parts.add(l10n.minutesAgo(diff.inMinutes));
      } else if (diff.inHours < 24) {
        parts.add(l10n.hoursAgo(diff.inHours));
      } else {
        parts.add(l10n.daysAgo(diff.inDays));
      }
    }

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  String _barsForRssi(int rssiDbm) {
    // Approximate useful RSSI range: -120..-70 dBm
    final score = ((rssiDbm + 120) / 10).round().clamp(0, 5);
    return _asciiBars(score, 5);
  }

  String _barsForSnr(double snrDb) {
    // Approximate useful SNR range: -5..+20 dB
    final score = ((snrDb + 5.0) / 5.0).round().clamp(0, 5);
    return _asciiBars(score, 5);
  }

  String _asciiBars(int filled, int total) {
    return '[${'#' * filled}${'-' * (total - filled)}]';
  }
}
