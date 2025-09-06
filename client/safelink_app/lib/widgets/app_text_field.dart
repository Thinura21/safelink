import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.obscure = false,
    this.enabled = true,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool obscure;
  final bool enabled;
  final void Function(String value)? onSubmitted;

  /// Keep this signature aligned with TextFormField: String? Function(String?)
  final String? Function(String? value)? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hide = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hide = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _hide,
          onFieldSubmitted: widget.onSubmitted,
          validator: (v) {
            if (widget.validator == null) return null;
            final err = widget.validator!(v);
            setState(() => _error = err);
            return err;
          },
          onChanged: (v) {
            if (widget.validator != null) {
              setState(() => _error = widget.validator!(v));
            }
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hide = !_hide),
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  )
                : null,
            errorText: _error,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
