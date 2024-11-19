import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:ble_flutter/presentation/provider/ble.dart';
import 'package:ble_flutter/presentation/widgets/display_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final bleNotifier = Provider.of<BleNotifier>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await bleNotifier.checkPermissions();
      await bleNotifier.initBle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleNotifier = Provider.of<BleNotifier>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bleNotifier.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bleNotifier.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        bleNotifier.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE-APP'),
      ),
      body: StreamBuilder<BluetoothAdapterState>(
        stream: bleNotifier.bluetoothStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data != BluetoothAdapterState.on) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                      radius: SizeConfig.getWidth(40),
                      child: Icon(Icons.bluetooth_disabled,
                          size: SizeConfig.getWidth(40))),
                  SizedBox(height: SizeConfig.getHeight(10)),
                  const Text(
                    'Bluetooth is disabled.\nPlease enable Bluetooth to scan for devices.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No devices found. Start scanning.'));
              }

              final scanResults = snapshot.data!;
              return ListView.separated(
                itemCount: scanResults.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  return DisplayDevice(result: result);
                },
              );
            },
          );
        },
      ),
      floatingActionButton:
          bleNotifier.bluetoothState == BluetoothAdapterState.on
              ? FloatingActionButton(
                  onPressed: bleNotifier.scan,
                  child: const Icon(Icons.search),
                )
              : null,
    );
  }
}
