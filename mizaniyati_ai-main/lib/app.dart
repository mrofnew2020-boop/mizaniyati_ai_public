import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/recorder/recorder_home_screen.dart';
import 'screens/role_selection/role_selection_screen.dart';
import 'screens/splash/splash_screen.dart';

class MizaniyatiApp extends StatelessWidget {
  const MizaniyatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.ready) return const SplashScreen();
    if (!appState.roleSelected) return const RoleSelectionScreen();
    
    // توجيه المستخدم حسب دوره
    return appState.isManager ? const HomeScreen() : const RecorderHomeScreen();
  }
}
