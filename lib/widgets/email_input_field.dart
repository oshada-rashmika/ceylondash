import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validators.dart';

class EmailInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const EmailInputField({super.key, required this.controller, this.validator});

  @override
  State<EmailInputField> createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  final FocusNode _focus = FocusNode();
  bool _hasFocus = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_hasFocus != _focus.hasFocus) {
        setState(() => _hasFocus = _focus.hasFocus);
      }
    });
    widget.controller.addListener(_checkValidity);
  }

  void _checkValidity() {
    final valid = Validators.isEmailValid(widget.controller.text);
    if (valid != _isValid) setState(() => _isValid = valid);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkValidity);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: (_isValid ? Colors.green : Colors.cyan).withAlpha(35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [
          _LowerCaseTextFormatter(),
          FilteringTextInputFormatter.deny(
            RegExp(r'\s'),
          ), // Also prevent spaces
        ],
        validator: widget.validator ?? Validators.validateEmail,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(
            color: _hasFocus
                ? (_isValid ? Colors.green : Colors.cyan)
                : Colors.black45,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: _isValid ? Colors.green : Colors.black38,
            size: 20,
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _isValid
                ? const Padding(
                    key: ValueKey('check'),
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _isValid ? Colors.green.shade200 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _isValid ? Colors.green : Colors.cyan,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          errorStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
        ),
      ),
    );
  }
}

class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
