import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  late StreamSubscription<BluetoothAdapterState> adapterStateSubscription;
  StreamSubscription? scanSubscription;

  final Map<DeviceIdentifier, List<BluetoothService>> _discoveredServices = {};
  Map<DeviceIdentifier, List<BluetoothService>> get discoveredServices =>
      _discoveredServices;

  Stream<BluetoothAdapterState> get bluetoothStateStream =>
      FlutterBluePlus.adapterState;

  Duration timeout = const Duration(seconds: 15);

  Future<void> checkPermissions() async {
    if (await Permission.bluetooth.isDenied ||
        await Permission.location.isDenied) {
      await [Permission.bluetooth, Permission.location].request();
    } else {
      log('Permissions already granted');
    }
  }

  Future<void> initBle() async {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    log('Initializing BLE');

    if (await FlutterBluePlus.isSupported == false) {
      throw Exception("Bluetooth not supported by this device");
    }

    adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      log('BluetoothAdapterState: $state');
      if (state == BluetoothAdapterState.on) {
        scan();
      }
    });

    // Turn on Bluetooth for Android
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // Start scanning if Bluetooth is already ON
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      await scan();
    }
  }

  Stream<BluetoothConnectionState> monitorDeviceConnection(
      BluetoothDevice device) {
    return device.connectionState;
  }

  Future<void> scan() async {
    try {
      scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          for (var result in results) {
            log('Device found: ${result.device.remoteId}');
          }
        },
        onError: (e) => log('Scan error: $e'),
      );

      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
    } catch (e) {
      log("Scan failed: $e");
      rethrow;
    } finally {
      scanSubscription?.cancel();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      log('Connecting to device: ${device.remoteId}');
      await device.connect(autoConnect: false, timeout: timeout);
      log('Connected to device: ${device.remoteId}');
    } catch (e) {
      log('Error connecting to device: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      log('Disconnected from device: ${device.remoteId}');
    } catch (e) {
      log('Error disconnecting from device: $e');
      rethrow;
    }
  }

  Future<List<BluetoothService>> discoverServices(
      BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      _discoveredServices[device.remoteId] = services;
      log('Discovered ${services.length} services for device ${device.remoteId}');
      return services;
    } catch (e) {
      log('Error discovering services: $e');
      rethrow;
    }
  }

  Future<void> sendJsonData(
    BluetoothDevice device,
    Guid serviceUuid,
    Guid characteristicUuid,
    Map<String, dynamic> jsonData,
  ) async {
    try {
      // Discover services on the device
      final services = await discoverServices(device);

      // Find the specific service
      final targetService = services.firstWhere(
        (service) => service.uuid == serviceUuid,
        orElse: () => throw Exception(
            'Service not found. Ensure the correct service UUID is provided.'),
      );

      // Find the specific characteristic
      final targetCharacteristic = targetService.characteristics.firstWhere(
        (characteristic) => characteristic.uuid == characteristicUuid,
        orElse: () => throw Exception(
            'Characteristic not found. Check the provided characteristic UUID.'),
      );

      // Check if the characteristic supports writing
      if (!targetCharacteristic.properties.write) {
        throw PlatformException(
          code: 'writeCharacteristic',
          message:
              'The WRITE property is not supported by this BLE characteristic.',
        );
      }

      final jsonString = json.encode(jsonData);

      await targetCharacteristic.write(
        utf8.encode(jsonString),
        withoutResponse: false,
      );
      log('Sent JSON data: $jsonData');
    } on PlatformException catch (e) {
      log('PlatformException: ${e.message}');
      throw Exception(
        e.code == 'writeCharacteristic'
            ? 'This device does not support writing to the selected characteristic. Please check the device documentation.'
            : 'Platform error occurred: ${e.message}',
      );
    } on Exception catch (e) {
      log('Error sending JSON data: $e');
      throw Exception('Failed to send data: $e');
    }
  }

  Future<void> receiveData(BluetoothDevice device, Guid serviceUuid,
      Guid characteristicUuid, Function(List<int>) onDataReceived) async {
    try {
      final services = await discoverServices(device);

      final targetService = services.firstWhere(
        (service) => service.uuid == serviceUuid,
        orElse: () => throw Exception('Service not found'),
      );

      final targetCharacteristic = targetService.characteristics.firstWhere(
        (characteristic) => characteristic.uuid == characteristicUuid,
        orElse: () => throw Exception('Characteristic not found'),
      );

      await targetCharacteristic.setNotifyValue(true);
      targetCharacteristic.onValueReceived.listen(onDataReceived);
    } catch (e) {
      log('Error receiving data: $e');
    }
  }

  void dispose() {
    adapterStateSubscription.cancel();
    scanSubscription?.cancel();
    log("BleService disposed and streams canceled.");
  }
}
