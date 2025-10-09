import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/plan_provider.dart';
import '../models/pillar.dart';
import '../models/strategic_objective.dart';

class AddObjectiveDialog extends StatefulWidget {
  final Pillar pillar;
  final StrategicObjective? initialObjective;
  final bool isEditing;

  const AddObjectiveDialog({
    super.key,
    required this.pillar,
    this.initialObjective,
    this.isEditing = false,
  });

  @override
  _AddObjectiveDialogState createState() => _AddObjectiveDialogState();
}

class _AddObjectiveDialogState extends State<AddObjectiveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _is90DayPriority = false;
  String _timeHorizon = 'Short-term';
  String _status = 'Not Started';
  DateTime? _startDate;
  DateTime? _targetDate;
  bool _isLoading = false;

  // Use the inject utility for provider
  late PlanProvider _planProvider;

  final List<String> _timeHorizons = [
    'Short-term',
    'Medium-term',
    'Long-term',
  ];

  final List<String> _statuses = [
    'Not Started',
    'In Progress',
    'Completed',
    'Deferred',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the provider using inject
    _planProvider = inject<PlanProvider>();

    if (widget.initialObjective != null) {
      _titleController.text = widget.initialObjective!.title;
      _descriptionController.text = widget.initialObjective!.description ?? '';
      _is90DayPriority = widget.initialObjective!.is90DayPriority;
      _timeHorizon = widget.initialObjective!.timeHorizon;
      _status = widget.initialObjective!.status;
      _startDate = widget.initialObjective!.startDate;
      _targetDate = widget.initialObjective!.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing
          ? 'Edit Strategic Objective'
          : 'Add Strategic Objective',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppStyle.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Information about the pillar this objective belongs to
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPillarColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getPillarColor()),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPillarIcon(),
                      color: _getPillarColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pillar: ${widget.pillar.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPillarColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Objective Title',
                  hintText: 'What do you want to achieve?',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the objective';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Provide more details about this objective',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('90-Day Priority'),
                subtitle: const Text('Mark as a priority for this quarter'),
                value: _is90DayPriority,
                activeColor: AppStyle.accentColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _is90DayPriority = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _timeHorizon,
                decoration: AppStyle.inputDecoration(
                  labelText: 'Time Horizon',
                ),
                items: _timeHorizons.map((horizon) {
                  return DropdownMenuItem<String>(
                    value: horizon,
                    child: Text(horizon),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _timeHorizon = value;
                    });
                  }
                },
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
                'Start Date (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select Start Date',
                      ),
                      Row(
                        children: [
                          if (_startDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
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
                'Target Date (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTargetDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _targetDate != null
                            ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                            : 'Select Target Date',
                      ),
                      Row(
                        children: [
                          if (_targetDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _targetDate = null;
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

  Color _getPillarColor() {
    if (widget.pillar.color == null) {
      return AppStyle.primary;
    }

    switch (widget.pillar.color!.toLowerCase()) {
      case 'purple':
        return AppStyle.peopleColor;
      case 'blue':
        return AppStyle.systemsColor;
      case 'green':
        return AppStyle.financeColor;
      case 'orange':
        return AppStyle.customersColor;
      case 'red':
        return AppStyle.socialColor;
      default:
        return AppStyle.primary;
    }
  }

  IconData _getPillarIcon() {
    if (widget.pillar.icon == null) {
      return Icons.star;
    }

    switch (widget.pillar.icon!.toLowerCase()) {
      case 'people':
        return Icons.people;
      case 'process':
        return Icons.settings;
      case 'finance':
        return Icons.attach_money;
      case 'customers':
        return Icons.person;
      case 'social':
        return Icons.public;
      default:
        return Icons.star;
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'pillar_id': widget.pillar.id,
        'title': _titleController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'is_90_day_priority': _is90DayPriority,
        'time_horizon': _timeHorizon,
        'status': _status,
        'start_date': _startDate?.toIso8601String().split('T')[0],
        'target_date': _targetDate?.toIso8601String().split('T')[0],
      };

      bool success;
      if (widget.isEditing && widget.initialObjective != null) {
        success = await _planProvider.updateStrategicObjective(
            widget.initialObjective!.uuid, data);
      } else {
        success = await _planProvider.createStrategicObjective(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Objective updated successfully'
                : 'Objective created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }
}

