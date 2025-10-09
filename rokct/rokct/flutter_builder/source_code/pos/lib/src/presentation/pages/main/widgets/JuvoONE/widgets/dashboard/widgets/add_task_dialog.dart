import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/task_provider.dart';
import '../providers/plan_provider.dart';
import '../models/todo_task.dart';
import '../models/strategic_objective.dart';
import '../models/kpi.dart';

class AddTaskDialog extends StatefulWidget {
  final String? preSelectedRoadmapVersion;
  final TodoTask? initialTask;
  final bool isEditing;
  final String? preSelectedObjectiveId;
  final String? preSelectedKpiId;
  final String? preSelectedAppId;

  const AddTaskDialog({
    this.preSelectedRoadmapVersion,
    super.key,
    this.initialTask,
    this.isEditing = false,
    this.preSelectedObjectiveId,
    this.preSelectedKpiId,
    this.preSelectedAppId,
  });

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _status = 'Todo';
  String _priority = 'Medium';
  String? _objectiveId;
  String? _kpiId;
  String? _appId;
  String? _roadmapVersion;
  String? _assignedTo;
  bool _isLoading = false;

  // Use the inject utility for providers
  late TaskProvider _taskProvider;
  late PlanProvider _planProvider;

  final List<String> _statuses = ['Todo', 'In Progress', 'Done', 'Blocked'];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();

    // Initialize the providers using inject
    _taskProvider = inject<TaskProvider>();
    _planProvider = inject<PlanProvider>();

    if (widget.initialTask != null) {
      _titleController.text = widget.initialTask!.title;
      _descriptionController.text = widget.initialTask!.description ?? '';
      _dueDate = widget.initialTask!.dueDate;
      _status = widget.initialTask!.status;
      _priority = widget.initialTask!.priority;
      _objectiveId = widget.initialTask!.objectiveId;
      _kpiId = widget.initialTask!.kpiId;
      _appId = widget.initialTask!.appId;
      _roadmapVersion = widget.initialTask!.roadmapVersion;
      _assignedTo = widget.initialTask!.assignedTo;
    } else {
      // Use preselected values if provided
      _objectiveId = widget.preSelectedObjectiveId;
      _kpiId = widget.preSelectedKpiId;
      _appId = widget.preSelectedAppId;
      _roadmapVersion = widget.preSelectedRoadmapVersion;
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
      title: Text(widget.isEditing ? 'Edit Task' : 'Add Task',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppStyle.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'What needs to be done?',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the task';
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
                  hintText: 'Provide more details about this task',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Link this task to...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLinkButton(
                      icon: Icons.assignment,
                      label: 'Objective',
                      isLinked: _objectiveId != null,
                      onTap: _selectStrategicObjective,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLinkButton(
                      icon: Icons.speed,
                      label: 'KPI',
                      isLinked: _kpiId != null,
                      onTap: _selectKpi,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLinkButton(
                      icon: Icons.phone_android,
                      label: 'App',
                      isLinked: _appId != null,
                      onTap: _selectApp,
                    ),
                  ),
                ],
              ),
              if (_kpiId != null) ...[
                const SizedBox(height: 8),
                _buildLinkedItemInfo('KPI'),
              ],
              if (_objectiveId != null && _kpiId == null) ...[
                const SizedBox(height: 8),
                _buildLinkedItemInfo('Objective'),
              ],
              if (_appId != null) ...[
                const SizedBox(height: 8),
                _buildLinkedItemInfo('App'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _roadmapVersion,
                  style: TextStyle(color: AppStyle.black),
                  decoration: InputDecoration(
                    labelText: 'Roadmap Version',
                    hintText: 'e.g., 2.4.1',
                    labelStyle: TextStyle(color: AppStyle.black),
                    hintStyle: TextStyle(color: AppStyle.black),
                  ),
                  onChanged: (value) {
                    _roadmapVersion = value;
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Due Date (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
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
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Select Due Date',
                      ),
                      Row(
                        children: [
                          if (_dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _dueDate = null;
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: AppStyle.inputDecoration(
                        labelText: 'Priority',
                      ),
                      items: _priorities.map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // This would normally be a user selector but for simplicity we'll use a text field
              TextFormField(
                initialValue: _assignedTo,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Assign To (User ID)',
                  hintText: 'User ID',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                  prefixIcon: const Icon(Icons.person),
                ),
                onChanged: (value) {
                  _assignedTo = value;
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

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required bool isLinked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isLinked ? AppStyle.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLinked ? AppStyle.primary : AppStyle.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isLinked ? AppStyle.primary : AppStyle.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isLinked ? AppStyle.primary : AppStyle.grey.shade600,
                fontWeight: isLinked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isLinked)
              Icon(
                Icons.check_circle,
                color: AppStyle.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedItemInfo(String type) {
    // In a real app you would fetch the actual information from your state
    // This is simplified for the example
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppStyle.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppStyle.primary,
        ),
      ),
      child: Row(
        children: [
          Icon(
            type == 'KPI'
                ? Icons.speed
                : type == 'Objective'
                    ? Icons.assignment
                    : Icons.phone_android,
            color: AppStyle.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Linked to $type: ${_getLinkedItemName(type)}',
              style: TextStyle(
                fontSize: 12,
                color: AppStyle.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 16,
              color: AppStyle.primary,
            ),
            onPressed: () {
              setState(() {
                if (type == 'KPI') {
                  _kpiId = null;
                } else if (type == 'Objective') {
                  _objectiveId = null;
                } else if (type == 'App') {
                  _appId = null;
                  _roadmapVersion = null;
                }
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _getLinkedItemName(String type) {
    if (_planProvider.vision == null) {
      return 'Selected Item';
    }

    // Get actual names from the vision data
    if (type == 'KPI' && _kpiId != null) {
      for (final pillar in _planProvider.vision!.pillars) {
        for (final objective in pillar.strategicObjectives) {
          for (final kpi in objective.kpis) {
            if (kpi.id == _kpiId) {
              return kpi.metric;
            }
          }
        }
      }
    } else if (type == 'Objective' && _objectiveId != null) {
      for (final pillar in _planProvider.vision!.pillars) {
        for (final objective in pillar.strategicObjectives) {
          if (objective.id == _objectiveId) {
            return objective.title;
          }
        }
      }
    } else if (type == 'App') {
      return 'App ID: $_appId';
    }

    return 'Selected Item';
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
        _objectiveId = selectedObjective.id;
        // If this objective has KPIs, clear any previously selected KPI
        // as it might not belong to this objective
        if (_kpiId != null) {
          bool kpiBelongsToObjective =
              selectedObjective.kpis.any((kpi) => kpi.id == _kpiId);
          if (!kpiBelongsToObjective) {
            _kpiId = null;
          }
        }
      });
    }
  }

  Future<void> _selectKpi() async {
    if (_planProvider.vision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vision data available')),
      );
      return;
    }

    List<Kpi> availableKpis = [];

    // If an objective is already selected, only show KPIs for that objective
    if (_objectiveId != null) {
      for (var pillar in _planProvider.vision!.pillars) {
        for (var objective in pillar.strategicObjectives) {
          if (objective.id == _objectiveId) {
            availableKpis = objective.kpis;
            break;
          }
        }
        if (availableKpis.isNotEmpty) break;
      }
    } else {
      // Otherwise, show all KPIs
      for (var pillar in _planProvider.vision!.pillars) {
        for (var objective in pillar.strategicObjectives) {
          availableKpis.addAll(objective.kpis);
        }
      }
    }

    if (availableKpis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No KPIs available')),
      );
      return;
    }

    // Show dialog to select KPI
    final selectedKpi = await showDialog<Kpi>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select KPI'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: availableKpis.length,
              itemBuilder: (context, index) {
                final kpi = availableKpis[index];
                return ListTile(
                  title: Text(kpi.metric),
                  subtitle: Text(
                      'Due: ${kpi.dueDate.day}/${kpi.dueDate.month}/${kpi.dueDate.year}'),
                  onTap: () {
                    Navigator.of(context).pop(kpi);
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

    if (selectedKpi != null) {
      setState(() {
        _kpiId = selectedKpi.id;
        // If no objective was selected or if the selected objective doesn't match the KPI,
        // update the objective to match the KPI
        if (_objectiveId != selectedKpi.objectiveId) {
          _objectiveId = selectedKpi.objectiveId;
        }
      });
    }
  }

  Future<void> _selectApp() async {
    // In a real app, you would fetch available apps from your state or API
    // This is simplified for the example - showing a mock app selection
    final selectedApp = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select App'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Water Refill Station'),
                  subtitle: const Text('South River'),
                  onTap: () {
                    Navigator.of(context)
                        .pop({'id': '1', 'name': 'Water Refill Station'});
                  },
                ),
                ListTile(
                  title: const Text('Delivery Platform'),
                  subtitle: const Text('Juvo'),
                  onTap: () {
                    Navigator.of(context)
                        .pop({'id': '2', 'name': 'Delivery Platform'});
                  },
                ),
              ],
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

    if (selectedApp != null) {
      setState(() {
        _appId = selectedApp['id'];
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        'kpi_id': _kpiId,
        'objective_id': _objectiveId,
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'assigned_to': _assignedTo,
        'status': _status,
        'priority': _priority,
        'app_id': _appId,
        'roadmap_version': _roadmapVersion,
      };

      bool success;
      if (widget.isEditing && widget.initialTask != null) {
        success =
            await _taskProvider.updateTask(widget.initialTask!.uuid, data);
      } else {
        success = await _taskProvider.createTask(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Task updated successfully'
                : 'Task created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }
}

