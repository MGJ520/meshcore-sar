import 'package:flutter/widgets.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';

/// Extension for Message to provide localized delivery status
extension MessageLocalization on Message {
  /// Get localized delivery status text
  String getLocalizedDeliveryStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (deliveryStatus) {
      case MessageDeliveryStatus.sending:
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
}
