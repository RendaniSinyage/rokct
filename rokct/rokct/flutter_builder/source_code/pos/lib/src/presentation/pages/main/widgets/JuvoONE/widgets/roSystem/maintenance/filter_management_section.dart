import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../theme/theme.dart';
import '../../../../income/widgets/custom_date_picker.dart';
import '../models/data/ro_system_model.dart';

class FilterManagementSection extends StatefulWidget {
  final List<Filter> initialFilters;
  final Function(List<Filter>) onFiltersChanged;

  const FilterManagementSection({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterManagementSection> createState() => _FilterManagementSectionState();
}

class _FilterManagementSectionState extends State<FilterManagementSection> {
  late Map<FilterLocation, List<Filter>> _filtersByLocation;
  final Map<String, bool> _showDatePickers = {};

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  @override
  void didUpdateWidget(FilterManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize filters if the initialFilters list changes
    if (widget.initialFilters != oldWidget.initialFilters) {
      _initializeFilters();
    }
  }

  void _initializeFilters() {
    // Create a new map with empty lists for each location
    _filtersByLocation = {
      FilterLocation.pre: [],
      FilterLocation.ro: [],
      FilterLocation.post: [],
    };

    // Group existing filters by location
    for (var filter in widget.initialFilters) {
      _filtersByLocation[filter.location]?.add(Filter(
        id: filter.id,
        type: filter.type,
        location: filter.location,
        installationDate: filter.installationDate,
      ));
    }

    // Reset date picker visibility
    _showDatePickers.clear();
  }

  void _addFilter(FilterLocation location) {
    final newFilter = Filter(
      id: '${location.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}',
      type: FilterType.sediment, // Default type
      location: location,
      installationDate: DateTime.now(),
    );

    setState(() {
      _filtersByLocation[location] ??= [];
      _filtersByLocation[location]!.add(newFilter);
      _notifyFilterChange();
    });
  }

  void _removeFilter(FilterLocation location, String filterId) {
    setState(() {
      _filtersByLocation[location]?.removeWhere((f) => f.id == filterId);
      _showDatePickers.remove(filterId);
      _notifyFilterChange();
    });
  }

  void _updateFilterType(FilterLocation location, String filterId, FilterType newType) {
    setState(() {
      final filterIndex = _filtersByLocation[location]?.indexWhere((f) => f.id == filterId) ?? -1;
      if (filterIndex != -1) {
        final filter = _filtersByLocation[location]![filterIndex];
        _filtersByLocation[location]![filterIndex] = Filter(
          id: filter.id,
          type: newType,
          location: location,
          installationDate: filter.installationDate,
        );
      }
      _notifyFilterChange();
    });
  }

  void _updateFilterDate(FilterLocation location, String filterId, DateTime? newDate) {
    if (newDate == null) return;

    setState(() {
      final filterIndex = _filtersByLocation[location]?.indexWhere((f) => f.id == filterId) ?? -1;
      if (filterIndex != -1) {
        final filter = _filtersByLocation[location]![filterIndex];
        _filtersByLocation[location]![filterIndex] = filter.copyWith(
          installationDate: newDate,
        );
      }
      _showDatePickers[filterId] = false;
      _notifyFilterChange();
    });
  }

  void _notifyFilterChange() {
    final allFilters = <Filter>[];
    _filtersByLocation.forEach((location, filters) {
      allFilters.addAll(filters);
    });
    widget.onFiltersChanged(allFilters);
  }

  String _getLocationTitle(FilterLocation location) {
    switch (location) {
      case FilterLocation.pre:
        return 'Pre Filters';
      case FilterLocation.ro:
        return 'RO Filters';
      case FilterLocation.post:
        return 'Post Filters';
    }
  }

  Widget _buildFilterSection(FilterLocation location) {
    final filters = _filtersByLocation[location] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppStyle.black.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLocationTitle(location),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addFilter(location),
                  icon: const Icon(FlutterRemix.add_line, size: 20),
                  label: const Text('Add Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.enableJuvoONE ? AppStyle.blueBonus : AppStyle.primary,
                    foregroundColor: AppStyle.white,
                  ),
                ),
              ],
            ),
          ),
          if (filters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No filters added yet',
                style: GoogleFonts.inter(
                  color: AppStyle.black.withOpacity(0.5),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<FilterType>(
                          value: filter.type,
                          style: const TextStyle(
                            color: AppStyle.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Filter Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: FilterType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                AppConstants.filterTypes[type.toString().split('.').last] ?? '',
                                style: GoogleFonts.inter(),
                              ),
                            );
                          }).toList(),
                          onChanged: (newType) {
                            if (newType != null) {
                              _updateFilterType(location, filter.id, newType);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showDatePickers.forEach((key, value) {
                                    _showDatePickers[key] = false;
                                  });
                                  _showDatePickers[filter.id] = true;
                                });
                              },
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
                                      '${filter.installationDate.day}/${filter.installationDate.month}/${filter.installationDate.year}',
                                      style: GoogleFonts.inter(color: AppStyle.black),
                                    ),
                                    const Icon(Icons.calendar_today, size: 20, color: AppStyle.black,),
                                  ],
                                ),
                              ),
                            ),
                            if (_showDatePickers[filter.id] ?? false)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppStyle.black.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppStyle.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CustomDatePicker(
                                  range: [filter.installationDate],
                                  onChange: (dates) {
                                    if (dates.isNotEmpty && dates.first != null) {
                                      _updateFilterDate(location, filter.id, dates.first);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeFilter(location, filter.id),
                        icon: const Icon(FlutterRemix.delete_bin_line),
                        color: AppStyle.red,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Filter Management',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
        ),
        ...FilterLocation.values.map(_buildFilterSection),
      ],
    );
  }
}
