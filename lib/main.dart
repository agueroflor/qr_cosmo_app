import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qr_cosmo_app/firebase_options.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/cubits/auth/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  await configureDependencies();
  runApp(_wrapWithDevicePreview(const MyApp()));
}

Future<void> _initFirebase() async {
  if (Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Widget _wrapWithDevicePreview(Widget app) {
  return DevicePreview(
    enabled: kDebugMode && !Platform.isIOS,
    builder: (context) => app,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
      ],
      child: MaterialApp(
        title: 'QR Cosmo App',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES')],
        locale: const Locale('es', 'ES'),
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
