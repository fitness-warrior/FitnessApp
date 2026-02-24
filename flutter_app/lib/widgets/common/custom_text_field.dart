import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Customizable text field with consistent styling
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  const CustomTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconPressed,
              )
            : null,
        border: const OutlineInputBorder(),
        filled: !enabled,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
    );
  }
}

/// Number input field with validation
class NumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int? min;
  final int? max;
  final bool allowDecimal;
  final String? Function(String?)? additionalValidator;
  final void Function(String)? onChanged;

  const NumberTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.min,
    this.max,
    this.allowDecimal = false,
    this.additionalValidator,
    this.onChanged,
  }) : super(key: key);

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Allow empty unless required by additionalValidator
    }

    if (allowDecimal) {
      final num? val = double.tryParse(value);
      if (val == null) return 'Enter a valid number';
      if (min != null && val < min!) return 'Minimum value is $min';
      if (max != null && val > max!) return 'Maximum value is $max';
    } else {
      final int? val = int.tryParse(value);
      if (val == null) return 'Enter a valid whole number';
      if (min != null && val < min!) return 'Minimum value is $min';
      if (max != null && val > max!) return 'Maximum value is $max';
    }

    return additionalValidator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? (min != null && max != null ? '$min - $max' : null),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: _validate,
      onChanged: onChanged,
    );
  }
}

/// Email input field with validation
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final void Function(String)? onChanged;
  final bool required;

  const EmailTextField({
    Key? key,
    this.controller,
    this.labelText = 'Email',
    this.hintText = 'Enter your email',
    this.onChanged,
    this.required = false,
  }) : super(key: key);

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Email is required' : null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email,
      validator: _validate,
      onChanged: onChanged,
    );
  }
}

/// Password input field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool required;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.validator,
    this.onChanged,
    this.required = false,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  String? _defaultValidator(String? value) {
    if (widget.required && (value == null || value.isEmpty)) {
      return 'Password is required';
    }
    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      obscureText: _obscureText,
      prefixIcon: Icons.lock,
      suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
      onSuffixIconPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
      validator: _defaultValidator,
      onChanged: widget.onChanged,
    );
  }
}

/// Multi-line text field for longer content
class MultiLineTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const MultiLineTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 5,
    this.maxLength,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
