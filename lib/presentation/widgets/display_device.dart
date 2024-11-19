import 'package:ble_flutter/presentation/provider/ble.dart';
import 'package:ble_flutter/presentation/screens/details.dart';
import 'package:ble_flutter/presentation/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

class DisplayDevice extends StatelessWidget {
  const DisplayDevice({super.key, required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final bleNotifier = Provider.of<BleNotifier>(context);

    return ListTile(
        onTap: () {
          final bleNotifier = Provider.of<BleNotifier>(context, listen: false);
          bleNotifier.setSelectedScanResult(result);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DetailsScreen(),
            ),
          );
        },
        title: Text(
          result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${result.device.remoteId}'),
        trailing: StreamBuilder<BluetoothConnectionState>(
          stream: bleNotifier.monitorDeviceConnection(result.device),
          builder: (context, snapshot) {
            final isConnected =
                snapshot.data == BluetoothConnectionState.connected;

            if (bleNotifier.loadingIdentifier == result.device.remoteId) {
              return const CustomLoader();
            }

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green : null,
              ),
              onPressed: isConnected
                  ? () async {
                      await bleNotifier.disconnectFromDevice(result.device);
                    }
                  : () async {
                      bleNotifier.setLoadingIdenifier(result.device.remoteId);
                      await bleNotifier.connectToDevice(result);
                      bleNotifier.setLoadingIdenifier(null);
                    },
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: TextStyle(color: isConnected ? Colors.white : null),
              ),
            );
          },
        ));
  }
}
