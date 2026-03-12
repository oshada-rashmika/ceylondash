import 'package:flutter/material.dart';
import '../utils/validators.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool showRequirements;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.validator,
    this.showRequirements = true,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  final FocusNode _focus = FocusNode();
  bool _hasFocus = false;
  bool _obscure = true;

  bool _hasMin = false;
  bool _hasUpper = false;
  bool _hasNum = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_hasFocus != _focus.hasFocus) {
        setState(() => _hasFocus = _focus.hasFocus);
      }
    });
    widget.controller.addListener(_evaluate);
  }

  void _evaluate() {
    final v = widget.controller.text;
    setState(() {
      _hasMin = Validators.hasMinLength(v);
      _hasUpper = Validators.hasUppercase(v);
      _hasNum = Validators.hasNumber(v);
      _hasSpecial = Validators.hasSpecialChar(v);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_evaluate);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTracker =
        widget.showRequirements &&
        (widget.controller.text.isNotEmpty || _hasFocus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: Colors.cyan.withAlpha(40),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: _obscure,
            validator: widget.validator ?? Validators.validatePassword,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: _hasFocus ? Colors.cyan : Colors.black45,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Colors.black38,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.cyan,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
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
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Req(label: '8+ chars', met: _hasMin),
                _Req(label: 'Uppercase', met: _hasUpper),
                _Req(label: 'Number', met: _hasNum),
                _Req(label: 'Special', met: _hasSpecial),
              ],
            ),
          ),
          crossFadeState: showTracker
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}


class _Req extends StatelessWidget {
  final String label;
  final bool met;
  const _Req({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: met ? Colors.green.withAlpha(20) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: met ? Colors.green.shade400 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              met ? Icons.check_circle : Icons.circle_outlined,
              key: ValueKey(met),
              size: 14,
              color: met ? Colors.green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: met ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
