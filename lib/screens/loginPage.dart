import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('lib/assets/loginPage.png'), context);
    precacheImage(const AssetImage('lib/assets/emailBar.png'), context);
    precacheImage(const AssetImage('lib/assets/passwordBar.png'), context);
    precacheImage(const AssetImage('lib/assets/loginButton.png'), context);
    precacheImage(const AssetImage('lib/assets/donthaveaccountText.png'), context);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset('lib/assets/loginPage.png', fit: BoxFit.fill),
            ),
          ),

          // Email Bar Image
          Positioned(
            bottom: screenHeight * 0.50,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/emailBar.png',
                width: screenWidth * 0.82,
              ),
            ),
          ),

          // Email TextFormField
          Positioned(
            bottom: screenHeight * 0.50,
            left: screenHeight * 0.01,
            right: 0,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.68,
                child: TextFormField(
                  enableSuggestions: false,
                  autocorrect: false,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'johnemail@gmail.com',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.40,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/passwordBar.png',
                width: screenWidth * 0.82,
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.395,
            left: screenHeight * 0.01,
            right: 0,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.68,
                child: TextFormField(
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  controller: _password,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '**********',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final email = _email.text;
                  final password = _password.text;
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    Navigator.pushNamed(context, '/mainAppPage');
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'invalid-credential') {
                      buildSnackBar(context, "Invalid email or password!");
                    }
                  }
                },
                child: Image.asset(
                  'lib/assets/loginButton.png',
                  width: screenWidth * 0.5,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushNamed(context, '/setupPage/registerPage');
                },
                child: Image.asset(
                  'lib/assets/donthaveaccountText.png',
                  width: screenWidth * 0.75,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/setupPage');
          },
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          child: Icon(
            Icons.arrow_circle_left_rounded,
            color: const Color.fromARGB(255, 85, 125, 199),
            size: screenWidth * 0.08,
          ),
        ),
      ),
    );
  }
}