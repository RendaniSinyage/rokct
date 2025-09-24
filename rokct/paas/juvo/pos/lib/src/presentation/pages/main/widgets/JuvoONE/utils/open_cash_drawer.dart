import 'package:flutter/foundation.dart' show Uint8List, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show File, FileMode, Platform, Process, Socket;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum CashDrawerType {
  direct,
  network,
  bluetooth,
}

class CashDrawerConfig {
  final String id;
  final String name;
  final CashDrawerType type;
  final Map<String, dynamic> settings;

  CashDrawerConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.settings,
  });

  factory CashDrawerConfig.fromJson(Map<String, dynamic> json) {
    return CashDrawerConfig(
      id: json['id'],
      name: json['name'],
      type: CashDrawerType.values.firstWhere((e) => e.toString() == 'CashDrawerType.${json['type']}'),
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'settings': settings,
    };
  }
}

class CashDrawerManager {
  static const String _configKey = 'cash_drawer_configs';

  static Future<List<CashDrawerConfig>> getConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsJson = prefs.getString(_configKey);
    if (configsJson != null) {
      final List<dynamic> configsList = json.decode(configsJson);
      return configsList.map((config) => CashDrawerConfig.fromJson(config)).toList();
    }
    return [];
  }

  static Future<void> saveConfiguration(CashDrawerConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CashDrawerConfig> configs = await getConfigurations();
    final existingIndex = configs.indexWhere((c) => c.id == config.id);
    if (existingIndex != -1) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    await prefs.setString(_configKey, json.encode(configs.map((c) => c.toJson()).toList()));
  }

  static Future<void> deleteConfiguration(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CashDrawerConfig> configs = await getConfigurations();
    configs.removeWhere((c) => c.id == id);
    await prefs.setString(_configKey, json.encode(configs.map((c) => c.toJson()).toList()));
  }

  static Future<void> openCashDrawer(CashDrawerConfig config) async {
    try {
      switch (config.type) {
        case CashDrawerType.direct:
          await _openCashDrawerDirect(config.settings);
          break;
        case CashDrawerType.network:
          await _openCashDrawerNetwork(config.settings);
          break;
        case CashDrawerType.bluetooth:
          await _openCashDrawerBluetooth(config.settings);
      }
      if (kDebugMode) {
        print('Cash drawer ${config.name} opened successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening cash drawer ${config.name}: $e');
      }
      rethrow;
    }
  }

  static Future<void> _openCashDrawerDirect(Map<String, dynamic> settings) async {
    if (kIsWeb) {
      throw UnsupportedError('Direct cash drawer opening is not supported on web');
    }

    final openCommand = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // ESC p 0 25 250
    final List<int> bytes = Uint8List.fromList(openCommand);

    if (Platform.isWindows) {
      final port = settings['port'] ?? r'\\.\COM1';
      final file = await File(port).open(mode: FileMode.write);
      await file.writeFrom(bytes);
      await file.close();
    } else if (Platform.isMacOS || Platform.isLinux) {
      final device = settings['device'] ?? '/dev/usb/lp0';
      final file = await File(device).open(mode: FileMode.write);
      await file.writeFrom(bytes);
      await file.close();
    } else {
      throw UnsupportedError('Direct cash drawer opening is not supported on this platform');
    }
  }

  static Future<void> _openCashDrawerNetwork(Map<String, dynamic> settings) async {
    final address = settings['address'];
    final port = settings['port'];

    final socket = await Socket.connect(address, port);
    final openCommand = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // ESC p 0 25 250
    socket.add(openCommand);
    await socket.flush();
    await socket.close();
  }

  static Future<void> _openCashDrawerBluetooth(Map<String, dynamic> settings) async {
    final deviceName = settings['deviceName'];

    if (!await FlutterBluePlus.isAvailable) {
      throw Exception('Bluetooth is not available on this device');
    }

    await FlutterBluePlus.turnOn();

    bool deviceFound = false;
    BluetoothDevice? targetDevice;

    // Start scanning
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == deviceName) {
          targetDevice = r.device;
          deviceFound = true;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // Wait for the scan to complete
    await Future.delayed(const Duration(seconds: 5));

    if (!deviceFound || targetDevice == null) {
      throw Exception('Bluetooth device not found');
    }

    // Connect to the device
    await targetDevice!.connect();

    // Discover services
    List<BluetoothService> services = await targetDevice!.discoverServices();
    BluetoothCharacteristic? writeCharacteristic;

    // Find the write characteristic
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
          break;
        }
      }
      if (writeCharacteristic != null) break;
    }

    if (writeCharacteristic == null) {
      await targetDevice!.disconnect();
      throw Exception('Write characteristic not found');
    }

    // Send the open command
    final openCommand = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // ESC p 0 25 250
    await writeCharacteristic.write(openCommand, withoutResponse: true);

    // Disconnect from the device
    await targetDevice!.disconnect();
  }
}

class CashDrawerButton extends StatelessWidget {
  final String title;
  final CashDrawerConfig config;

  const CashDrawerButton({
    super.key,
    required this.title,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await CashDrawerManager.openCashDrawer(config);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${config.name} opened successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open ${config.name}: $e')),
          );
        }
      },
      child: Text(title),
    );
  }
}

class CashDrawerConfigScreen extends StatefulWidget {
  const CashDrawerConfigScreen({super.key});

  @override
  _CashDrawerConfigScreenState createState() => _CashDrawerConfigScreenState();
}

class _CashDrawerConfigScreenState extends State<CashDrawerConfigScreen> {
  List<CashDrawerConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  Future<void> _loadConfigurations() async {
    final configs = await CashDrawerManager.getConfigurations();
    setState(() {
      _configs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Drawer Configurations')),
      body: ListView.builder(
        itemCount: _configs.length,
        itemBuilder: (context, index) {
          final config = _configs[index];
          return ListTile(
            title: Text(config.name),
            subtitle: Text(config.type.toString().split('.').last),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await CashDrawerManager.deleteConfiguration(config.id);
                _loadConfigurations();
              },
            ),
            onTap: () {
              _editConfiguration(config);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _addConfiguration();
        },
      ),
    );
  }

  void _addConfiguration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CashDrawerConfigForm(
          onSave: (newConfig) async {
            await CashDrawerManager.saveConfiguration(newConfig);
            _loadConfigurations();
          },
        ),
      ),
    );
  }

  void _editConfiguration(CashDrawerConfig config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CashDrawerConfigForm(
          initialConfig: config,
          onSave: (updatedConfig) async {
            await CashDrawerManager.saveConfiguration(updatedConfig);
            _loadConfigurations();
          },
        ),
      ),
    );
  }
}

class CashDrawerConfigForm extends StatefulWidget {
  final CashDrawerConfig? initialConfig;
  final Function(CashDrawerConfig) onSave;

  const CashDrawerConfigForm({super.key, this.initialConfig, required this.onSave});

  @override
  _CashDrawerConfigFormState createState() => _CashDrawerConfigFormState();
}

class _CashDrawerConfigFormState extends State<CashDrawerConfigForm> {
  late TextEditingController _nameController;
  late CashDrawerType _selectedType;
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialConfig?.name ?? '');
    _selectedType = widget.initialConfig?.type ?? CashDrawerType.direct;
    _settings = widget.initialConfig?.settings ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialConfig == null ? 'Add Cash Drawer' : 'Edit Cash Drawer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Cash Drawer Name'),
            ),
            DropdownButtonFormField<CashDrawerType>(
              value: _selectedType,
              onChanged: (CashDrawerType? newValue) {
                setState(() {
                  _selectedType = newValue!;
                  _settings = {}; // Reset settings when type changes
                });
              },
              items: CashDrawerType.values.map((CashDrawerType type) {
                return DropdownMenuItem<CashDrawerType>(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Settings:', style: Theme.of(context).textTheme.titleMedium),
            ..._buildSettingsFields(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveConfiguration,
              child: const Text('Save Configuration'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSettingsFields() {
    switch (_selectedType) {
      case CashDrawerType.direct:
        return [
          TextField(
            decoration: const InputDecoration(labelText: 'Port (Windows) or Device (macOS/Linux)'),
            onChanged: (value) => _settings['port'] = value,
            controller: TextEditingController(text: _settings['port'] ?? ''),
          ),
        ];
      case CashDrawerType.network:
        return [
          TextField(
            decoration: const InputDecoration(labelText: 'IP Address'),
            onChanged: (value) => _settings['address'] = value,
            controller: TextEditingController(text: _settings['address'] ?? ''),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Port'),
            keyboardType: TextInputType.number,
            onChanged: (value) => _settings['port'] = int.tryParse(value) ?? 9100,
            controller: TextEditingController(text: _settings['port']?.toString() ?? '9100'),
          ),
        ];
      case CashDrawerType.bluetooth:
        return [
          TextField(
            decoration: const InputDecoration(labelText: 'Device Name'),
            onChanged: (value) => _settings['deviceName'] = value,
            controller: TextEditingController(text: _settings['deviceName'] ?? ''),
          ),
        ];
    }
  }

  void _saveConfiguration() {
    final newConfig = CashDrawerConfig(
      id: widget.initialConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _selectedType,
      settings: _settings,
    );
    widget.onSave(newConfig);
    Navigator.of(context).pop();
  }
}
