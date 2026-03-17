import 'package:flutter/services.dart';

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    if (int.tryParse(digitsOnly) == null) return oldValue;

    final formatted = _addSeparators(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addSeparators(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String format(double value) {
    return _addSeparators(value.toStringAsFixed(0));
  }

  static double parse(String formatted) {
    return double.tryParse(formatted.replaceAll('.', '')) ?? 0;
  }
}
