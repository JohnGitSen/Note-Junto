import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  // late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmpassword;

  @override
  void initState() {
    //    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmpassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    //    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmpassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('lib/assets/registerPage.png', fit: BoxFit.fill),
          ),

          Positioned(
            bottom: screenHeight * 0.61,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/usernameBar.png',
                width: screenWidth * 0.75,
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.605,
            left: screenHeight * 0.05,
            right: 0,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.68,
                child: TextFormField(
                  // controller: _username,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'johnDoe',
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
            bottom: screenHeight * 0.53,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/emailBar.png',
                width: screenWidth * 0.75,
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.525,
            left: screenHeight * 0.05,
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
            bottom: screenHeight * 0.455,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/passwordBar.png',
                width: screenWidth * 0.75,
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.45,
            left: screenHeight * 0.05,
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
                    hintText: 'Create Password',
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
            bottom: screenHeight * 0.375,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'lib/assets/passwordBar.png',
                width: screenWidth * 0.75,
              ),
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.37,
            left: screenHeight * 0.05,
            right: 0,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.68,
                child: TextFormField(
                  obscureText: true,
                  controller: _confirmpassword,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Confirm password',
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
            bottom: screenHeight * 0.275,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final email = _email.text;
                  final password = _password.text;
                  final confirmpassword = _confirmpassword.text;

                  if (password == confirmpassword) {
                    try {
                      final userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        buildSnackBar(
                          context,
                          "Use a stronger password , 8-16 characters",
                        );
                      } else if (e.code == 'email-already-in-use') {
                        buildSnackBar(context, "Email already in use");
                      } else if (e.code == 'invalid-email') {
                        buildSnackBar(context, "Invalid Email Format");
                      }
                    }
                  } else {
                    buildSnackBar(
                      context,
                      "Password and confirm password doesnt match",
                    );
                  }
                },
                child: Image.asset(
                  'lib/assets/registerButton.png',
                  width: screenWidth * 0.4,
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
                onTap: () {
                  Navigator.pushNamed(context, '/setupPage/loginPage');
                },
                child: Image.asset(
                  'lib/assets/alreadyhaveaccountText.png',
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
