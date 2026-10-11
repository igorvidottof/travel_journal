import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/create_trip_view_model.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _destinationFocus = FocusNode();

  @override
  void dispose() {
    _destinationFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(createTripViewModelProvider.notifier)
        .saveTrip();
    if (mounted && saved) Navigator.of(context).pop();
  }

  Future<void> _cancel() async {
    final state = ref.read(createTripViewModelProvider);
    if (state.isSaving) return;
    FocusScope.of(context).unfocus();
    final hasChanges =
        state.name.isNotEmpty ||
        state.destination.isNotEmpty ||
        state.startDate != null ||
        state.endDate != null;
    if (hasChanges) {
      final discard = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Discard trip?'),
          content: const Text('Your changes will be lost.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Editing'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    FocusScope.of(context).unfocus();
    final state = ref.read(createTripViewModelProvider);
    if (state.isSaving) return;
    final now = DateTime.now();
    var selected =
        (isStartDate ? state.startDate : state.endDate) ??
        state.startDate ??
        state.endDate ??
        DateTime(now.year, now.month, now.day);
    final minimum = isStartDate ? null : state.startDate;
    final maximum = isStartDate ? state.endDate : null;
    if (minimum != null && selected.isBefore(minimum)) selected = minimum;
    if (maximum != null && selected.isAfter(maximum)) selected = maximum;

    final date = await showCupertinoModalPopup<DateTime>(
      context: context,
      semanticsDismissible: true,
      builder: (context) => Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text('Done'),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selected,
                  minimumDate: minimum,
                  maximumDate: maximum,
                  onDateTimeChanged: (date) {
                    selected = DateTime(date.year, date.month, date.day);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || date == null) return;
    final viewModel = ref.read(createTripViewModelProvider.notifier);
    if (isStartDate) {
      viewModel.updateStartDate(date);
    } else {
      viewModel.updateEndDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTripViewModelProvider);
    final viewModel = ref.read(createTripViewModelProvider.notifier);
    final localizations = CupertinoLocalizations.of(context);
    String formatDate(DateTime date) =>
        '${localizations.datePickerMediumDate(date)}, '
        '${localizations.datePickerYear(date.year)}';

    return PopScope<void>(
      canPop: !state.isSaving,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Create Trip'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: state.isSaving ? null : _cancel,
            child: const Text('Cancel'),
          ),
          trailing: state.isSaving
              ? Semantics(
                  label: 'Saving trip',
                  liveRegion: true,
                  child: const CupertinoActivityIndicator(),
                )
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _save,
                  child: const Text('Save'),
                ),
        ),
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              CupertinoFormSection.insetGrouped(
                header: const Text('TRIP DETAILS'),
                children: [
                  CupertinoTextFormFieldRow(
                    prefix: const Text('Trip name'),
                    placeholder: 'Summer vacation',
                    initialValue: state.name,
                    enabled: !state.isSaving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: viewModel.updateName,
                    onFieldSubmitted: (_) => _destinationFocus.requestFocus(),
                  ),
                  CupertinoTextFormFieldRow(
                    prefix: const Text('Destination'),
                    placeholder: 'Paris, France',
                    initialValue: state.destination,
                    focusNode: _destinationFocus,
                    enabled: !state.isSaving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: viewModel.updateDestination,
                    onFieldSubmitted: (_) => _destinationFocus.unfocus(),
                  ),
                ],
              ),
              CupertinoFormSection.insetGrouped(
                header: const Text('DATES'),
                children: [
                  CupertinoFormRow(
                    prefix: const Text('Start date'),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: state.isSaving
                          ? null
                          : () => _selectDate(isStartDate: true),
                      child: Text(
                        state.startDate == null
                            ? 'Select'
                            : formatDate(state.startDate!),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('End date'),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: state.isSaving
                          ? null
                          : () => _selectDate(isStartDate: false),
                      child: Text(
                        state.endDate == null
                            ? 'Select'
                            : formatDate(state.endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: CupertinoColors.systemRed.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
