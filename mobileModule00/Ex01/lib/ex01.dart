import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: MyButton(),
      ),
    ),
  ));
}

class MyButton extends StatefulWidget {
  const MyButton({super.key});

  @override
  MyButtonState createState() => MyButtonState();
}

class MyButtonState extends State<MyButton> {
  String texts = 'A simple Text';
  int currentIndex = 1;

  void _toggleText() {
    setState(() {
      if (currentIndex == 0)
        {
          texts = 'A simple Text';
          currentIndex = 1;
        }
      else
        {
          texts = 'Hello World!';
          currentIndex = 0;
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          texts,
          style: const TextStyle(
            fontSize: 30,
            backgroundColor: Colors.green,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _toggleText,
          child: const Text('Click me'),
        ),
      ],
    );
  }
}
