import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscountTypeDropDown extends StatefulWidget {
  final String? typeValue;
  final Function(String?) onTap;
  final String? label;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool? obscure;
  final TextEditingController? textController;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final TextInputType? inputType;
  final String? initialText;
  final String? descriptionText;
  final String? hintText;
  final bool readOnly;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final Color? color;
  final Color? border;
  final TextStyle? style;
  final String? Function(String?)? validator;

  const DiscountTypeDropDown({
    super.key,
    required this.onTap,
    this.typeValue,
    required this.label,
    this.suffixIcon,
    this.prefixIcon,
    this.obscure,
    this.onChanged,
    this.textController,
    this.inputType,
    this.initialText,
    this.descriptionText,
    this.readOnly = false,
    this.textCapitalization,
    this.onFieldSubmitted,
    this.maxLength,
    this.color,
    this.style,
    this.border,
    this.validator,
    this.textInputAction,
    this.hintText,
  });

  @override
  State<DiscountTypeDropDown> createState() => _DiscountTypeDropDownState();
}

class _DiscountTypeDropDownState extends State<DiscountTypeDropDown> {
  late String selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.typeValue ?? 'fix';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Column(
            children: [
              Text(
                widget.label ?? "",
              ),
              4.verticalSpace,
            ],
          ),
        DropdownButtonFormField<String>(
          padding: EdgeInsets.zero,
          value: selectedOption,
          onChanged: (value) {
            setState(() {
              selectedOption = value!;
            });
            widget.onTap(value);
          },
          items: <String>['fix', 'percent'].map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          decoration: InputDecoration(
            counterText: '',
            suffixIconConstraints: BoxConstraints(maxWidth: 48.r, minWidth: 36.r),
            contentPadding: REdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            floatingLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize:14.sp,
              color: AppStyle.black,
              letterSpacing: -14 * 0.01,
            ),
            fillColor:  AppStyle.white,
            filled: true,
            hoverColor: AppStyle.transparent,
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
            border: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
            disabledBorder: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.merge(
                    const BorderSide(color: AppStyle.border, width: 0.5),
                    const BorderSide(color: AppStyle.border, width: 0.5)),
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ],
    );
  }
}

