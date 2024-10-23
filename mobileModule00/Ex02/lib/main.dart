import 'package:flutter/material.dart';

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

  void buttonPressed(String buttonText) {
    debugPrint('Button pressed: $buttonText');
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
          const Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '0',
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    Text(
                      '0',
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            color: const Color.fromARGB(255, 74, 0, 177),
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
