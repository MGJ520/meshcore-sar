import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/sensors_provider.dart';

class SensorsTab extends StatelessWidget {
  const SensorsTab({super.key});

  Future<void> _showAddSensorSheet(BuildContext context) async {
    final sensorsProvider = context.read<SensorsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final candidates = sensorsProvider.availableCandidates(contactsProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (candidates.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No eligible nodes available. Discover a relay or node first.',
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const ListTile(
                title: Text(
                  'Add sensor node',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Pick a relay or node to watch in Sensors.'),
              ),
              ...candidates.map(
                (contact) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFDDEAF8),
                    child: Icon(
                      _typeIcon(contact),
                      color: const Color(0xFF1E4F7A),
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: _SensorCandidatePreview(contact: contact),
                  isThreeLine: true,
                  onTap: () async {
                    await sensorsProvider.addSensor(contact);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${contact.displayName} added to Sensors',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMetricSelector(
    BuildContext context,
    String publicKeyHex,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer<SensorsProvider>(
        builder: (context, sensorsProvider, child) {
          final visibleMetrics = sensorsProvider.visibleMetricsFor(
            publicKeyHex,
          );
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  'Visible fields',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which values appear on sensor cards.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SensorMetric.values.map((metric) {
                    final visible = visibleMetrics.contains(metric);
                    return FilterChip(
                      selected: visible,
                      label: Text(_metricLabel(metric)),
                      onSelected: (value) {
                        sensorsProvider.toggleMetric(
                          publicKeyHex,
                          metric,
                          value,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAll(BuildContext context) async {
    await context.read<SensorsProvider>().refreshAll(
      contactsProvider: context.read<ContactsProvider>(),
      connectionProvider: context.read<ConnectionProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSensorSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer2<SensorsProvider, ContactsProvider>(
        builder: (context, sensorsProvider, contactsProvider, child) {
          final watchedKeys = sensorsProvider.watchedSensorKeys;

          return RefreshIndicator(
            onRefresh: () => _refreshAll(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (watchedKeys.isEmpty)
                  const _EmptySensorsState()
                else
                  ...watchedKeys.map((key) {
                    Contact? contact;
                    for (final entry in contactsProvider.contacts) {
                      if (entry.publicKeyHex == key) {
                        contact = entry;
                        break;
                      }
                    }
                    return _SensorCard(
                      contact: contact,
                      state: sensorsProvider.stateFor(key),
                      visibleMetrics: sensorsProvider.visibleMetricsFor(key),
                      onRemove: () async {
                        await sensorsProvider.removeSensor(key);
                      },
                      onCustomize: () => _showMetricSelector(context, key),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SensorCandidatePreview extends StatelessWidget {
  final Contact contact;

  const _SensorCandidatePreview({required this.contact});

  @override
  Widget build(BuildContext context) {
    final telemetry = contact.telemetry;
    final previewLines = <String>[
      '${contact.type.displayName} • ${contact.publicKeyShort}',
      if (telemetry?.batteryPercentage != null)
        'Battery ${telemetry!.batteryPercentage!.toStringAsFixed(0)}% • '
            'Temp ${telemetry.temperature?.toStringAsFixed(1) ?? '--'}°C',
      if (telemetry?.gpsLocation != null)
        'GPS ${telemetry!.gpsLocation!.latitude.toStringAsFixed(3)}, '
            '${telemetry.gpsLocation!.longitude.toStringAsFixed(3)}',
    ];

    if (previewLines.length == 1) {
      previewLines.add('No telemetry preview available yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: previewLines
          .take(3)
          .map(
            (line) => Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
          .toList(),
    );
  }
}

class _EmptySensorsState extends StatelessWidget {
  const _EmptySensorsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEAF8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors_outlined,
              size: 40,
              color: Color(0xFF1E4F7A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No sensor nodes added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Use + to add discovered relays or nodes. Pull down to refresh telemetry after adding them.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Contact? contact;
  final SensorRefreshState state;
  final Set<SensorMetric> visibleMetrics;
  final Future<void> Function() onRemove;
  final VoidCallback onCustomize;

  const _SensorCard({
    required this.contact,
    required this.state,
    required this.visibleMetrics,
    required this.onRemove,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final telemetry = contact?.telemetry;
    final theme = Theme.of(context);
    final metrics = contact == null || telemetry == null
        ? const <_MetricCardData>[]
        : _buildMetricCards(l10n, telemetry, contact!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            contact?.displayName ?? 'Unavailable node',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (state == SensorRefreshState.timeout)
                            const _InlineAlertBadge(label: 'No response'),
                        ],
                      ),
                      if (telemetry != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTelemetryDateTime(telemetry.timestamp)} • ${_formatTelemetryTime(telemetry.timestamp)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'remove') {
                      await onRemove();
                    } else if (value == 'customize') {
                      onCustomize();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'customize',
                      child: Text('Customize fields'),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (((state != SensorRefreshState.idle &&
                        state != SensorRefreshState.timeout) ||
                    state == SensorRefreshState.unavailable) ||
                (contact != null &&
                    visibleMetrics.contains(SensorMetric.lastSeen)))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (state != SensorRefreshState.idle &&
                        state != SensorRefreshState.timeout)
                      _StatusPill(state: state),
                    if (contact != null &&
                        visibleMetrics.contains(SensorMetric.lastSeen))
                      _InfoPill(
                        icon: Icons.schedule,
                        label:
                            '${l10n.lastSeen}: ${contact!.timeSinceLastSeen}',
                      ),
                  ],
                ),
              ),
            if (contact == null)
              const Text(
                'This node is no longer available in the contact list.',
              )
            else if (telemetry == null)
              const Text('No telemetry received yet. Pull down to fetch it.')
            else if (metrics.isEmpty)
              const Text(
                'All fields are hidden. Use Visible fields to choose what to show.',
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics
                    .map((metric) => _MetricTile(data: metric))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<_MetricCardData> _buildMetricCards(
    AppLocalizations l10n,
    dynamic telemetry,
    Contact contact,
  ) {
    final items = <_MetricCardData>[];

    if (visibleMetrics.contains(SensorMetric.voltage) &&
        telemetry.batteryMilliVolts != null) {
      items.add(
        _MetricCardData(
          icon: Icons.bolt,
          label: l10n.voltage,
          value: '${(telemetry.batteryMilliVolts! / 1000).toStringAsFixed(3)}V',
          accent: const Color(0xFF0A7D61),
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.battery) &&
        telemetry.batteryPercentage != null) {
      items.add(
        _MetricCardData(
          icon: Icons.battery_5_bar,
          label: l10n.battery,
          value: '${telemetry.batteryPercentage!.toStringAsFixed(0)}%',
          accent: const Color(0xFF4B8E2F),
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.temperature) &&
        telemetry.temperature != null) {
      items.add(
        _MetricCardData(
          icon: Icons.thermostat,
          label: l10n.temperature,
          value: '${telemetry.temperature!.toStringAsFixed(1)}°C',
          accent: const Color(0xFFC76821),
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.humidity) &&
        telemetry.humidity != null) {
      items.add(
        _MetricCardData(
          icon: Icons.water_drop,
          label: l10n.humidity,
          value: '${telemetry.humidity!.toStringAsFixed(1)}%',
          accent: const Color(0xFF246BB2),
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.pressure) &&
        telemetry.pressure != null) {
      items.add(
        _MetricCardData(
          icon: Icons.compress,
          label: l10n.pressure,
          value: '${telemetry.pressure!.toStringAsFixed(1)} hPa',
          accent: const Color(0xFF6B4BAE),
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.gps) &&
        telemetry.gpsLocation != null) {
      items.add(
        _MetricCardData(
          icon: Icons.place,
          label: l10n.gpsTelemetry,
          value:
              '${telemetry.gpsLocation!.latitude.toStringAsFixed(5)}, ${telemetry.gpsLocation!.longitude.toStringAsFixed(5)}',
          accent: const Color(0xFFAA3F57),
          wide: true,
        ),
      );
    }
    if (visibleMetrics.contains(SensorMetric.updated)) {
      items.add(
        _MetricCardData(
          icon: Icons.update,
          label: l10n.updated,
          value: _formatTelemetryTime(telemetry.timestamp),
          accent: const Color(0xFF6C727F),
        ),
      );
    }
    if (telemetry.extraSensorData != null) {
      for (final entry in telemetry.extraSensorData!.entries) {
        items.add(
          _MetricCardData(
            icon: Icons.sensors,
            label: entry.key,
            value: '${entry.value}',
            accent: const Color(0xFF3E657C),
          ),
        );
      }
    }

    return items;
  }

  String _formatTelemetryTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTelemetryDateTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _StatusPill extends StatelessWidget {
  final SensorRefreshState state;

  const _StatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      SensorRefreshState.idle => (
        'Idle',
        const Color(0xFF5D7185),
        Icons.sensors,
      ),
      SensorRefreshState.refreshing => (
        'Refreshing',
        const Color(0xFF266AC2),
        Icons.sync,
      ),
      SensorRefreshState.success => (
        'Updated',
        const Color(0xFF218B63),
        Icons.check_circle,
      ),
      SensorRefreshState.timeout => (
        'No response',
        const Color(0xFFC17B1D),
        Icons.schedule,
      ),
      SensorRefreshState.unavailable => (
        'Unavailable',
        const Color(0xFFB13B55),
        Icons.error_outline,
      ),
    };

    return _InfoPill(
      icon: icon,
      label: label,
      foreground: color,
      background: color.withValues(alpha: 0.10),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:
            background ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InlineAlertBadge extends StatelessWidget {
  final String label;

  const _InlineAlertBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFC17B1D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFC17B1D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricCardData data;

  const _MetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = data.wide ? 320.0 : 168.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: data.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool wide;

  const _MetricCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.wide = false,
  });
}

String _metricLabel(SensorMetric metric) {
  return switch (metric) {
    SensorMetric.lastSeen => 'Last seen',
    SensorMetric.voltage => 'Voltage',
    SensorMetric.battery => 'Battery',
    SensorMetric.temperature => 'Temperature',
    SensorMetric.humidity => 'Humidity',
    SensorMetric.pressure => 'Pressure',
    SensorMetric.gps => 'GPS',
    SensorMetric.updated => 'Updated',
  };
}

IconData _typeIcon(Contact contact) {
  if (contact.isRepeater) {
    return Icons.router;
  }
  if (contact.isChat) {
    return Icons.sensors;
  }
  return Icons.device_hub;
}
