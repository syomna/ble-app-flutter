import 'dart:convert';

import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:ble_flutter/data/models/send_data.dart';
import 'package:ble_flutter/presentation/provider/ble.dart';
import 'package:ble_flutter/presentation/widgets/custom_field.dart';
import 'package:ble_flutter/presentation/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

class BleCard extends StatefulWidget {
  const BleCard({super.key});

  @override
  State<BleCard> createState() => _BleCardState();
}

class _BleCardState extends State<BleCard> {
  final Map<Guid, TextEditingController> commandControllers = {};
  final Map<Guid, TextEditingController> valueControllers = {};
  final Map<Guid, GlobalKey<FormState>> formKeys = {};

  @override
  Widget build(BuildContext context) {
    final bleNotifier = Provider.of<BleNotifier>(context);
    final ScanResult? result = bleNotifier.selectedScanResult;

    if (result == null) {
      return const Center(child: Text('No device selected'));
    }

    return Padding(
      padding: EdgeInsets.all(SizeConfig.getWidth(8)),
      child: StreamBuilder<BluetoothConnectionState>(
        stream: bleNotifier.monitorDeviceConnection(result.device),
        builder: (context, snapshot) {
          final isConnected =
              snapshot.data == BluetoothConnectionState.connected;
          return SingleChildScrollView(
            child: _body(context, result, isConnected, bleNotifier),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ScanResult result, bool isConnected,
      BleNotifier bleNotifier) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: SizeConfig.getWidth(50),
            child: Text(
              result.device.platformName.isNotEmpty
                  ? result.device.platformName[0]
                  : '?',
              style: TextStyle(fontSize: SizeConfig.getFontSize(30)),
            ),
          ),
          SizedBox(height: SizeConfig.getHeight(10)),
          Text(
            result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            style: TextStyle(
                fontSize: SizeConfig.getFontSize(18),
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: SizeConfig.getHeight(20)),
          isConnected
              ? bleNotifier.loadingDiscoverServices
                  ? const CustomLoader()
                  : ElevatedButton(
                      onPressed: () async {
                        await bleNotifier.discoverServices(result.device);
                      },
                      child: const Text('Discover Services'),
                    )
              : const Text(
                  'Device is not connected.\nPlease connect to access services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
          if (isConnected) _displayServices(context, result),
          const SizedBox(height: 16),
          if (isConnected)
            Consumer<BleNotifier>(
              builder: (context, notifier, child) {
                final data = notifier.receivedData;
                return data != null
                    ? Text(
                        'Received: ${utf8.decode(data)}',
                        style: TextStyle(fontSize: SizeConfig.getFontSize(16)),
                      )
                    : const Text('No data received yet.');
              },
            ),
          _button(isConnected, bleNotifier, result)
        ],
      ),
    );
  }

  Widget _button(bool isConnected, BleNotifier bleNotifier, ScanResult result) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.getHeight(20)),
      child: bleNotifier.loadingIdentifier == result.device.remoteId
          ? const CustomLoader()
          : ElevatedButton(
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
            ),
    );
  }

  Widget _displayServices(BuildContext context, ScanResult result) {
    return Consumer<BleNotifier>(
      builder: (context, bleNotifier, _) {
        if (!bleNotifier.discoveredServices
            .containsKey(result.device.remoteId)) {
          return const SizedBox.shrink();
        }

        final services =
            bleNotifier.discoveredServices[result.device.remoteId]!;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              commandControllers[service.uuid] ??= TextEditingController();
              valueControllers[service.uuid] ??= TextEditingController();
              formKeys[service.uuid] ??= GlobalKey<FormState>();

              return Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text('Service: ${service.uuid}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(SizeConfig.getWidth(8)),
                      child: Form(
                        key: formKeys[service.uuid],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomField(
                                    label: 'Command',
                                    commandController:
                                        commandControllers[service.uuid]!),
                                SizedBox(width: SizeConfig.getWidth(8)),
                                CustomField(
                                  label: 'Value',
                                  commandController:
                                      valueControllers[service.uuid]!,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                            SizedBox(height: SizeConfig.getHeight(12)),
                            bleNotifier.loadingService == service.uuid
                                ? const CustomLoader()
                                : ElevatedButton(
                                    onPressed: () {
                                      _onSendData(service, bleNotifier, result);
                                    },
                                    child: const Text('Send Data'),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  _onSendData(BluetoothService service, BleNotifier bleNotifier,
      ScanResult result) async {
    if (formKeys[service.uuid]!.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      final command = commandControllers[service.uuid]!.text.trim();
      final value =
          int.tryParse(valueControllers[service.uuid]!.text.trim()) ?? 0;

      bleNotifier.sendJsonData(
        result.device,
        service.uuid,
        service.characteristics.first.uuid,
        SendDataModel(command: command, value: value).toJson(),
      );

      // commandControllers[service.uuid]!
      //     .clear();
      // valueControllers[service.uuid]!.clear();
    }
  }

  @override
  dispose() {
    for (final controller in commandControllers.values) {
      controller.dispose();
    }
    for (final controller in valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
