import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';
import 'package:notesharingapp/screens/loginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmpassword;

  bool _isLoading = false; // ← prevents double tap

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmpassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmpassword.dispose();
    super.dispose();
  }

  void _showVerificationPrompt(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.mark_email_unread_outlined,
          color: Color(0xFFB0C8E0),
          size: 44,
        ),
        title: const Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFEAEFF8),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'A verification link has been sent to\n$email\n\nPlease check your inbox and click the link to activate your account.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A96B0),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  showLoginSheet(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B9EC2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Got it — Sign in',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (_isLoading) return; // block double tap

    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirmpassword = _confirmpassword.text;

    if (username.isEmpty) {
      buildSnackBar(context, "Please enter a username");
      return;
    }

    if (password.isEmpty) {
      buildSnackBar(context, "Please enter a password");
      return;
    }

    if (password != confirmpassword) {
      buildSnackBar(context, "Password and confirm password don't match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'username': username,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        _showVerificationPrompt(email);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'weak-password') {
          buildSnackBar(context, "Use a stronger password, 8-16 characters");
        } else if (e.code == 'email-already-in-use') {
          buildSnackBar(context, "Email already in use");
        } else if (e.code == 'invalid-email') {
          buildSnackBar(context, "Invalid Email Format");
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('lib/assets/registerPage.png', fit: BoxFit.fill),
          ),

          // Username bar image
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

          // Username field
          Positioned(
            bottom: screenHeight * 0.605,
            left: screenHeight * 0.05,
            right: 0,
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.68,
                child: TextFormField(
                  controller: _username,
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

          // Email bar image
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

          // Email field
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
                    hintText: 'johndoe@gmail.com',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Password bar image
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

          // Password field
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

          // Confirm password bar image
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

          // Confirm password field
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

          // Register button
          Positioned(
            bottom: screenHeight * 0.275,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _register,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Color.fromARGB(255, 85, 125, 199),
                      )
                    : Image.asset(
                        'lib/assets/registerButton.png',
                        width: screenWidth * 0.4,
                      ),
              ),
            ),
          ),

          // Already have an account
          Positioned(
            bottom: screenHeight * 0.20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showLoginSheet(context),
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
          onPressed: () => Navigator.pushNamed(context, '/setupPage'),
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