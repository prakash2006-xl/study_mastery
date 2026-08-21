import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Profile Section
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text('K', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kavin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('kavin@example.com', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Edit Profile'),
              )
            ],
          ),
          const SizedBox(height: 40),
          
          _buildSectionHeader('App Settings'),
          _buildSettingsTile(Icons.dark_mode, 'Dark Mode', true),
          _buildSettingsTile(Icons.notifications, 'Notifications', true),
          _buildSettingsTile(Icons.volume_up, 'Sound Effects', true),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsActionTile(Icons.cloud_sync, 'Sync Data', 'Last synced: 2 mins ago'),
          _buildSettingsActionTile(Icons.download, 'Export Data', 'Export to PDF/JSON'),
          _buildSettingsActionTile(Icons.delete_forever, 'Clear App Data', 'Warning: Irreversible', isDestructive: true),
          const SizedBox(height: 24),
          
          _buildSectionHeader('About'),
          _buildSettingsActionTile(Icons.info_outline, 'Version', '1.0.0 (Build 42)'),
          _buildSettingsActionTile(Icons.policy, 'Privacy Policy', ''),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, bool value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildSettingsActionTile(IconData icon, String title, String subtitle, {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : null),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.redAccent : null,
          ),
        ),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
