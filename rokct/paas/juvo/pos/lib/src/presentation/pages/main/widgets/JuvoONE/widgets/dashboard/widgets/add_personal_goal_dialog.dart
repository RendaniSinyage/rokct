import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/personal_mastery_provider.dart';
import '../providers/plan_provider.dart';
import '../models/personal_mastery_goal.dart';
import '../models/strategic_objective.dart';

class AddPersonalGoalDialog extends StatefulWidget {
  final PersonalMasteryGoal? initialGoal;
  final bool isEditing;
  final String? initialArea;

  const AddPersonalGoalDialog({
    super.key,
    this.initialGoal,
    this.isEditing = false,
    this.initialArea,
  });

  @override
  _AddPersonalGoalDialogState createState() => _AddPersonalGoalDialogState();
}

class _AddPersonalGoalDialogState extends State<AddPersonalGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _area = 'Financial';
  DateTime? _targetDate;
  String _status = 'Not Started';
  String? _relatedObjectiveId;
  bool _isLoading = false;

  // Use the inject utility for providers
  late PersonalMasteryProvider _personalMasteryProvider;
  late PlanProvider _planProvider;

  final List<String> _areas = [
    'Financial',
    'Vocation/Work',
    'Family',
    'Friends',
    'Spiritual',
    'Physical',
    'Learning & Skills',
  ];

  final List<String> _statuses = ['Not Started', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();

    // Initialize the providers using inject
    _personalMasteryProvider = inject<PersonalMasteryProvider>();
    _planProvider = inject<PlanProvider>();

    if (widget.initialGoal != null) {
      _titleController.text = widget.initialGoal!.title;
      _descriptionController.text = widget.initialGoal!.description ?? '';
      _area = widget.initialGoal!.area;
      _targetDate = widget.initialGoal!.targetDate;
      _status = widget.initialGoal!.status;
      _relatedObjectiveId = widget.initialGoal!.relatedObjectiveId;
    } else if (widget.initialArea != null) {
      _area = widget.initialArea!;
    }

    // Load the plan data to get strategic objectives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_planProvider.vision == null) {
        _planProvider.fetchPlanOnPage(null);
      }
    });
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
      title:
          Text(widget.isEditing ? 'Edit Personal Goal' : 'Add Personal Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _area,
                decoration: AppStyle.inputDecoration(
                  labelText: 'Life Area',
                ),
                items: _areas.map((area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(area),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _area = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'What do you want to achieve?',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for your goal';
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
                  hintText: 'Provide more details about this goal',
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
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Link to Business Objective (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectStrategicObjective(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppStyle.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: _relatedObjectiveId != null
                            ? AppStyle.primary.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _relatedObjectiveId != null
                              ? Expanded(
                                  child: Text(
                                    _getObjectiveTitle() ?? 'Linked Objective',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const Text('Select Business Objective'),
                          Row(
                            children: [
                              if (_relatedObjectiveId != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _relatedObjectiveId = null;
                                    });
                                  },
                                  iconSize: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.business),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  String? _getObjectiveTitle() {
    if (_relatedObjectiveId == null || _planProvider.vision == null) {
      return null;
    }

    for (final pillar in _planProvider.vision!.pillars) {
      for (final objective in pillar.strategicObjectives) {
        if (objective.id == _relatedObjectiveId) {
          return objective.title;
        }
      }
    }

    return null;
  }

  Future<void> _selectStrategicObjective() async {
    if (_planProvider.vision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vision data available')),
      );
      return;
    }

    // Flatten all objectives across pillars
    List<StrategicObjective> allObjectives = [];
    for (var pillar in _planProvider.vision!.pillars) {
      allObjectives.addAll(pillar.strategicObjectives);
    }

    if (allObjectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No strategic objectives available')),
      );
      return;
    }

    // Show dialog to select objective
    final selectedObjective = await showDialog<StrategicObjective>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Strategic Objective'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: allObjectives.length,
              itemBuilder: (context, index) {
                final objective = allObjectives[index];
                final pillar = _planProvider.vision!.pillars
                    .firstWhere((p) => p.id == objective.pillarId);
                return ListTile(
                  title: Text(objective.title),
                  subtitle: Text(pillar.name),
                  onTap: () {
                    Navigator.of(context).pop(objective);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedObjective != null) {
      setState(() {
        _relatedObjectiveId = selectedObjective.id;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // In a real app, you would get the current user ID from auth
      final userId = '1'; // Mock user ID

      final data = {
        'user_id': userId,
        'area': _area,
        'title': _titleController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'related_objective_id': _relatedObjectiveId,
        'target_date': _targetDate?.toIso8601String().split('T')[0],
        'status': _status,
      };

      bool success;
      if (widget.isEditing && widget.initialGoal != null) {
        success = await _personalMasteryProvider.updatePersonalMasteryGoal(
            widget.initialGoal!.uuid, data);
      } else {
        success =
            await _personalMasteryProvider.createPersonalMasteryGoal(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Goal updated successfully'
                : 'Goal created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }
}

