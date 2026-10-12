import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

/// Reveals an action without dismissing the row before deletion is committed.
class TripSwipeAction extends StatefulWidget {
  const TripSwipeAction({
    super.key,
    required this.child,
    required this.onDelete,
    this.isBusy = false,
  });

  final Widget child;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  State<TripSwipeAction> createState() => _TripSwipeActionState();
}

class _TripSwipeActionState extends State<TripSwipeAction>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 88.0;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  void _delete() {
    _controller.animateTo(0, curve: Curves.easeOut);
    widget.onDelete();
  }

  void _settle(double velocity) {
    final open = velocity.abs() > 400 ? velocity < 0 : _controller.value >= 0.5;
    _controller.animateTo(open ? 1 : 0, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      customSemanticsActions: widget.isBusy
          ? null
          : {const CustomSemanticsAction(label: 'Delete'): _delete},
      child: GestureDetector(
        onHorizontalDragStart: widget.isBusy ? null : (_) => _controller.stop(),
        onHorizontalDragUpdate: widget.isBusy
            ? null
            : (details) {
                _controller.value =
                    (_controller.value - details.delta.dx / _actionWidth).clamp(
                      0.0,
                      1.0,
                    );
              },
        onHorizontalDragEnd: widget.isBusy
            ? null
            : (details) => _settle(details.primaryVelocity ?? 0),
        onHorizontalDragCancel: widget.isBusy ? null : () => _settle(0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => ClipRect(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: _actionWidth,
                  child: ExcludeSemantics(
                    excluding: _controller.value == 0,
                    child: IgnorePointer(
                      ignoring: _controller.value == 0 || widget.isBusy,
                      child: ColoredBox(
                        color: CupertinoColors.systemRed.resolveFrom(context),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.isBusy ? null : _delete,
                          child: widget.isBusy
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(-_actionWidth * _controller.value, 0),
                  child: ColoredBox(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
