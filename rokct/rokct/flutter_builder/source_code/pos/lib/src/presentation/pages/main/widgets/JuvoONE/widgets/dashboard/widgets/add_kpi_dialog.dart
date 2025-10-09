import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../providers/plan_provider.dart';
import '../models/strategic_objective.dart';
import '../models/kpi.dart';

class AddKpiDialog extends StatefulWidget {
  final StrategicObjective objective;
  final Kpi? initialKpi;
  final bool isEditing;

  const AddKpiDialog({
    super.key,
    required this.objective,
    this.initialKpi,
    this.isEditing = false,
  });

  @override
  _AddKpiDialogState createState() => _AddKpiDialogState();
}

class _AddKpiDialogState extends State<AddKpiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _metricController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _unitController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'Not Started';
  bool _isLoading = false;

  // Use the inject utility for provider
  late PlanProvider _planProvider;

  final List<String> _statuses = [
    'Not Started',
    'In Progress',
    'Completed',
    'Overdue',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the provider using inject
    _planProvider = inject<PlanProvider>();

    if (widget.initialKpi != null) {
      _metricController.text = widget.initialKpi!.metric;
      _targetValueController.text = widget.initialKpi!.targetValue ?? '';
      _currentValueController.text = widget.initialKpi!.currentValue ?? '';
      _unitController.text = widget.initialKpi!.unit ?? '';
      _dueDate = widget.initialKpi!.dueDate;
      _status = widget.initialKpi!.status;
    }
  }

  @override
  void dispose() {
    _metricController.dispose();
    _targetValueController.dispose();
    _currentValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit KPI' : 'Add KPI',
      style: const TextStyle(
        fontWeight: FontWeight.bold, color: AppStyle.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Information about the objective this KPI belongs to
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppStyle.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppStyle.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategic Objective:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppStyle.black,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.objective.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                          color: AppStyle.black
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _metricController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Metric',
                  hintText: 'What will you measure?',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a metric for the KPI';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetValueController,
                      style: TextStyle(color: AppStyle.black),
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        hintText: 'e.g., 100',
                        labelStyle: TextStyle(color: AppStyle.black),
                        hintStyle: TextStyle(color: AppStyle.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      style: TextStyle(color: AppStyle.black),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g., %',
                        labelStyle: TextStyle(color: AppStyle.black),
                        hintStyle: TextStyle(color: AppStyle.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentValueController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Current Value (Optional)',
                  hintText: 'Current progress',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Due Date',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.black),
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
                        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.black),
                      ),
                      const Icon(Icons.calendar_today, color: AppStyle.black),
                    ],
                  ),
                ),
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
                    child: Text(status,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.black)),

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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.black),),
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
      backgroundColor: AppStyle.white
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
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
        'objective_id': widget.objective.id,
        'metric': _metricController.text,
        'target_value': _targetValueController.text.isNotEmpty
            ? _targetValueController.text
            : null,
        'current_value': _currentValueController.text.isNotEmpty
            ? _currentValueController.text
            : null,
        'unit': _unitController.text.isNotEmpty ? _unitController.text : null,
        'due_date': _dueDate.toIso8601String().split('T')[0],
        'status': _status,
      };

      bool success;
      if (widget.isEditing && widget.initialKpi != null) {
        success = await _planProvider.updateKpi(widget.initialKpi!.uuid, data);
      } else {
        success = await _planProvider.createKpi(data);
      }

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'KPI updated successfully'
                : 'KPI created successfully'),
            backgroundColor: AppStyle.green,
          ),
        );
      }
    }
  }
}

