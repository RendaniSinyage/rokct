import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/roadmap_provider.dart';
import '../models/roadmap_version.dart';

class AddRoadmapVersionDialog extends StatefulWidget {
  final String appId;
  final RoadmapVersion? initialVersion;
  final bool isEditing;

  const AddRoadmapVersionDialog({
    super.key,
    required this.appId,
    this.initialVersion,
    this.isEditing = false,
  });

  @override
  _AddRoadmapVersionDialogState createState() => _AddRoadmapVersionDialogState();
}

class _AddRoadmapVersionDialogState extends State<AddRoadmapVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'Planning';
  DateTime? _releaseDate;
  final List<String> _features = [];
  final _featureController = TextEditingController();
  bool _isLoading = false;

  // Use the inject utility for provider
  late RoadmapProvider _roadmapProvider;

  final List<String> _statuses = [
    'Planning',
    'Development',
    'Testing',
    'Released',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the provider using inject
    _roadmapProvider = inject<RoadmapProvider>();

    if (widget.initialVersion != null) {
      _versionController.text = widget.initialVersion!.versionNumber;
      _descriptionController.text = widget.initialVersion!.description ?? '';
      _status = widget.initialVersion!.status;
      _releaseDate = widget.initialVersion!.releaseDate;
      _features.addAll(widget.initialVersion!.features);
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _descriptionController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Roadmap Version' : 'Add Roadmap Version'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _versionController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Version Number',
                  hintText: 'e.g., 1.0.0',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a version number';
                  }
                  // Validate version format (e.g., 1.0.0)
                  final RegExp versionRegex = RegExp(r'^\d+(\.\d+)*$');
                  if (!versionRegex.hasMatch(value)) {
                    return 'Please enter a valid version number (e.g., 1.0.0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is new in this version?',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: AppStyle.inputDecoration(
                  labelText: 'Status',
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Target Release Date (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectReleaseDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _releaseDate != null
                            ? '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}'
                            : 'Select Release Date',
                      ),
                      Row(
                        children: [
                          if (_releaseDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _releaseDate = null;
                                });
                              },
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Key Features',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _featureController,
                      style: TextStyle(color: AppStyle.black),
                      decoration: InputDecoration(
                        labelText: 'Feature',
                        hintText: 'Add a feature',
                        labelStyle: TextStyle(color: AppStyle.black),
                        hintStyle: TextStyle(color: AppStyle.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addFeature,
                    color: AppStyle.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFeatureList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.primary,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(widget.isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    if (_features.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No features added yet',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: AppStyle.grey,
          ),
        ),
      );
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: AppStyle.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        itemCount: _features.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(_features[index]),
            leading: const Icon(Icons.check, size: 16),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: () {
                setState(() {
                  _features.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  void _addFeature() {
    if (_featureController.text.isNotEmpty) {
      setState(() {
        _features.add(_featureController.text);
        _featureController.clear();
      });
    }
  }

  Future<void> _selectReleaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _releaseDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'app_id': widget.appId,
        'version_number': _versionController.text,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'status': _status,
        'features': _features,
        'release_date': _releaseDate?.toIso8601String().split('T')[0],
      };

      bool success;
      if (widget.isEditing && widget.initialVersion != null) {
        success = await _roadmapProvider.updateRoadmapVersion(widget.initialVersion!.uuid, data);
      } else {
        success = await _roadmapProvider.createRoadmapVersion(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Version updated successfully' : 'Version created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }}
