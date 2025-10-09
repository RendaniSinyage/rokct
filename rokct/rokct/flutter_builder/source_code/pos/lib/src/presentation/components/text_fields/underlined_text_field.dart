import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';


class UnderlinedTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget? suffixIcon;
  final bool? obscure;
  final TextEditingController? textController;
  final ValueChanged<String>? onChanged;
  final TextInputType? inputType;
  final String? initialText;
  final String? descriptionText;
  final bool readOnly;
  final bool isError;
  final bool isSuccess;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const UnderlinedTextField({
    super.key,
    required this.label,
    this.suffixIcon,
    this.obscure,
    this.onChanged,
    this.textController,
    this.inputType,
    this.initialText,
    this.descriptionText,
    this.readOnly = false,
    this.isError = false,
    this.isSuccess = false,
    this.textCapitalization,
    this.textInputAction,
    this.hint,
    this.onTap,
    this.validator, this.inputFormatters,
  }) ;

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          onTap: onTap,
          autocorrect: true,
          onChanged: onChanged,
          obscureText: !(obscure ?? true),
          obscuringCharacter: '*',
          controller: textController,
          style: AppStyle.interNormal(
            size: 15.sp,
            color: AppStyle.black,
          ),
          cursorWidth: 1,
          inputFormatters: inputFormatters,
          cursorColor: AppStyle.black,
          keyboardType: inputType,
          initialValue: initialText,
          readOnly: readOnly,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            suffixIconConstraints: BoxConstraints(
              maxHeight: suffixIcon != null ? 80.h : 30.h,
              maxWidth: suffixIcon != null ? 80.w : 30.w,
            ),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              color: AppStyle.textGrey,
            ),
            labelText: label.toUpperCase(),
            labelStyle: AppStyle.interNormal(
              size: 14.sp,
              color: AppStyle.black,
            ),
            contentPadding: REdgeInsets.symmetric(horizontal: 0, vertical: 8),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppStyle.shimmerBase),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppStyle.red),
            ),
            border: const UnderlineInputBorder(),
            focusedErrorBorder: const UnderlineInputBorder(),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppStyle.shimmerBase),
            ),
            focusedBorder: const UnderlineInputBorder(),
          ),
        ),
        if (descriptionText != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              4.verticalSpace,
              Text(
                descriptionText!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                  fontSize: 12.sp,
                  color: isError
                      ? AppStyle.red
                      : isSuccess
                          ? AppStyle.textGrey
                          : AppStyle.black,
                ),
              ),
            ],
          )
      ],
    );
  }
}

