import 'package:flutter_application_1/calculator_logic.dart';
import 'package:flutter_test/flutter_test.dart';

CalculatorLogic pressAll(List<String> keys) {
  final logic = CalculatorLogic();
  for (final key in keys) {
    logic.press(key);
  }
  return logic;
}

void main() {
  test('whole results have no trailing .0', () {
    expect(pressAll(['2', '+', '2', '=']).result, '4');
  });

  test('operator precedence and decimals', () {
    expect(pressAll(['2', '+', '3', 'X', '4', '=']).result, '14');
    expect(pressAll(['.', '1', '+', '.', '2', '=']).result, '0.3');
    expect(pressAll(['1', '0', '/', '4', '=']).result, '2.5');
  });

  test('division by zero shows Error instead of Infinity', () {
    expect(pressAll(['1', '/', '0', '=']).result, 'Error');
  });

  test('double operators are replaced, not appended', () {
    final logic = pressAll(['5', '+', '+', 'X', '3']);
    expect(logic.expression, '5X3');
    logic.press('=');
    expect(logic.result, '15');
  });

  test('only one dot per number', () {
    expect(pressAll(['1', '.', '.', '2']).expression, '1.2');
    expect(pressAll(['1', '.', '2', '+', '3', '.', '4']).expression, '1.2+3.4');
  });

  test('leading minus and trailing operator', () {
    expect(pressAll(['-', '3', '+', '5', '=']).result, '2');
    expect(pressAll(['7', 'X', '=']).result, '7');
  });

  test('00 on empty display and C / AC', () {
    expect(pressAll(['00']).expression, '0');
    expect(pressAll(['1', '2', 'C']).expression, '1');
    expect(pressAll(['1', 'C', 'C']).expression, '0');
    final logic = pressAll(['9', '=', 'AC']);
    expect(logic.expression, '0');
    expect(logic.result, '0');
  });

  test('evaluate never throws on bad input', () {
    expect(CalculatorLogic.evaluate('/5'), 'Error');
    expect(CalculatorLogic.evaluate('X'), '0');
  });
}
