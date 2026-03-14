import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:notesharingapp/NavBarScreens/createNotesScreen.dart';
import 'package:notesharingapp/NavBarScreens/editViewNotesScreen.dart';
import 'package:notesharingapp/screens/setupPage.dart';
import 'firebase_options.dart';
import 'screens/landingPage.dart';
import 'screens/loginPage.dart';
import 'screens/registerPage.dart';
import 'screens/mainAppPage.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
  print(
    'Firebase initialized: ${Firebase.app().name}',
  ); // Kapag [DEFAULT] goods siya :) , Dito nag start ung pag create ng implementation or pagpasok ng firebase.
}

// For Smooth Transition or Style ng pag change ng page.
Route _smoothRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.fastOutSlowIn));

      return FadeTransition(
        opacity: animation.drive(tween),
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // For flutterquil localization for language.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Note Junto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // For changing pages , Initial route natin yung landing page
      // Dito na rin ung pag create ng routes ng ibang pages.
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _smoothRoute(Landingpage());
          case '/setupPage':
            return _smoothRoute(Setuppage());
          case '/setupPage/loginPage':
          case '/setupPage/registerPage':
            return _smoothRoute(RegisterPage());
          case '/mainAppPage':
            return _smoothRoute(MainAppPage());
          case '/landingPage/mainAppPage/CreateNotesPage':
            return _smoothRoute(CreateNotesPage());
          case '/editViewNotesScreen':
            // Mostly kaya ako ng switch case para dun sa opening notes , since nasisira siya when wala condition or
            // Map args para i pass ung noteid, title, and body galing sa editviewnotes screen function
            final args = settings.arguments as Map<String, dynamic>;
            return _smoothRoute(
              EditViewNotesScreen(
                noteId: args['noteId'] as String,
                title: args['title'] as String? ?? '',
                body: args['body'] as String? ?? '[]',
                isShared: args['isShared'] as bool? ?? false,
              ),
            );
          default:
            return _smoothRoute(Landingpage());
        }
      },
    );
  }
}
