import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/trip_reminders_view_model.dart';
import 'settings_section.dart';
import 'notification_delivery_check_row.dart';

class TripRemindersSection extends ConsumerWidget {
  const TripRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(tripRemindersViewModelProvider);
    final viewModel = ref.read(tripRemindersViewModelProvider.notifier);

    return SettingsSection(
      title: 'Notifications',
      children: [
        CupertinoListTile(
          title: const Text('Trip Reminders'),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.bell_fill,
                size: 20,
                color: CupertinoColors.white,
              ),
            ),
          ),
          additionalInfo: reminders.isBusy
              ? const CupertinoActivityIndicator()
              : null,
          trailing: Semantics(
            label: 'Trip Reminders',
            child: CupertinoSwitch(
              value: reminders.enabled,
              onChanged: reminders.isBusy ? null : viewModel.setEnabled,
            ),
          ),
        ),
        if (kDebugMode) const NotificationDeliveryCheckRow(),
        if (reminders.message != null) ...[
          CupertinoListTile(
            title: Text(
              'Retry Reminder Synchronization',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.activeBlue,
                  context,
                ),
              ),
            ),
            onTap: reminders.isBusy ? null : viewModel.retry,
          ),
          CupertinoListTile(
            title: const Text('Open Notification Settings'),
            trailing: const CupertinoListTileChevron(),
            onTap: reminders.isBusy ? null : viewModel.openSettings,
          ),
        ],
      ],
    );
  }
}
