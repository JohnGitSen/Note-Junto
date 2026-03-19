import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notesharingapp/utils/SnackBarUtils.dart';

// Ginawa ko na siya function that can be called para
// ma recall ko nalang siya sa register page

void showLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    useRootNavigator: true,
    builder: (_) => const LoginSheet(),
  );
}

class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});
  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

  // Colors ng mga compoments para dun sa login
  // Draggable Bottom Sheet

  static const _bg = Color.fromARGB(255, 33, 44, 58);
  static const _fieldBg = Color(0xFF1A1F30);
  static const _accent = Color(0xFF668CEF);
  static const _light = Color(0xFFB0C8E0);
  static const _primary = Color(0xFFEAEFF8);
  static const _muted = Color(0xFF8A96B0);
  static const _error = Color(0xFFFF5C5C);

  @override
  // For error message , like ung lumalabas na error sa email field
  // tapos once na meron magtype or maglagay ma cle-clear or mawawala

  void initState() {
    super.initState();
    _email.addListener(_clearError);
    _password.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    setState(() => _loading = true);
    try {

      // Dito natin binibigay sa firebase auth ung info or email & password and it get's passed
      // sa firebase para i check kung existing , valid siya.

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Iniinitialized niya ung user na nag logged in just now as the default
      // or ung fresh na latest user data

      final user = credential.user!;
      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser!;

      if (!mounted) return;

      // Checks if ung user ay verified , if yes continue. 
      // Kung hindi magbibigay siya ng prompt

      if (freshUser.emailVerified) {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/mainAppPage');
      } else {
        _showNotVerifiedDialog(freshUser);
      } // Once na maipasa ung email at password sa fireauth , Kapag invalid
      // normally magbibigay yun ng exception sa console. Dito inaano once na may ma catch na exception
      // sasabihin niya "invalid" error message. 
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.code == 'invalid-credential'
              ? 'Invalid email or password.'
              : 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Eto ung compoment basically ng pagshow ng 
  // error message once di ka verified
  void _showNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFE8A838),
          size: 44,
        ),
        title: const Text(
          'Email not verified',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFEAEFF8),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Your email has not been verified yet.\n\nCheck your inbox and click the link we sent.\n\n⚠️ Skipping will limit your access to certain features.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A96B0), fontSize: 13, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Resend ng emailverification link takes place here
                        await user.sendEmailVerification();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          buildSnackBar(
                            context,
                            "Verification email resent!",
                            backgroundColor: const Color.fromARGB(
                              255,
                              99,
                              167,
                              255,
                            ),
                          );
                        }
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF668CEF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Resend verification email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/mainAppPage');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8A96B0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Skip for now (limited features)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final keyboard = mq.viewInsets.bottom;
    final navBar = mq.padding.bottom;

    final bool hasError = _errorMessage != null;

    // Eto ung buong frame or design ng login bottom bar
    return Container(
      height: screenH * 0.67,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenW, 150),
              painter: _WavePainter(
                const Color.fromARGB(255, 178, 205, 240).withOpacity(0.9),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 12, 28, keyboard + navBar + 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _muted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.notes_rounded,
                        color: _light,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Sign in to Note Junto',
                          style: TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'EMAIL',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Email field border red error effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: hasError ? _error.withOpacity(0.07) : _fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasError
                          ? _error.withOpacity(0.85)
                          : _accent.withOpacity(0.2),
                      width: hasError ? 1.6 : 1.0,
                    ),
                    boxShadow: hasError
                        ? [
                            BoxShadow(
                              color: _error.withOpacity(0.18),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(color: _primary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'johndoe@gmail.com',
                      hintStyle: const TextStyle(color: _muted, fontSize: 15),
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: hasError ? _error.withOpacity(0.85) : _muted,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Red error text above email field
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: _error,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: _error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 18),

                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                _field(
                  controller: _password,
                  hint: '••••••••••',
                  obscure: _obscure,
                  icon: Icons.lock_outline_rounded,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _muted,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/setupPage/registerPage'),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account?  ",
                        style: TextStyle(color: _muted, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(
                              color: _light,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        enableSuggestions: false,
        autocorrect: false,
        style: const TextStyle(color: _primary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted, fontSize: 15),
          prefixIcon: Icon(icon, color: _muted, size: 20),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// Wave design kemerut lang to 

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.color != color;
}
