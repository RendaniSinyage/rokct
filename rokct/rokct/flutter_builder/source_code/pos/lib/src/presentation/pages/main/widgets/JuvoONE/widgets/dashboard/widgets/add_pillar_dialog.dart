import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/plan_provider.dart';
import '../models/pillar.dart';

class AddPillarDialog extends StatefulWidget {
  final String visionId;
  final Pillar? initialPillar;
  final bool isEditing;

  const AddPillarDialog({
    super.key,
    required this.visionId,
    this.initialPillar,
    this.isEditing = false,
  });

  @override
  _AddPillarDialogState createState() => _AddPillarDialogState();
}

class _AddPillarDialogState extends State<AddPillarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  int _displayOrder = 0;
  bool _isLoading = false;

  // Use the inject utility for provider
  late PlanProvider _planProvider;

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'People', 'icon': Icons.people},
    {'name': 'Process', 'icon': Icons.settings},
    {'name': 'Finance', 'icon': Icons.attach_money},
    {'name': 'Customers', 'icon': Icons.person},
    {'name': 'Social', 'icon': Icons.public},
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Purple', 'color': AppStyle.peopleColor},
    {'name': 'Blue', 'color': AppStyle.systemsColor},
    {'name': 'Green', 'color': AppStyle.financeColor},
    {'name': 'Orange', 'color': AppStyle.customersColor},
    {'name': 'Red', 'color': AppStyle.socialColor},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the provider using inject
    _planProvider = inject<PlanProvider>();

    if (widget.initialPillar != null) {
      _nameController.text = widget.initialPillar!.name;
      _descriptionController.text = widget.initialPillar!.description ?? '';
      _iconController.text = widget.initialPillar!.icon ?? '';
      _colorController.text = widget.initialPillar!.color ?? '';
      _displayOrder = widget.initialPillar!.displayOrder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Pillar' : 'Add Pillar'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Pillar Name',
                  hintText: 'e.g., People, Processes, Finance, etc.',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for the pillar';
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
                  hintText: 'Briefly describe this pillar',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Icon',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _iconOptions.map((option) {
                  final isSelected = _iconController.text == option['name'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _iconController.text = option['name'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppStyle.primary.withOpacity(0.1)
                            : AppStyle.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppStyle.primary
                              : AppStyle.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            option['icon'] as IconData,
                            color: isSelected
                                ? AppStyle.primary
                                : AppStyle.grey.shade600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppStyle.primary
                                  : AppStyle.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _colorOptions.map((option) {
                  final isSelected = _colorController.text == option['name'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _colorController.text = option['name'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (option['color'] as Color).withOpacity(0.1)
                            : AppStyle.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? option['color'] as Color
                              : AppStyle.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: option['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? option['color'] as Color
                                  : AppStyle.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _displayOrder.toString(),
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Display Order',
                  hintText: 'Numeric value for sorting',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _displayOrder = int.tryParse(value) ?? 0;
                },
              ),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'vision_id': widget.visionId,
        'name': _nameController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'icon': _iconController.text.isNotEmpty ? _iconController.text : null,
        'color':
            _colorController.text.isNotEmpty ? _colorController.text : null,
        'display_order': _displayOrder,
      };

      bool success;
      if (widget.isEditing && widget.initialPillar != null) {
        success =
            await _planProvider.updatePillar(widget.initialPillar!.uuid, data);
      } else {
        success = await _planProvider.createPillar(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Pillar updated successfully'
                : 'Pillar created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }
}

