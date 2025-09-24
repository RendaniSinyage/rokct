import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../core/utils/utils.dart';
import '../../../../../../theme/theme.dart';
import '../roSystem/models/data/expense_data.dart';
import 'expenses_type.dart';
import 'repository/expenses_api.dart';

class AddExpense extends StatefulWidget {
  final int shopId;

  AddExpense({
    super.key,
    int? providedShopId,
  }) : shopId = providedShopId ?? _getDefaultShopId();

  static int _getDefaultShopId() {
    final userData = LocalStorage.getUser();
    // If user is admin and no shop, use default 9003
    if (userData?.role == 'admin' && userData?.shop?.id == null) {
      return 9003;
    }
    // Otherwise use the user's shop ID or throw an exception
    return userData?.shop?.id ?? (throw Exception('Shop data not found'));
  }

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();
  bool _isLoading = false;
  bool _isLoadingTypes = true;
  String? _error;
  int? _selectedTypeId;
  List<ExpenseType> _expenseTypes = [];
  int? _shopId;

  // Controllers for all fields
  final _itemCodeController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _meterIdController = TextEditingController();
  final _kwhController = TextEditingController();
  final _litresController = TextEditingController();
  final _supplierController = TextEditingController();
  final _invoiceNumberController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  Future<void> _loadExpenseTypes() async {
    try {
      final types = await _expenseService.getExpenseTypes();
      if (mounted) {
        setState(() {
          _expenseTypes = types;
          _isLoadingTypes = false;
          if (types.isNotEmpty) {
            _selectedTypeId = types.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading expense types: $e';
          _isLoadingTypes = false;
        });

        // Show a more detailed error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load expense types. Please check your connection and try again.'),
            backgroundColor: AppStyle.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_selectedTypeId == null) {
          throw Exception('Please select an expense type');
        }
        if (_shopId == null) {
          throw Exception('Shop data not found');
        }

        final expense = Expense(
          shopId: widget.shopId,
          itemCode: _itemCodeController.text.isEmpty ? null : _itemCodeController.text,
          qty: double.parse(_qtyController.text),
          price: double.parse(_priceController.text),
          description: _descriptionController.text,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          meterId: _meterIdController.text.isEmpty ? null : int.parse(_meterIdController.text),
          kwh: _kwhController.text.isEmpty ? null : double.parse(_kwhController.text),
          litres: _litresController.text.isEmpty ? null : double.parse(_litresController.text),
          status: 'progress',
          typeId: _selectedTypeId!,
          supplier: _supplierController.text.isEmpty ? null : _supplierController.text,
          invoiceNumber: _invoiceNumberController.text.isEmpty ? null : _invoiceNumberController.text,
        );

        await _expenseService.createExpense(expense);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: AppStyle.brandGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error saving expense: $e';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: AppStyle.red,
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppStyle.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: validator ?? (required ? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        } : null),
      ),
    );
  }

  Future<void> _showExpenseDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                              'Add Expense',
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

                        // Expense Type Dropdown
                        if (_isLoadingTypes)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          DropdownButtonFormField<int>(
                            value: _selectedTypeId,
                            decoration: InputDecoration(
                              labelText: 'Expense Type',
                              labelStyle: GoogleFonts.inter(color: AppStyle.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _expenseTypes.map((type) {
                              return DropdownMenuItem(
                                value: type.id,
                                child: Text(type.name),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select an expense type';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeId = value!;
                              });
                            },
                          ),
                        const SizedBox(height: 16),

                        // Required fields for all types
                        _buildFormField(
                          label: 'Item Code',
                          controller: _itemCodeController,
                          required: false,
                        ),
                        _buildFormField(
                          label: 'Quantity',
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          label: 'Price',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          label: 'Description',
                          controller: _descriptionController,
                          maxLines: 3,
                        ),

                        // Optional fields
                        _buildFormField(
                          label: 'Note',
                          controller: _noteController,
                          maxLines: 2,
                          required: false,
                        ),

                        // Conditional fields based on type
                        if (_selectedTypeId == 2) ...[  // Energy type
                          _buildFormField(
                            label: 'Meter ID',
                            controller: _meterIdController,
                            keyboardType: TextInputType.number,
                            required: false,
                          ),
                          _buildFormField(
                            label: 'KWH Usage',
                            controller: _kwhController,
                            keyboardType: TextInputType.number,
                            required: false,
                          ),
                        ],

                        if (_selectedTypeId == 3) ...[  // Water type
                          _buildFormField(
                            label: 'Litres',
                            controller: _litresController,
                            keyboardType: TextInputType.number,
                            required: false,
                          ),
                        ],

                        _buildFormField(
                          label: 'Supplier',
                          controller: _supplierController,
                          required: false,
                        ),
                        _buildFormField(
                          label: 'Invoice Number',
                          controller: _invoiceNumberController,
                          required: false,
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyle.brandGreen,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _isLoading ? null : _handleSubmit,
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
                            'Save Expense',
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
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _meterIdController.dispose();
    _kwhController.dispose();
    _litresController.dispose();
    _supplierController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add Expense',
      child: Container(
        height: 50.h,
        width: 70.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppStyle.dontHaveAccBtnBack,
        ),
        child: MaterialButton(
          onPressed: () => _showExpenseDialog(context),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppStyle.black, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
