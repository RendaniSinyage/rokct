/*import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/constants/constants.dart';
import '../config/api.dart';
import '../utils/local_storage.dart';
import '../utils/offline_utils.dart';
import '../data/dummy_data.dart';

class SettingsPopup extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const SettingsPopup({super.key, required this.isOpen, required this.onClose});

  @override
  _SettingsPopupState createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup> {
  Map<String, dynamic>? shopData;
  bool loading = true;
  String? error;
  String? expandedSection;
  Map<String, bool> expandedItems = {};
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      fetchShopData();
    }
    if (AppConstants.enableOfflineMode) {
      _setupConnectivityListeners();
    }
  }

  void _setupConnectivityListeners() {
    // Implement connectivity listeners here
  }

  Future<void> fetchShopData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final userData = await LocalStorage.getUserData();
      final shopId = userData?['user']?['shop']?['id'];

      if (shopId == null) {
        throw Exception('No shop ID available');
      }

      if (isOnline) {
        final response = await http.get(
          Uri.parse('${ApiConstants.resourceApi}?shopId=$shopId'),
          headers: {'Authorization': 'Bearer ${await LocalStorage.getToken()}'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            shopData = data;
          });
          await LocalStorage.setShopData(data);
        } else if (response.statusCode == 404) {
          final dummyShop = dummyData.firstWhere(
                (shop) => shop['shopId'] == shopId,
            orElse: () => dummyData[0],
          );
          setState(() {
            shopData = {...dummyShop, 'isDefault': true};
          });
        } else {
          throw Exception('Failed to fetch shop data');
        }
      } else {
        final storedShopData = await LocalStorage.getShopData();
        if (storedShopData != null) {
          setState(() {
            shopData = storedShopData;
          });
        } else {
          final dummyShop = dummyData.firstWhere(
                (shop) => shop['shopId'] == shopId,
            orElse: () => dummyData[0],
          );
          setState(() {
            shopData = {...dummyShop, 'isDefault': true};
          });
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void handleInputChange(String section, int? index, String field, dynamic value, {String? nestedField}) {
    setState(() {
      if (section == 'tanks') {
        if (nestedField != null) {
          shopData!['tanks'][index!][nestedField][field] = value;
        } else {
          shopData!['tanks'][index!][field] = value;
        }
      } else if (section == 'roSystem') {
        if (nestedField != null) {
          shopData!['roSystem'][nestedField][index!][field] = value;
        } else {
          shopData!['roSystem'][field] = value;
        }
      } else if (section == 'maintenance') {
        if (nestedField != null) {
          shopData!['maintenance'][nestedField][field] = value;
        } else {
          shopData!['maintenance'][field] = value;
        }
      }
    });
  }

  void handleAddItem(String section) {
    setState(() {
      if (section == 'tanks') {
        final newIndex = shopData!['tanks'].length;
        shopData!['tanks'].add({
          'number': shopData!['tanks'].length + 1,
          'type': 'raw',
          'capacity': 1000,
          'level': 0,
          'waterQuality': {'ph': 7.0, 'tds': 100, 'temperature': 20, 'hardness': 20},
          'pumpStatus': {'isOn': false, 'flowRate': 0}
        });
        expandedItems['tanks-$newIndex'] = true;
      } else if (section == 'roSystem.membranes') {
        shopData!['roSystem']['membranes'].add({'lastReplaced': DateTime.now().toIso8601String()});
      } else if (section == 'roSystem.megaCharVessels') {
        shopData!['roSystem']['megaCharVessels'].add({'lastReplaced': DateTime.now().toIso8601String()});
      }
    });
  }

  void handleRemoveItem(String section, int index) {
    setState(() {
      if (section == 'tanks') {
        shopData!['tanks'].removeAt(index);
      } else if (section == 'roSystem.membranes') {
        shopData!['roSystem']['membranes'].removeAt(index);
      } else if (section == 'roSystem.megaCharVessels') {
        shopData!['roSystem']['megaCharVessels'].removeAt(index);
      }
    });
  }

  Future<void> handleSetupData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      if (isOnline) {
        final response = await http.post(
          Uri.parse(ApiConstants.resourceApi),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await LocalStorage.getToken()}',
          },
          body: json.encode(shopData),
        );

        if (response.statusCode == 200) {
          final updatedData = json.decode(response.body);
          setState(() {
            shopData = updatedData;
          });
          await LocalStorage.setShopData(updatedData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop data has been set up successfully!')),
          );
        } else {
          throw Exception('Failed to setup shop data');
        }
      } else {
        saveOfflineRequest(ApiConstants.resourceApi, 'POST', shopData!);
        await LocalStorage.setShopData(shopData!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop data has been saved locally and will be synced when online.')),
        );
      }
      widget.onClose();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen || shopData == null) return const SizedBox.shrink();

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.yellow[100],
                child: Text(
                  'Offline Mode: Changes will be saved locally and synchronized when you\'re back online.',
                  style: TextStyle(color: Colors.yellow[800]),
                ),
              ),
            // Add your sections here (Tanks, RO System, Maintenance)
            // Use ExpansionPanels for collapsible sections
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: handleSetupData,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}*/
