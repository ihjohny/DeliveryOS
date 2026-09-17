import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('Initialize localStorageProvider in ProviderScope');
});

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(localStorageProvider);
    return Locale(storage.getLanguage());
  }

  Future<void> setLanguage(String langCode) async {
    if (['en', 'ar', 'bn'].contains(langCode)) {
      state = Locale(langCode);
      await ref.read(localStorageProvider).setLanguage(langCode);
    }
  }

  bool get isRtl => state.languageCode == 'ar';
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Locale>(LanguageNotifier.new);
