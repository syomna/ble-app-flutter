import 'package:ble_flutter/core/theme/app_theme.dart';
import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:ble_flutter/data/services/ble.dart';
import 'package:ble_flutter/presentation/provider/ble.dart';
import 'package:ble_flutter/presentation/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return MultiProvider(
      providers: [
        Provider<BleService>(
          create: (_) => BleService(),
        ),
        ChangeNotifierProvider<BleNotifier>(
          create: (context) => BleNotifier(context.read<BleService>()),
        ),
      ],
      child: MaterialApp(
        title: 'BLE-APP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.defaultTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
