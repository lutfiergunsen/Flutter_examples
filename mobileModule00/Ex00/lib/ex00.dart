import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A simple text', 
              style: TextStyle(
                fontSize: 30,
                backgroundColor: Colors.green,
                letterSpacing: 5,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print('Button pressed');
              },
              child: Text('Click me'),
            ),
          ],
        ),
      ), 
    ),
  ));
}