import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/config.dart';
import '/food.dart';

final configurations = Configurations();

Future<void> main() async {
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: configurations.apiKey,
          appId: configurations.appId,
          storageBucket: configurations.storageBucket,
          messagingSenderId: configurations.messagingSenderId,
          projectId: configurations.projectId));
  runApp(const firestore());
}

// ignore: camel_case_types
class firestore extends StatelessWidget {
  const firestore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            primarySwatch: Colors.brown, fontFamily: 'PlayfairDisplay'),
        debugShowCheckedModeBanner: false,
        home: EngPageState());
  }
}
