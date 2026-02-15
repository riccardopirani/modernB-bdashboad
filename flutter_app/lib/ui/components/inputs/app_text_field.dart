import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;

  const AppTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          validator: (value) {
            final error = widget.validator?.call(value);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _errorText = error);
              }
            });
            return error;
          },
          onChanged: widget.onChanged,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          maxLines: _obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 18)
                : null,
            suffixIcon: widget.suffixIcon != null || widget.obscureText
                ? InkWell(
                    onTap: widget.obscureText
                        ? () => setState(() => _obscure = !_obscure)
                        : null,
                    child: Icon(
                      widget.obscureText
                          ? (_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined)
                          : widget.suffixIcon,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: AppColors.accent,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: AppColors.error,
              ),
            ),
            errorText: _errorText,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.textTertiary,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
