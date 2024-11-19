import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:ble_flutter/presentation/screens/home.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: SizeConfig.getHeight(100),
          ),
          SizedBox(
            height: SizeConfig.getHeight(20),
          ),
          Text(
            'BLE-APP',
            style: TextStyle(
                fontSize: SizeConfig.getFontSize(20),
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: 4),
          )
        ],
      ),
    ));
  }
}
