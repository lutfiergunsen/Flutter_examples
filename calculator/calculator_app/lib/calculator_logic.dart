import 'package:math_expressions/math_expressions.dart';

/// Pure calculator state, kept apart from the UI so it can be unit tested.
class CalculatorLogic {
  static const operators = ['+', '-', 'X', '/'];

  String expression = '0';
  String result = '0';

  void press(String key) {
    switch (key) {
      case 'AC':
        expression = '0';
        result = '0';
      case 'C':
        expression = expression.length > 1
            ? expression.substring(0, expression.length - 1)
            : '0';
      case '=':
        result = evaluate(expression);
      case '.':
        _addDot();
      default:
        if (operators.contains(key)) {
          _addOperator(key);
        } else {
          _addDigits(key);
        }
    }
  }

  void _addDigits(String digits) {
    if (expression == '0') {
      // "00" on an empty display would just be another zero.
      expression = digits == '00' ? '0' : digits;
    } else {
      expression += digits;
    }
  }

  void _addOperator(String op) {
    final last = expression[expression.length - 1];
    if (expression == '0' && op == '-') {
      expression = '-';
    } else if (operators.contains(last)) {
      // Two operators in a row would be invalid, so replace the previous one.
      expression = expression.length == 1
          ? '0$op'
          : expression.substring(0, expression.length - 1) + op;
    } else if (last == '.') {
      expression += '0$op';
    } else {
      expression += op;
    }
  }

  void _addDot() {
    // Only one dot per number: look at the part after the last operator.
    final lastNumber = expression.split(RegExp(r'[+\-X/]')).last;
    if (lastNumber.contains('.')) return;
    expression += lastNumber.isEmpty ? '0.' : '.';
  }

  /// Evaluates [input] and returns a display string, or "Error".
  static String evaluate(String input) {
    var text = input;
    // Ignore a trailing operator or dot, e.g. "5+" evaluates as "5".
    while (text.isNotEmpty &&
        (operators.contains(text[text.length - 1]) ||
            text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }
    if (text.isEmpty) return '0';

    try {
      final exp = Parser().parse(text.replaceAll('X', '*'));
      final value = exp.evaluate(EvaluationType.REAL, ContextModel()) as num;
      if (!value.isFinite) return 'Error';
      return format(value.toDouble());
    } catch (_) {
      return 'Error';
    }
  }

  /// 4.0 -> "4", 0.1 + 0.2 -> "0.3"
  static String format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var text = value.toStringAsPrecision(12);
    if (text.contains('e')) return text;
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    }
    return text;
  }
}
