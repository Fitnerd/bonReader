import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/data_providers.dart';

/// Auto-Logout-Timeout in Minuten. Persistiert im Secure Storage,
/// damit beim naechsten App-Start derselbe Wert gilt.
class AutoLogoutMinutesNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final storage = ref.watch(secureStorageProvider);
    return storage.readAutoLogoutMinutes();
  }

  Future<void> set(int minutes) async {
    final clamped = minutes.clamp(
      AppConstants.minAutoLogoutMinutes,
      AppConstants.maxAutoLogoutMinutes,
    );
    final storage = ref.read(secureStorageProvider);
    await storage.writeAutoLogoutMinutes(clamped);
    state = AsyncValue<int>.data(clamped);
  }
}

final autoLogoutMinutesProvider =
    AsyncNotifierProvider<AutoLogoutMinutesNotifier, int>(
  AutoLogoutMinutesNotifier.new,
);
