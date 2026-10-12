import 'package:cupertino_ui/cupertino_ui.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: Semantics(header: true, child: Text(title.toUpperCase())),
      footer: footer == null ? null : Text(footer!),
      children: children,
    );
  }
}
