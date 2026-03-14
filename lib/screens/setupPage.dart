import 'package:flutter/material.dart';
import 'package:notesharingapp/screens/loginPage.dart';

class Setuppage extends StatefulWidget {
  const Setuppage({super.key});
  @override
  State<Setuppage> createState() => _SetuppageState();
}

class _SetuppageState extends State<Setuppage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('lib/assets/setupPage.png', fit: BoxFit.fill),
          ),

          // Create an account button
          Positioned(
            bottom: screenHeight * 0.35,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/setupPage/registerPage'),
                child: Image.asset('lib/assets/registeraccountButton.png',
                    width: screenWidth * 0.50),
              ),
            ),
          ),

          // Login button — calls showLoginSheet from login_page.dart
          Positioned(
            bottom: screenHeight * 0.22,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => showLoginSheet(context),
                child: Image.asset('lib/assets/loginaccountButton.png',
                    width: screenWidth * 0.50),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/'),
        backgroundColor: Colors.white,
        child: Icon(
          Icons.arrow_circle_left_rounded,
          color: const Color.fromARGB(255, 85, 125, 199),
          size: screenHeight * 0.05,
        ),
      ),
    );
  }
}