import 'dart:async';
import 'package:ble_flutter/data/services/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleNotifier extends ChangeNotifier {
  final BleService _bleService;

  BleNotifier(this._bleService);

  ScanResult? _selectedScanResult;
  ScanResult? get selectedScanResult => _selectedScanResult;

  final BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get bluetoothState => _bluetoothState;

  List<int>? _receivedData;
  List<int>? get receivedData => _receivedData;

  DeviceIdentifier? _loadingIdentifier;
  DeviceIdentifier? get loadingIdentifier => _loadingIdentifier;

  Guid? _loadingService;
  Guid? get loadingService => _loadingService;

  bool _loadingDiscoverServices = false;
  bool get loadingDiscoverServices => _loadingDiscoverServices;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<DeviceIdentifier, List<BluetoothService>> get discoveredServices =>
      _bleService.discoveredServices;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLoadingIdenifier(DeviceIdentifier? id) {
    _loadingIdentifier = id;
    notifyListeners();
  }

  void setLoadingDiscoverServices(bool isLoading) {
    _loadingDiscoverServices = isLoading;
    notifyListeners();
  }

  void setSelectedScanResult(ScanResult? scanResult) {
    _selectedScanResult = scanResult;
    notifyListeners();
  }

  void setLoadingService(Guid? service) {
    _loadingService = service;
    notifyListeners();
  }

  Stream<BluetoothAdapterState> get bluetoothStateStream =>
      _bleService.bluetoothStateStream;

  Future<void> checkPermissions() async {
    await _bleService.checkPermissions();
  }

  Future<void> initBle() async {
    try {
      await _bleService.initBle();
    } catch (e) {
      setError("Initialization failed: $e");
    }
  }

  Stream<BluetoothConnectionState> monitorDeviceConnection(
      BluetoothDevice device) {
    return _bleService.monitorDeviceConnection(device);
  }

  Future<void> scan() async {
    try {
      // setIsLoading(true);
      await _bleService.scan();
    } catch (e) {
      setError("Scan failed: $e");
    } finally {
      // setIsLoading(false);
    }
  }

  Future<void> connectToDevice(ScanResult scanResult) async {
    try {
      setLoadingIdenifier(scanResult.device.remoteId);
      await _bleService.connectToDevice(scanResult.device);
      setSelectedScanResult(scanResult);
      clearError();
    } catch (e) {
      setError('Error connecting to device');
    } finally {
      setLoadingIdenifier(null);
    }
    notifyListeners();
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      setLoadingIdenifier(device.remoteId);
      await _bleService.disconnectFromDevice(device);
      clearError();
    } catch (e) {
      setError('Error disconnecting from device');
    } finally {
      setLoadingIdenifier(null);
    }
    notifyListeners();
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      setLoadingDiscoverServices(true);
      await _bleService.discoverServices(device);
      clearError();
      setLoadingDiscoverServices(false);
    } catch (e) {
      setLoadingDiscoverServices(false);
      setError(
          "We couldn't retrieve services for this device. This may happen with certain devices. Please consult the device manual or try again.");
    }
  }

  Future<void> sendJsonData(BluetoothDevice device, Guid serviceUuid,
      Guid characteristicUuid, Map<String, dynamic> jsonData) async {
    try {
      setLoadingService(serviceUuid);
      await _bleService.sendJsonData(
          device, serviceUuid, characteristicUuid, jsonData);
      clearError();
      setLoadingService(null);
    } catch (e) {
      setError('Failed to send data: $e');
    } finally {
      setLoadingService(null);
    }
  }

  Future<void> receiveData(
      BluetoothDevice device, Guid serviceUuid, Guid characteristicUuid) async {
    try {
      await _bleService.receiveData(device, serviceUuid, characteristicUuid,
          (data) {
        _receivedData = data;
        notifyListeners();
      });
    } catch (e) {
      setError('Error receiving data');
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
