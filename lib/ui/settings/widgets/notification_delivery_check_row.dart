import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/notification_delivery_check_view_model.dart';
import '../view_models/trip_reminders_view_model.dart';

class NotificationDeliveryCheckRow extends ConsumerWidget {
  const NotificationDeliveryCheckRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(notificationDeliveryCheckViewModelProvider);
    final reminders = ref.watch(tripRemindersViewModelProvider);
    final enabled = reminders.enabled && !reminders.isBusy && !check.isBusy;

    return CupertinoListTile(
      title: Text(
        'Send Test Reminder',
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(
            enabled ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
            context,
          ),
        ),
      ),
      subtitle: Text(
        check.message ??
            (reminders.enabled
                ? 'Schedule a separate notification one minute ahead.'
                : 'Enable Trip Reminders first.'),
        maxLines: 4,
      ),
      trailing: check.isBusy ? const CupertinoActivityIndicator() : null,
      onTap: enabled
          ? ref.read(notificationDeliveryCheckViewModelProvider.notifier).send
          : null,
    );
  }
}
