class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static bool isEmailValid(String value) => _emailRegex.hasMatch(value.trim());

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Need an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Need a number';
    if (!RegExp(
      r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?/\\|`~]',
    ).hasMatch(value)) {
      return 'Need a special character';
    }
    return null;
  }

  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasUppercase(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool hasNumber(String v) => RegExp(r'[0-9]').hasMatch(v);
  static bool hasSpecialChar(String v) =>
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?/\\|`~]').hasMatch(v);
  
  static String extractPhoneDigits(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '');
  
  static String? validateSriLankaPhone(String? digits) {
    if (digits == null || digits.isEmpty) return 'Phone number is required';
    final clean = extractPhoneDigits(digits);
    if (clean.length != 9) return 'Enter exactly 9 digits after +94';
    return null;
  }

  static String formatPhoneDisplay(String digits) {
    final d = extractPhoneDigits(digits);
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)} ${d.substring(2)}';
    return '${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5)}';
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
