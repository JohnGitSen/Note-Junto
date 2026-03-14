import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  @override
  Widget build(BuildContext context) {
    // For accurate size for images multiplying relative
    // sa screen size. Para kapag minultiply ung image size relative dun sa image resolution.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('lib/assets/landingPage.png', fit: BoxFit.fill),
          ),
          Positioned(
            bottom: screenHeight * 0.20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Checks kung ung user nag login na ba or may current user sa firebase.
                  // If meron continue na agad sa mainpage and if non existing. Sa setup page sila ipupunta
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.pushNamed(context, '/mainAppPage');
                  } else {
                    Navigator.pushNamed(context, '/setupPage');
                  }
                },
                child: Image.asset(
                  'lib/assets/getstartedButton.png',
                  width: screenWidth * 0.40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
