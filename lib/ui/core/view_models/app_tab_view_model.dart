import 'package:flutter_riverpod/flutter_riverpod.dart';

final appTabViewModelProvider = NotifierProvider<AppTabViewModel, int>(
  AppTabViewModel.new,
);

/// App-wide tab selection; each tab retains its own navigation stack.
class AppTabViewModel extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (index < 0 || index > 2) throw RangeError.range(index, 0, 2);
    state = index;
  }

  void selectTrips() => selectTab(0);
}
