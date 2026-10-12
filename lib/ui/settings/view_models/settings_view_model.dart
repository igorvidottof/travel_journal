import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';

final settingsViewModelProvider =
    AsyncNotifierProvider.autoDispose<SettingsViewModel, String>(
      SettingsViewModel.new,
    );

class SettingsViewModel extends AsyncNotifier<String> {
  @override
  Future<String> build() => ref.watch(appInfoRepositoryProvider).loadVersion();
}
