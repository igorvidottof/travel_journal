import 'package:cupertino_ui/cupertino_ui.dart';

/// Separates read-only metadata from settings with informational dialogs.
class SettingsRow extends StatelessWidget {
  const SettingsRow.value({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required String this.value,
  }) : description = null;

  const SettingsRow.information({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required String this.description,
    this.value,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? value;
  final String? description;

  Future<void> _showDescription(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(description!),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onTap = description == null ? null : () => _showDescription(context);

    return Semantics(
      label: title,
      value: value,
      button: onTap == null ? null : true,
      hint: onTap == null ? null : 'Show setting description',
      onTap: onTap,
      // Decorative symbols and chevrons must not be announced as controls.
      child: ExcludeSemantics(
        child: CupertinoListTile(
          title: Text(title, maxLines: 2),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(iconColor, context),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: CupertinoColors.white),
            ),
          ),
          additionalInfo: value == null ? null : Text(value!),
          trailing: onTap == null ? null : const CupertinoListTileChevron(),
          onTap: onTap,
        ),
      ),
    );
  }
}
