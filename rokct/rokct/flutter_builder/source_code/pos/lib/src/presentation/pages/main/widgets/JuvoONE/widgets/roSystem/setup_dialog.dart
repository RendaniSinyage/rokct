import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/theme.dart';
import '../../../income/widgets/custom_date_picker.dart';
import 'maintenance/filter_management_section.dart';
import 'models/data/ro_system_model.dart';
import 'repository/ro_system_api.dart';

class SystemSetupDialog extends StatefulWidget {
  const SystemSetupDialog({super.key});

  @override
  State<SystemSetupDialog> createState() => _SystemSetupDialogState();
}

class _SystemSetupDialogState extends State<SystemSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _error;
  bool _inFilterSetupMode = false;

  // Vessel counts
  int _megaCharCount = 1;
  int _softenerCount = 1;
  int _membraneCount = 1;

  // Filters
  List<Filter> _filters = [];

  // Installation dates
  DateTime? _vesselInstallationDate;
  DateTime? _membraneInstallationDate;

  // Date picker visibility flags
  bool _showVesselDatePicker = false;
  bool _showMembraneDatePicker = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSystem();
  }

  Future<void> _loadExistingSystem() async {
    try {
      final system = await MaintenanceApiService.getROSystem();
      if (system != null && mounted) {
        setState(() {
          _megaCharCount = system.vessels.where((v) => v.type == 'megaChar').length;
          _softenerCount = system.vessels.where((v) => v.type == 'softener').length;
          _membraneCount = system.membraneCount;
          _filters = system.filters;
          _vesselInstallationDate = system.vessels.isNotEmpty ? system.vessels.first.installationDate : null;
          _membraneInstallationDate = system.membraneInstallationDate;
          _isLoading = false;
          _inFilterSetupMode = false; // Show both sections for existing system
        });
      } else {
        setState(() {
          _isLoading = false;
          _inFilterSetupMode = false; // Show both sections for new system initially
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading system: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleFiltersChanged(List<Filter> newFilters) {
    setState(() {
      _filters = newFilters;
      // For new system, hide vessel/membrane section only after dates are set and adding first filter
      if (_vesselInstallationDate != null &&
          _membraneInstallationDate != null &&
          newFilters.isNotEmpty) {
        _inFilterSetupMode = true;
      }
    });
  }


  Widget _buildNumberPicker(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, color: AppStyle.black),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              color: AppStyle.black,
            ),
            Text(
              value.toString(),
              style: GoogleFonts.inter(fontSize: 16, color: AppStyle.black),
            ),
            IconButton(
              onPressed: value < 10 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
              color: AppStyle.black,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required bool showPicker,
    required Function(bool) onPickerVisibilityChanged,
    required Function(List<DateTime?>) onDateChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, color: AppStyle.black),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => onPickerVisibilityChanged(!showPicker),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppStyle.black.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      : 'Select Date',
                  style: GoogleFonts.inter(fontSize: 16,color: AppStyle.black),
                ),
                const Icon(Icons.calendar_today, size: 20, color: AppStyle.black),
              ],
            ),
          ),
        ),
        if (showPicker)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppStyle.black.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              color: AppStyle.white,
              boxShadow: [
                BoxShadow(
                  color: AppStyle.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomDatePicker(
              range: selectedDate != null ? [selectedDate] : [],
              onChange: onDateChanged,
            ),
          ),
      ],
    );
  }



  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() &&
        _vesselInstallationDate != null &&
        _membraneInstallationDate != null) {
      setState(() => _isLoading = true);

      try {
        // Debug print initial state
        if (kDebugMode) {
          print('Initial Setup Details:');
        }
        if (kDebugMode) {
          print('Mega Char Count: $_megaCharCount');
        }
        if (kDebugMode) {
          print('Softener Count: $_softenerCount');
        }
        if (kDebugMode) {
          print('Membrane Count: $_membraneCount');
        }
        if (kDebugMode) {
          print('Vessel Installation Date: $_vesselInstallationDate');
        }
        if (kDebugMode) {
          print('Membrane Installation Date: $_membraneInstallationDate');
        }

        // Print filters details
        if (kDebugMode) {
          print('Filters:');
        }
        for (var filter in _filters) {
          if (kDebugMode) {
            print('- Filter ID: ${filter.id}, Location: ${filter.location}');
          }
        }

        // First create the RO System
        final vessels = <Vessel>[];

        // Add Mega Char vessels
        for (var i = 0; i < _megaCharCount; i++) {
          final vesselId = 'megaChar_$i';
          vessels.add(Vessel(
            id: vesselId,
            type: 'megaChar',
            installationDate: _vesselInstallationDate!,
          ));
          if (kDebugMode) {
            print('Added Mega Char Vessel: $vesselId');
          }
        }

        // Add Softener vessels
        for (var i = 0; i < _softenerCount; i++) {
          final vesselId = 'softener_$i';
          vessels.add(Vessel(
            id: vesselId,
            type: 'softener',
            installationDate: _vesselInstallationDate!,
          ));
          if (kDebugMode) {
            print('Added Softener Vessel: $vesselId');
          }
        }

        // Create system
        final system = ROSystem(
          filters: _filters,
          vessels: vessels,
          membraneCount: _membraneCount,
          membraneInstallationDate: _membraneInstallationDate!,
        );

        // Validate system before saving
        if (kDebugMode) {
          print('System to be saved:');
        }
        if (kDebugMode) {
          print('Vessels count: ${system.vessels.length}');
        }
        if (kDebugMode) {
          print('Filters count: ${system.filters.length}');
        }
        if (kDebugMode) {
          print('Membrane Count: ${system.membraneCount}');
        }

        // Save system first
        if (kDebugMode) {
          print('Attempting to save RO System...');
        }
        final savedSystem = await MaintenanceApiService.saveROSystem(system);

        if (kDebugMode) {
          print('Saved System Details:');
        }
        if (kDebugMode) {
          print('System ID: ${savedSystem.id}');
        }
        if (kDebugMode) {
          print('Saved Vessels Count: ${savedSystem.vessels.length}');
        }
        if (kDebugMode) {
          print('Saved Filters Count: ${savedSystem.filters.length}');
        }

        // Now create maintenance records for vessels
        for (final vessel in savedSystem.vessels) {
          // Initial record
          await MaintenanceApiService.updateMaintenanceDate(
            type: 'vessel',
            referenceId: vessel.id,
            date: DateTime.now(),
          );

          // Next maintenance date
          await MaintenanceApiService.updateMaintenanceDate(
            type: 'vessel',
            referenceId: vessel.id,
            date: DateTime.now().add(Duration(days: AppConstants.maintenanceCheckDays)),
          );
        }

        // Create maintenance records for filters
        for (final filter in savedSystem.filters) {
          int replacementDays = switch (filter.location) {
            FilterLocation.pre => AppConstants.preFilterReplaceDays,
            FilterLocation.ro => AppConstants.roFilterReplaceDays,
            FilterLocation.post => AppConstants.postFilterReplaceDays,
          };

          await MaintenanceApiService.updateMaintenanceDate(
            type: 'filter',
            referenceId: filter.id,
            date: DateTime.now().add(Duration(days: replacementDays)),
          );
        }

        // Create membrane maintenance record
        await MaintenanceApiService.updateMaintenanceDate(
          type: 'membrane',
          referenceId: 'membrane_${savedSystem.id}',
          date: DateTime.now().add(Duration(days: AppConstants.roMembraneReplaceDays)),
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('Full Error Details:');
        }
        if (kDebugMode) {
          print('Error: $e');
        }
        if (kDebugMode) {
          print('Stacktrace: $stackTrace');
        }

        if (mounted) {
          setState(() {
            _error = 'Error saving system setup: $e';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: AppStyle.red,
              duration: Duration(seconds: 10), // Longer duration to read error
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        backgroundColor: AppStyle.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }


    return Dialog(
      backgroundColor: AppStyle.white,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 800,
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
                      'System Setup',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppStyle.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppStyle.black,
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

                // Only show vessel and membrane setup if not in filter setup mode
                if (!_inFilterSetupMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberPicker(
                          'Mega Char Vessels',
                          _megaCharCount,
                              (value) => setState(() => _megaCharCount = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberPicker(
                          'Softener Vessels',
                          _softenerCount,
                              (value) => setState(() => _softenerCount = value),
                        ),
                      ),
                      _buildNumberPicker(
                        'RO Membranes',
                        _membraneCount,
                            (value) => setState(() => _membraneCount = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Vessel Installation Date',
                          selectedDate: _vesselInstallationDate,
                          showPicker: _showVesselDatePicker,
                          onPickerVisibilityChanged: (show) => setState(() {
                            _showVesselDatePicker = show;
                            _showMembraneDatePicker = false;
                          }),
                          onDateChanged: (dates) {
                            if (dates.isNotEmpty && dates.first != null) {
                              setState(() {
                                _vesselInstallationDate = dates.first;
                                _showVesselDatePicker = false;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Membrane Installation Date',
                          selectedDate: _membraneInstallationDate,
                          showPicker: _showMembraneDatePicker,
                          onPickerVisibilityChanged: (show) => setState(() {
                            _showMembraneDatePicker = show;
                            _showVesselDatePicker = false;
                          }),
                          onDateChanged: (dates) {
                            if (dates.isNotEmpty && dates.first != null) {
                              setState(() {
                                _membraneInstallationDate = dates.first;
                                _showMembraneDatePicker = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Show filter management section when dates are set
                 ...[
                  FilterManagementSection(
                    initialFilters: _filters,
                    onFiltersChanged: _handleFiltersChanged,
                  ),
                  const SizedBox(height: 16),

                  // RO filter warning
                  if (!_filters.any((filter) => filter.location == FilterLocation.ro))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please add at least one RO filter to continue',
                        style: GoogleFonts.inter(
                          color: AppStyle.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.enableJuvoONE
                        ? AppStyle.blueBonus
                        : AppStyle.brandGreen,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _isLoading ||
                      _vesselInstallationDate == null ||
                      _membraneInstallationDate == null ||
                      !_filters.any((filter) => filter.location == FilterLocation.ro)
                      ? null
                      : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppStyle.white),
                    ),
                  )
                      : Text(
                    'Save Configuration',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppStyle.white,
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
