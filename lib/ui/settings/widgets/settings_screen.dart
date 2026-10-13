import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/settings_view_model.dart';
import 'settings_row.dart';
import 'settings_section.dart';
import 'trip_reminders_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(settingsViewModelProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const SettingsSection(
              title: 'Appearance',
              children: [
                SettingsRow.information(
                  title: 'Appearance',
                  description:
                      'Travel Journal currently follows your device’s light or dark appearance. Choosing an appearance within the app is coming in a future update.',
                  icon: CupertinoIcons.circle_lefthalf_fill,
                  iconColor: CupertinoColors.systemIndigo,
                  value: 'System',
                ),
              ],
            ),
            const SettingsSection(
              title: 'Preferences',
              children: [
                SettingsRow.information(
                  title: 'Language',
                  description:
                      'Travel Journal currently uses English. Choosing another app language is coming in a future update.',
                  icon: CupertinoIcons.globe,
                  iconColor: CupertinoColors.systemBlue,
                  value: 'English',
                ),
              ],
            ),
            const TripRemindersSection(),
            const SettingsSection(
              title: 'Data & Storage',
              children: [
                SettingsRow.information(
                  title: 'Storage',
                  description:
                      'This setting will let you review the storage used by your travel journal. Storage management is not available yet.',
                  icon: CupertinoIcons.archivebox_fill,
                  iconColor: CupertinoColors.systemOrange,
                ),
                SettingsRow.information(
                  title: 'Export Travel Data',
                  description:
                      'This option will let you export your travel journal data. Exporting is not available yet.',
                  icon: CupertinoIcons.square_arrow_up,
                  iconColor: CupertinoColors.systemGreen,
                ),
              ],
            ),
            SettingsSection(
              title: 'About',
              children: [
                const SettingsRow.information(
                  title: 'About Travel Journal',
                  description:
                      'Travel Journal is a place to keep your trips, destinations, and travel photos. A full About screen is coming in a future update.',
                  icon: CupertinoIcons.info_circle_fill,
                  iconColor: CupertinoColors.systemBlue,
                ),
                const SettingsRow.information(
                  title: 'Privacy Policy',
                  description:
                      'This option will show Travel Journal’s privacy policy and explain how the app handles your data. The privacy policy is not available yet.',
                  icon: CupertinoIcons.hand_raised_fill,
                  iconColor: CupertinoColors.systemPurple,
                ),
                SettingsRow.value(
                  title: 'App Version',
                  icon: CupertinoIcons.number,
                  iconColor: CupertinoColors.systemGrey,
                  value: version.when(
                    data: (value) => value.isEmpty ? 'Unavailable' : value,
                    loading: () => 'Loading…',
                    error: (error, stackTrace) => 'Unavailable',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
