import 'package:ble_flutter/presentation/widgets/ble_card.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE-APP'),
      ),
      body: SizedBox(
          width: MediaQuery.of(context).size.width, child: const BleCard()),
    );
  }
}
