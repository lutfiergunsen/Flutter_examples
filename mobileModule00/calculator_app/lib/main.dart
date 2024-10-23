import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Calculator',
      home: Calculator(),
    );
  }
}

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  CalculatorState createState() => CalculatorState();
}

class CalculatorState extends State<Calculator> {
  String displayText = "0";
  String res = "0";

  void buttonPressed(String buttonText) {
    debugPrint('Button pressed: $buttonText');

    void letstart(String displayText) {
      String replacedText = displayText.replaceAll("X", "*");
      Parser p = Parser();
      Expression exp =  p.parse(replacedText);

      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      setState(() {  
        res = eval.toString();
      });
      debugPrint('Sonuç: $eval');
    }

    setState(() {
      if (displayText == "0" &&
          buttonText != "AC" &&
          buttonText != "C" &&
          buttonText != "=") {
        displayText = buttonText;
      } else if (buttonText == "AC") {
        displayText = "0";
        res = "0";
      } else if (buttonText == "C") {
        displayText = displayText.substring(0, displayText.length - 1);
        if (displayText == "") displayText = "0";
      } else if (buttonText == "=") {
        if (int.tryParse(displayText[displayText.length - 1]) != null)
        {
          letstart(displayText);
        }
      } else {
          displayText += buttonText;
      }
    });
  }

  Widget buildButton(String buttonText, {Color textColor = Colors.white}) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(20.0),
          side: const BorderSide(color: Color.fromARGB(255, 74, 0, 177)),
          backgroundColor: const Color.fromARGB(255, 74, 0, 177),
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 20.0, color: textColor),
        ),
        onPressed: () => buttonPressed(buttonText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        backgroundColor: const Color.fromARGB(255, 74, 0, 177),
      ),
      body: Container(
        color: const Color.fromARGB(255, 68, 0, 254),
        child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      displayText,
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    Text(
                      res,
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            color: Color.fromARGB(255, 74, 0, 177),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    buildButton("7"),
                    buildButton("8"),
                    buildButton("9"),
                    buildButton("C", textColor: Colors.red),
                    buildButton("AC", textColor: Colors.red),
                  ],
                ),
                Row(
                  children: <Widget>[
                    buildButton("4"),
                    buildButton("5"),
                    buildButton("6"),
                    buildButton("+", textColor: Colors.blue),
                    buildButton("-", textColor: Colors.blue),
                  ],
                ),
                Row(
                  children: <Widget>[
                    buildButton("1"),
                    buildButton("2"),
                    buildButton("3"),
                    buildButton("X", textColor: Colors.blue),
                    buildButton("/", textColor: Colors.blue),
                  ],
                ),
                Row(
                  children: <Widget>[
                    buildButton("0"),
                    buildButton("."),
                    buildButton("00"),
                    buildButton("="),
                    const Expanded(
                      child: Text(' ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
