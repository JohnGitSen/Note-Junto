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
  ); // Kapag [DEFAULT] goods siya :)
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Landingpage(),
        '/setupPage': (context) => Setuppage(),
        '/setupPage/loginPage': (context) => LoginPage(),
        '/setupPage/registerPage': (context) => RegisterPage(),
        '/mainAppPage': (context) => MainAppPage(),
        '/landingPage/mainAppPage/CreateNotesPage': (context) =>
            CreateNotesPage(),
        '/editViewNotesScreen': (context) => EditViewNotesScreen(),
      },
    );
  }
}
