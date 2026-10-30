import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/family_insights_provider.dart';
import '../../domain/models/location_model.dart';

class LocationHistoryView extends ConsumerWidget {
  const LocationHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionsAsync = ref.watch(monitoringPermissionsMapProvider);
    final locationsAsync = ref.watch(locationHistoryListProvider);
    final latestLocationAsync = ref.watch(latestLocationRecordProvider);

    final perms = permissionsAsync.valueOrNull ?? {};
    final isLocationEnabled = perms['location_enabled'] == true;
    final isPermissionGranted = perms['location'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transparent Consent & Opt-in Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: isLocationEnabled ? Colors.green : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Location Sharing',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Explicitly opt-in only. Strictly non-covert.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isLocationEnabled,
                      onChanged: (val) {
                        ref.read(familyInsightsControllerProvider.notifier).toggleLocationMonitoring(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLocationEnabled
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocationEnabled ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 16,
                        color: isLocationEnabled ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLocationEnabled
                            ? 'Visible Status: Sharing Active for Family Safety'
                            : 'Visible Status: Location Tracking Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLocationEnabled ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocationEnabled && !isPermissionGranted) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      final service = ref.read(familyInsightsServiceProvider);
                      service?.requestLocationPermission();
                    },
                    child: const Text('Grant Location Runtime Permission'),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Latest Location Card
        latestLocationAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (latest) {
            if (latest == null) return const SizedBox.shrink();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Latest Recorded Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          DateFormat('h:mm a').format(latest.timestamp),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Latitude: ${latest.latitude.toStringAsFixed(5)}, Longitude: ${latest.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (latest.accuracy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Accuracy: ±${latest.accuracy!.toStringAsFixed(1)} meters',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Location History List
        locationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading location history: $e')),
          data: (locations) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location History Log',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${locations.length} entries',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (locations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            isLocationEnabled
                                ? 'No location entries recorded yet.'
                                : 'Location history is empty because location sharing is disabled.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: locations.take(10).length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withValues(alpha: 0.15),
                              child: const Icon(Icons.my_location_rounded, color: Colors.teal, size: 18),
                            ),
                            title: Text(
                              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                            ),
                            subtitle: Text(
                              loc.accuracy != null
                                  ? 'Accuracy: ±${loc.accuracy!.toStringAsFixed(1)}m'
                                  : 'GPS coordinate',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                            trailing: Text(
                              DateFormat('MMM d • h:mm a').format(loc.timestamp),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

