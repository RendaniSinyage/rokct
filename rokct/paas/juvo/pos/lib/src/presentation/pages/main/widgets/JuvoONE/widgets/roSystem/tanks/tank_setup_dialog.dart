import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../theme/theme.dart';
import '../models/data/tank_models.dart';
import '../repository/tanks_api.dart';

class TankSetupDialog extends StatefulWidget {
  final Tank? initialTank;
  final TankType defaultType;

  const TankSetupDialog({
    super.key,
    this.initialTank,
    required this.defaultType,
  });

  @override
  State<TankSetupDialog> createState() => _TankSetupDialogState();
}

class _TankSetupDialogState extends State<TankSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  late TextEditingController _numberController;
  late TextEditingController _capacityController;

  // Pump status controllers
  late TextEditingController _flowRateController;
  late bool _isPumpOn;

  // Water quality controllers
  late TextEditingController _phController;
  late TextEditingController _tdsController;
  late TextEditingController _temperatureController;
  late TextEditingController _hardnessController;

  late TankType _selectedType;
  late TankStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.initialTank?.number ?? '');
    _capacityController = TextEditingController(
      text: widget.initialTank?.capacity.toString() ?? '',
    );
    _selectedType = widget.initialTank?.type ?? widget.defaultType;
    _selectedStatus = widget.initialTank?.status ?? TankStatus.empty;

    // Set defaults based on tank type
    final bool isPurified = _selectedType == TankType.purified;

    // Initialize pump status with defaults
    _isPumpOn = widget.initialTank?.pumpStatus['isOn'] ?? false;
    _flowRateController = TextEditingController(
      text: (widget.initialTank?.pumpStatus['flowRate'] ??
          (isPurified ? 6.0 : 8.3)).toString(),
    );

    // Initialize water quality with defaults
    _phController = TextEditingController(
      text: (widget.initialTank?.waterQuality['ph'] ?? 7.0).toString(),
    );
    _tdsController = TextEditingController(
      text: (widget.initialTank?.waterQuality['tds'] ??
          (isPurified ? 16 : 150)).toString(),
    );
    _temperatureController = TextEditingController(
      text: (widget.initialTank?.waterQuality['temperature'] ??
          (isPurified ? 20.0 : 25.0)).toString(),
    );
    _hardnessController = TextEditingController(
      text: (widget.initialTank?.waterQuality['hardness'] ??
          (isPurified ? 0 : 90)).toString(),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _capacityController.dispose();
    _flowRateController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _temperatureController.dispose();
    _hardnessController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shopData = await LocalStorage.getUser();
      if (shopData == null || shopData.shop?.id == null) {
        throw Exception('Shop data not found');
      }

      final tank = Tank(
        id: widget.initialTank?.id,
        shopId: shopData.shop!.id,
        number: _numberController.text,
        type: _selectedType,
        capacity: double.parse(_capacityController.text),
        status: _selectedStatus,
        pumpStatus: {
          'isOn': _isPumpOn,
          'flowRate': double.parse(_flowRateController.text),
        },
        waterQuality: {
          'ph': double.parse(_phController.text),
          'tds': int.parse(_tdsController.text),
          'temperature': double.parse(_temperatureController.text),
          'hardness': int.parse(_hardnessController.text),
        },
        // Update lastFull to current time when tank becomes full again
        lastFull: _selectedStatus == TankStatus.full
            ? DateTime.now()
            : widget.initialTank?.lastFull,
      );

      if (widget.initialTank != null) {
        await TankApiService.updateTank(tank);
      } else {
        await TankApiService.createTank(tank);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppStyle.white,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 500, // Increased width to accommodate new fields
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialTank != null ? 'Edit Tank' : 'Add Tank',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color:  AppStyle.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color:  AppStyle.black,
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        color: AppStyle.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Tank number
                TextFormField(
                  controller: _numberController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tank Number',
                    hintText: 'Enter tank number',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tank number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tank type
                DropdownButtonFormField<TankType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tank Type',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  items: TankType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        final bool isPurified = value == TankType.purified;

                        // Update controllers with new default values
                        _flowRateController.text = isPurified ? '6.0' : '8.3';
                        _tdsController.text = isPurified ? '16' : '150';
                        _temperatureController.text = isPurified ? '20.0' : '25.0';
                        _hardnessController.text = isPurified ? '0' : '90';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Tank capacity
                TextFormField(
                  controller: _capacityController,
                  style: const TextStyle(
                    color: AppStyle.black, // This will make the input text white
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Capacity (L)',
                    hintText: 'Enter tank capacity in liters',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tank capacity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tank status
                DropdownButtonFormField<TankStatus>(
                  value: _selectedStatus,
                 // style: const TextStyle(
                 //   color: AppStyle.black,
                 // ),
                  decoration: const InputDecoration(
                    labelText: 'Tank Status',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  items: TankStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status
                            .toString()
                            .split('.')
                            .last
                            .replaceAll(RegExp(r'(?=[A-Z])'), ' '),
                        style: const TextStyle(fontSize: 14, color:  AppStyle.black),

                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Pump Status Section
                Text(
                  'Pump Status',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color:  AppStyle.black,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Pump On/Off'),
                  tileColor: AppStyle.black,
                  value: _isPumpOn,
                  onChanged: (bool value) {
                    setState(() {
                      _isPumpOn = value;
                    });
                  },
                ),
                TextFormField(
                  controller: _flowRateController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Flow Rate',
                    hintText: 'Enter flow rate',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter flow rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                // Water Quality Section
                const SizedBox(height: 16),
                Text(
                  'Water Quality',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color:  AppStyle.black,
                  ),
                ),
                TextFormField(
                  controller: _phController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'pH',
                    hintText: 'Enter pH level',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pH level';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tdsController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'TDS',
                    hintText: 'Enter Total Dissolved Solids',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter TDS';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _temperatureController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Temperature (°C)',
                    hintText: 'Enter water temperature',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter temperature';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hardnessController,
                  style: const TextStyle(
                    color: AppStyle.black,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Hardness',
                    hintText: 'Enter water hardness',
                    labelStyle: TextStyle(
                      color: AppStyle.black,
                    ),
                    hintStyle: TextStyle(
                      color: AppStyle.hint,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hardness';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                // Submit button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.enableJuvoONE
                          ? AppStyle.blueBonus
                          : AppStyle.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppStyle.white),
                            ),
                          )
                        : Text(
                            widget.initialTank != null
                                ? 'Update Tank'
                                : 'Add Tank',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppStyle.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

