import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/presentation/pending_approval_screen.dart';
import 'features/auth/presentation/phone_login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/presentation/rider_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
      ],
      child: const DeliveryOSRiderApp(),
    ),
  );
}

class DeliveryOSRiderApp extends ConsumerWidget {
  const DeliveryOSRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(riderAuthProvider);

    return MaterialApp(
      title: 'DeliveryOS Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.card,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('bn', ''),
        Locale('ar', ''),
      ],
      home: _resolveInitialScreen(authState),
    );
  }

  Widget _resolveInitialScreen(RiderAuthState authState) {
    if (authState.isAuthenticated) {
      return const RiderDashboardScreen();
    }
    if (authState.isPendingApproval) {
      return const PendingApprovalScreen();
    }
    return const PhoneLoginScreen();
  }
}
