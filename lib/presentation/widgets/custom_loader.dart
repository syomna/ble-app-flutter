import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SizeConfig.getHeight(20),
      width: SizeConfig.getHeight(20),
      child: const CircularProgressIndicator(),
    );
  }
}