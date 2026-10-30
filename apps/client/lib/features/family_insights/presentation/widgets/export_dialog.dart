import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/family_insights_provider.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  bool _isExporting = false;
  String? _exportedPath;
  String? _errorMessage;

  Future<void> _handleExportJson() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedPath = null;
    });

    try {
      final path = await ref.read(familyInsightsControllerProvider.notifier).exportJson();
      setState(() {
        _exportedPath = path;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _handleExportCsv(String type) async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedPath = null;
    });

    try {
      final path = await ref.read(familyInsightsControllerProvider.notifier).exportCsv(type);
      setState(() {
        _exportedPath = path;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.download_rounded, color: Colors.purpleAccent),
          SizedBox(width: 10),
          Text('Export Family Insights'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export local monitoring logs and summaries to JSON or CSV format without sending data to any external server.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_isExporting) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (_exportedPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Export Completed Successfully!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _exportedPath!,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _exportedPath!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File path copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy File Path'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Full Backup (JSON)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isExporting ? null : _handleExportJson,
                icon: const Icon(Icons.data_object_rounded, size: 18),
                label: const Text('Export Complete Dataset (.JSON)'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tabular Tables (CSV)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CsvChip(
                    label: 'App Usage',
                    onTap: () => _handleExportCsv('app_usage'),
                  ),
                  _CsvChip(
                    label: 'Daily Reports',
                    onTap: () => _handleExportCsv('daily_reports'),
                  ),
                  _CsvChip(
                    label: 'Screen Activity',
                    onTap: () => _handleExportCsv('screen'),
                  ),
                  _CsvChip(
                    label: 'Notifications',
                    onTap: () => _handleExportCsv('notifications'),
                  ),
                  _CsvChip(
                    label: 'Battery History',
                    onTap: () => _handleExportCsv('battery'),
                  ),
                  _CsvChip(
                    label: 'Network Usage',
                    onTap: () => _handleExportCsv('network'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CsvChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CsvChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.table_chart_outlined, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

