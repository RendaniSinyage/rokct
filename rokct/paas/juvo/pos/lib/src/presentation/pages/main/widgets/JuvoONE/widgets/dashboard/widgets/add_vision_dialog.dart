import 'package:flutter/material.dart';
import '../../../../../../../../core/di/injection.dart';
import '../../../../../../../theme/theme.dart';
import '../models/vision.dart';
import '../providers/plan_provider.dart';

class AddVisionDialog extends StatefulWidget {
  final Vision? initialVision;
  final bool isEditing;

  const AddVisionDialog({
    super.key,
    this.initialVision,
    this.isEditing = false,
  });

  @override
  _AddVisionDialogState createState() => _AddVisionDialogState();
}

class _AddVisionDialogState extends State<AddVisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _statementController = TextEditingController();
  DateTime _effectiveDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Use the inject utility for provider
  late PlanProvider _planProvider;

  @override
  void initState() {
    super.initState();

    // Initialize the provider using inject
    _planProvider = inject<PlanProvider>();

    if (widget.initialVision != null) {
      _statementController.text = widget.initialVision!.statement;
      _effectiveDate = widget.initialVision!.effectiveDate;
      _endDate = widget.initialVision!.endDate;
      _isActive = widget.initialVision!.isActive;
    }
  }

  @override
  void dispose() {
    _statementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Vision' : 'Add Vision',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppStyle.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyle.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppStyle.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppStyle.red),
                  ),
                ),
              TextFormField(
                controller: _statementController,
                style: TextStyle(color: AppStyle.black),
                decoration: InputDecoration(
                  labelText: 'Vision Statement',
                  hintText: 'Enter your company vision statement',
                  labelStyle: TextStyle(color: AppStyle.black),
                  hintStyle: TextStyle(color: AppStyle.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vision statement';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Effective Date',
                  style: const TextStyle(
                      color: AppStyle.black)
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectEffectiveDate,
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
                        '${_effectiveDate.day}/${_effectiveDate.month}/${_effectiveDate.year}',
                      style: const TextStyle(color: AppStyle.black)
                      ),
                      const Icon(Icons.calendar_today,
                           color: AppStyle.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'End Date (Optional)',
                  style: const TextStyle( color: AppStyle.black)
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectEndDate,
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
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select End Date',
                      style: const TextStyle(
                       color: AppStyle.black)),
                      Row(
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today,
                              color: AppStyle.black),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppStyle.black)),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: const TextStyle(
                  color: AppStyle.black)),
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

  Future<void> _selectEffectiveDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _effectiveDate) {
      setState(() {
        _effectiveDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Get the current user ID (in a real app, you would get this from auth)
      final userData = await _planProvider.getCurrentUser();
      final userId = userData?.id ?? '1'; // Default to '1' if not found

      final data = {
        'shop_id': widget.initialVision?.shopId,
        'statement': _statementController.text,
        'effective_date': _effectiveDate.toIso8601String().split('T')[0],
        'end_date': _endDate?.toIso8601String().split('T')[0],
        'is_active': _isActive,
        'created_by': userId, // Add the user ID who created this vision
      };

      try {
        bool success;
        if (widget.isEditing && widget.initialVision != null) {
          success = await _planProvider.updateVision(
              widget.initialVision!.uuid, data);
        } else {
          success = await _planProvider.createVision(data);
        }

        if (success) {
          // If success, close the dialog and show success message
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEditing
                    ? 'Vision updated successfully'
                    : 'Vision created successfully'),
                backgroundColor: AppStyle.green,
              ),
            );
          }
        } else {
          // If not success, show error message from provider
          setState(() {
            _isLoading = false;
            _errorMessage = _planProvider.error ??
                'Failed to save vision. Please try again.';
          });
        }
      } catch (e) {
        // Handle unexpected errors
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    }
  }
}

